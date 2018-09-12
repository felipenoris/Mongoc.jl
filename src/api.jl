
#
# Public API
#

BSON() = BSON("{}")

function BSON(json_string::String)
    handle = bson_new_from_json(json_string)
    if handle == C_NULL
        error("Failed parsing JSON to BSON. $json_string.")
    end
    return BSON(handle)
end

has_field(bson::BSON, key::String) = bson_has_field(bson.handle, key)

"""
    as_json(bson::BSON; canonical::Bool=false) :: String

Converts a `bson` object to a JSON string.

# Example

```julia
julia> document = Mongoc.BSON("{ \"hey\" : 1 }")
BSON("{ "hey" : 1 }")

julia> Mongoc.as_json(document)
"{ \"hey\" : 1 }"

julia> Mongoc.as_json(document, canonical=true)
"{ \"hey\" : { \"\$numberInt\" : \"1\" } }"
```

# C API

* [`bson_as_canonical_extended_json`](http://mongoc.org/libbson/current/bson_as_canonical_extended_json.html)

* [`bson_as_relaxed_extended_json`](http://mongoc.org/libbson/current/bson_as_relaxed_extended_json.html)

"""
function as_json(bson::BSON; canonical::Bool=false) :: String
    cstring = canonical ? bson_as_canonical_extended_json(bson.handle) : bson_as_relaxed_extended_json(bson.handle)
    if cstring == C_NULL
        error("Couldn't convert bson to json.")
    end
    return unsafe_string(cstring)
end

Client(host::String="localhost", port::Int=27017) = Client(URI("mongodb://$host:$port"))

function Collection(database::Database, coll_name::String)
    coll_handle = mongoc_database_get_collection(database.handle, coll_name)
    if coll_handle == C_NULL
        error("Failed creating collection $coll_name on db $(database.name).")
    end
    return Collection(database, coll_name, coll_handle)
end

function Collection(client::Client, db_name::String, coll_name::String)
    database = Database(client, db_name)
    return Collection(database, coll_name)
end

"""
    set_appname!(client::Client, appname::String)

Sets the application name for this client.

This string, along with other internal driver details,
is sent to the server as part of the initial connection handshake.

# C API

* [`mongoc_client_set_appname`](http://mongoc.org/libmongoc/current/mongoc_client_set_appname.html).
"""
function set_appname!(client::Client, appname::String)
    ok = mongoc_client_set_appname(client.handle, appname)
    if !ok
        error("Couldn't set appname=$appname for client $client.")
    end
    nothing
end

