
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

"""
    as_json_string(bson::BSON; canonical::Bool=false) :: String

Converts a `bson` object to a JSON string.

# Example

```julia
julia> document = Mongoc.BSON("{ \"hey\" : 1 }")
Mongoc.BSON(Ptr{Nothing} @0x00007fbc8e62cc30)

julia> Mongoc.as_json_string(document)
"{ \"hey\" : 1 }"

julia> Mongoc.as_json_string(document, canonical=true)
"{ \"hey\" : { \"\$numberInt\" : \"1\" } }"
```

# C API

* [`bson_as_canonical_extended_json`](http://mongoc.org/libbson/current/bson_as_canonical_extended_json.html)

* [`bson_as_relaxed_extended_json](http://mongoc.org/libbson/current/bson_as_relaxed_extended_json.html)

"""
function as_json_string(bson::BSON; canonical::Bool=false) :: String
    cstring = canonical ? bson_as_canonical_extended_json(bson.handle) : bson_as_relaxed_extended_json(bson.handle)
    if cstring == C_NULL
        error("Couldn't convert bson to json.")
    end
    return unsafe_string(cstring)
end

function Base.deepcopy(bson::BSON) :: BSON
    return BSON(bson_copy(bson.handle))
end

Client(host::String="localhost", port::Int=27017) = Client(URI("mongodb://$host:$port"))

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

# Example

```julia
julia> client = Mongoc.Client() # connects to localhost at port 27017
Client(URI("mongodb://localhost:27017"))

julia> bson_result = Mongoc.command_simple(client, "admin", "{ \"ping\" : 1 }")
Mongoc.BSON(Ptr{Nothing} @0x00007f8663e0d8d0)

julia> println(Mongoc.as_json_string(bson_result))
{ "ok" : 1.0 }
```

See also: `command_simple_as_json`.
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

"""
    command_simple_as_json(client::Client, database::String, command::Union{String, BSON}) :: String

Same as `command_simple`, but returns a JSON string.

# Example

```julia
julia> client = Mongoc.Client() # connects to localhost at port 27017
Client(URI("mongodb://localhost:27017"))

julia> result = Mongoc.command_simple_as_json(client, "admin", "{ \"ping\" : 1 }")
"{ \"ok\" : 1.0 }"
```
"""
function command_simple_as_json(client::Client, database::String, command::Union{String, BSON}) :: String
    return as_json_string(command_simple(client, database, command))
end

function command_simple_as_json(collection::Collection, command::Union{String, BSON}) :: String
    return as_json_string(command_simple(collection, command))
end

function ping(client::Client) :: String
    return command_simple_as_json(client, "admin", "{ \"ping\" : 1 }")
end

function insert_one(collection::Collection, document::BSON; options::Union{Nothing, BSON}=nothing) :: BSON
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_insert_one(collection.handle, document.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function find(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_find_with_opts(collection.handle, bson_filter.handle, options_handle, C_NULL)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(cursor_handle)
end

function Base.length(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing)
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    len = mongoc_collection_count_documents(collection.handle, bson_filter.handle, options_handle, C_NULL, C_NULL, err)
    if len == -1
        error("Couldn't count number of elements in $collection. $err.")
    end
    return Int(len)
end

#=
v1.0
next = iterate(iter)
while next != nothing
    (i, state) = next
    # body
    next = iterate(iter, state)
end

v0.6
state = start(I)
while !done(I, state)
    (i, state) = next(I, state)
    # body
end
=#

function _iterate(cursor::Cursor, state::Nothing=nothing)
    next = BSON()
    handle = next.handle
    handle_ref = Ref{Ptr{Cvoid}}(handle)
    has_next = mongoc_cursor_next(cursor.handle, handle_ref)
    next.handle = handle_ref[]

    if has_next
        return deepcopy(next), nothing
    else
        return nothing
    end
end

@static if VERSION < v"0.7-"

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
    Base.iterate(cursor::Cursor, state::Nothing=nothing) = _iterate(cursor, state)
end