"""
    command_simple(client::Client, database::String, command::Union{String, BSON}) :: BSON

Executes a `command` given by a JSON string or a BSON instance.

It returns the first document from the result cursor.

# Example

```julia
julia> client = Mongoc.Client() # connects to localhost at port 27017
Client(URI("mongodb://localhost:27017"))

julia> bson_result = Mongoc.command_simple(client, "admin", "{ \"ping\" : 1 }")
BSON("{ "ok" : 1.0 }")
```

# C API

* [`mongoc_client_command_simple`](http://mongoc.org/libmongoc/current/mongoc_client_command_simple.html)

"""
function command_simple(client::Client, database::String, command::BSON) :: BSON
    reply = BSON()
    err = BSONError()
    ok = mongoc_client_command_simple(client.handle, database, command.handle, C_NULL, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function command_simple(client::Client, database::String, command::String) :: BSON
    return command_simple(client, database, BSON(command))
end

function command_simple(collection::Collection, command::BSON) :: BSON
    reply = BSON()
    err = BSONError()
    ok = mongoc_collection_command_simple(collection.handle, command.handle, C_NULL, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function command_simple(collection::Collection, command::String) :: BSON
    return command_simple(collection, BSON(command))
end

function ping(client::Client) :: BSON
    return command_simple(client, "admin", "{ \"ping\" : 1 }")
end

function find_databases(client::Client; options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_client_find_databases_with_opts(client.handle, options_handle)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(cursor_handle)
end

struct InsertOneResult
    reply::BSON
    inserted_oid::Union{Nothing, BSONObjectId}
end

function insert_one(collection::Collection, document::BSON; options::Union{Nothing, BSON}=nothing) :: InsertOneResult
    inserted_oid = nothing
    if !has_field(document, "_id")
        inserted_oid = BSONObjectId()
        ok = bson_append_oid(document.handle, "_id", -1, inserted_oid)
        if !ok
            error("Couldn't append oid to BSON document.")
        end
    end

    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_insert_one(collection.handle, document.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return InsertOneResult(reply, inserted_oid)
end

insert_one(collection::Collection, document::String; options::Union{Nothing, BSON}=nothing) = insert_one(collection, BSON(document); options=options)

function find(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_find_with_opts(collection.handle, bson_filter.handle, options_handle, C_NULL)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(cursor_handle)
end

function count_documents(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing)
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    len = mongoc_collection_count_documents(collection.handle, bson_filter.handle, options_handle, C_NULL, C_NULL, err)
    if len == -1
        error("Couldn't count number of elements in $collection. $err.")
    end
    return Int(len)
end

count_documents(collection::Collection, bson_filter::String; options::Union{Nothing, BSON}=nothing) = count_documents(collection, BSON(bson_filter); options=options)

function set_limit!(cursor::Cursor, limit::Int)
    ok = mongoc_cursor_set_limit(cursor.handle, limit)
    if !ok
        error("Couldn't set cursor limit to $limit.")
    end
    nothing
end

"""
    find_one(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

Execute a query to a collection and returns the first element of the result set.

Returns `nothing` if the result set is empty.
"""
function find_one(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}
    cursor = find(collection, bson_filter, options=options)
    set_limit!(cursor, 1)
    next = _iterate(cursor)
    if next == nothing
        return nothing
    else
        bson_document, _state = next
        return bson_document
    end
end

find_one(collection::Collection, bson_filter::String; options::Union{Nothing, BSON}=nothing) = find_one(collection, BSON(bson_filter); options=options)

#
# High-level API
#

function _iterate(cursor::Cursor, state::Nothing=nothing)
    next = BSON()
    handle = next.handle
    handle_ref = Ref{Ptr{Cvoid}}(handle)
    has_next = mongoc_cursor_next(cursor.handle, handle_ref)
    next.handle = handle_ref[]

    if has_next
        # The bson document is valid only until the next call to mongoc_cursor_next.
        # So we should return a deepcopy.
        return deepcopy(next), nothing
    else
        return nothing
    end
end

@static if VERSION < v"0.7-"

    # Iteration protocol for Julia v0.6

    struct CursorIteratorState
        element::Union{Nothing, BSON}
    end

    function Base.start(cursor::Cursor)
        nxt = _iterate(cursor)
        if nxt == nothing
            return CursorIteratorState(nothing)
        else
            next_element, _inner_state = nxt # _inner_state is always nothing
            return CursorIteratorState(next_element)
        end
    end

    Base.done(cursor::Cursor, state::CursorIteratorState) = state.element == nothing

    function Base.next(cursor::Cursor, state::CursorIteratorState)
        @assert state.element != nothing
        nxt = _iterate(cursor)
        if nxt == nothing
            return state.element, CursorIteratorState(nothing)
        else
            next_element, _inner_state = nxt # _inner_state is always nothing
            return state.element, CursorIteratorState(next_element)
        end
    end
else
    # Iteration protocol for Julia v0.7 and v1.0
    Base.iterate(cursor::Cursor, state::Nothing=nothing) = _iterate(cursor, state)
end

function Base.deepcopy(bson::BSON) :: BSON
    return BSON(bson_copy(bson.handle))
end

Base.show(io::IO, oid::BSONObjectId) = print(io, "BSONObjectId(\"", bson_oid_to_string(oid), "\")")
Base.show(io::IO, bson::BSON) = print(io, "BSON(\"", as_json(bson), "\")")
Base.show(io::IO, err::BSONError) = print(io, replace(String([ i for i in err.message]), '\0' => ""))
Base.show(io::IO, uri::URI) = print(io, "URI(\"", uri.uri, "\")")
Base.show(io::IO, client::Client) = print(io, "Client(URI(\"", client.uri, "\"))")
Base.show(io::IO, db::Database) = print(io, "Database($(db.client), \"", db.name, "\")")
Base.show(io::IO, coll::Collection) = print(io, "Collection($(coll.database), \"", coll.name, "\")")

Base.haskey(bson::BSON, key::String) = has_field(bson, key)
Base.getindex(client::Client, database::String) = Database(client, database)
Base.getindex(database::Database, collection_name::String) = Collection(database, collection_name)
Base.push!(collection::Collection, document::Union{String, BSON}; options::Union{Nothing, BSON}=nothing) = insert_one(collection, document; options=options)
