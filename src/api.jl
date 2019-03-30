
#
# Public API
#

Client(host::String, port::Int) = Client(URI("mongodb://$host:$port"))
Client(uri::String) = Client(URI(uri))
Client() = Client("localhost", 27017)

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
    command_simple(database::Database, command::Union{String, BSON}) :: BSON

Executes a `command` given by a JSON string or a BSON instance.

It returns the first document from the result cursor.

# Example

```julia
julia> client = Mongoc.Client() # connects to localhost at port 27017
Client(URI("mongodb://localhost:27017"))

julia> bson_result = Mongoc.command_simple(client[\"admin\"], "{ \"ping\" : 1 }")
BSON("{ "ok" : 1.0 }")
```

# C API

* [`mongoc_database_command_simple`](http://mongoc.org/libmongoc/current/mongoc_database_command_simple.html)

"""
function command_simple(database::Database, command::BSON) :: BSON
    reply = BSON()
    err = BSONError()
    ok = mongoc_database_command_simple(database.handle, command.handle, C_NULL, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
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

function ping(client::Client) :: BSON
    return command_simple(client["admin"], BSON("""{ "ping" : 1 }"""))
end

"Queries the version for the MongoDB server instance."
function get_server_mongodb_version(client::Client) :: VersionNumber
    bson_server_status = command_simple(client["admin"], BSON("""{ "serverStatus" : 1 }"""))
    return VersionNumber(bson_server_status["version"])
end

function find_databases(client::Client; options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_client_find_databases_with_opts(client.handle, options_handle)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(client, cursor_handle)
end

function get_database_names(client::Client; options::Union{Nothing, BSON}=nothing) :: Vector{String}
    result = Vector{String}()
    for bson_database in find_databases(client, options=options)
        push!(result, bson_database["name"])
    end
    return result
end

function has_database(client::Client, database_name::String; options::Union{Nothing, BSON}=nothing) :: Bool
    for bson_database in find_databases(client, options=options)
        if bson_database["name"] == database_name
            return true
        end
    end
    return false
end

"""
    add_user(database::Database, username::String, password::String, roles::Union{Nothing, BSON}, custom_data::Union{Nothing, BSON}=nothing)

This function shall create a new user with access to database.

Warning: Do not call this function without TLS.
"""
function add_user(database::Database, username::String, password::String, roles::Union{Nothing, BSON}, custom_data::Union{Nothing, BSON}=nothing)
    err = BSONError()
    roles_handle = roles == nothing ? C_NULL : roles.handle
    custom_data_handle = custom_data == nothing ? C_NULL : custom_data.handle
    ok = mongoc_database_add_user(database.handle, username, password, roles_handle, custom_data_handle, err)
    if !ok
        error("$err")
    end
    nothing
end

"""
    remove_user(database::Database, username::String)

Removes a user from database.
"""
function remove_user(database::Database, username::String)
    err = BSONError()
    ok = mongoc_database_remove_user(database.handle, username, err)
    if !ok
        error("$err")
    end
    nothing
end

"""
    has_user(database::Database, user_name::String) :: Bool

Checks if `database` has a user named `user_name`.
"""
function has_user(database::Database, user_name::String) :: Bool
    cmd_result = command_simple(database, BSON("""{ "usersInfo": "$user_name" }"""))
    return !isempty(cmd_result["users"])
end

function find_collections(database::Database; options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_database_find_collections_with_opts(database.handle, options_handle)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(database, cursor_handle)
end

function get_collection_names(database::Database; options::Union{Nothing, BSON}=nothing) :: Vector{String}
    result = Vector{String}()
    for bson_collection in find_collections(database, options=options)
        push!(result, bson_collection["name"])
    end
    return result
end

# Aux function to add _id field to document if it does not exist.
function _new_id(document::BSON)
    if haskey(document, "_id")
        return document, nothing
    else
        inserted_oid = BSONObjectId()
        document = deepcopy(document) # copies it so this function doesn't have side effects
        document["_id"] = inserted_oid
        return document, inserted_oid
    end
end

function insert_one(collection::Collection, document::BSON; options::Union{Nothing, BSON}=nothing) :: InsertOneResult
    document, inserted_oid = _new_id(document)
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_insert_one(collection.handle, document.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return InsertOneResult(reply, inserted_oid)
end

function delete_one(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_delete_one(collection.handle, selector.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function delete_many(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_delete_many(collection.handle, selector.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function update_one(collection::Collection, selector::BSON, update::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_update_one(collection.handle, selector.handle, update.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

function update_many(collection::Collection, selector::BSON, update::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_update_many(collection.handle, selector.handle, update.handle, options_handle, reply.handle, err)
    if !ok
        error("$err.")
    end
    return reply
end

BulkOperationResult(reply::BSON, server_id::UInt32) = BulkOperationResult(reply, server_id, Vector{Union{Nothing, BSONObjectId}}())

function execute!(bulk_operation::BulkOperation) :: BulkOperationResult
    if bulk_operation.executed
        error("Bulk operation was already executed.")
    end

    try
        reply = BSON()
        err = BSONError()
        bulk_operation_result = mongoc_bulk_operation_execute(bulk_operation.handle, reply.handle, err)
        if bulk_operation_result == 0
            error("Bulk operation execution failed. $err.")
        end
        return BulkOperationResult(reply, bulk_operation_result)
    finally
        destroy!(bulk_operation)
    end
end

function bulk_insert!(bulk_operation::BulkOperation, document::BSON; options::Union{Nothing, BSON}=nothing)
    err = BSONError()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_bulk_operation_insert_with_opts(bulk_operation.handle, document.handle, options_handle, err)
    if !ok
        error("Bulk insert failed. $err.")
    end
    nothing
end

function insert_many(collection::Collection, documents::Vector{BSON}; bulk_options::Union{Nothing, BSON}=nothing, insert_options::Union{Nothing, BSON}=nothing)
    inserted_oids = Vector{Union{Nothing, BSONObjectId}}()

    bulk_operation = BulkOperation(collection, options=bulk_options)
    for doc in documents
        doc, inserted_oid = _new_id(doc)
        bulk_insert!(bulk_operation, doc, options=insert_options)
        push!(inserted_oids, inserted_oid)
    end
    result = execute!(bulk_operation)
    append!(result.inserted_oids, inserted_oids)
    return result
end

function find(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_find_with_opts(collection.handle, bson_filter.handle, options_handle, C_NULL)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(collection, cursor_handle)
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

function aggregate(collection::Collection, bson_pipeline::BSON; flags::QueryFlags=QUERY_FLAG_NONE, options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_aggregate(collection.handle, flags, bson_pipeline.handle, options_handle, C_NULL)
    if cursor_handle == C_NULL
        error("Couldn't execute aggregate command.")
    end
    return Cursor(collection, cursor_handle)
end

#
# High-level API
#

function _iterate(cursor::Cursor, state::Nothing=nothing)
    bson_handle_ref = Ref{Ptr{Cvoid}}()
    has_next = mongoc_cursor_next(cursor.handle, bson_handle_ref)

    if has_next
        # The bson document is valid only until the next call to mongoc_cursor_next.
        # So we should return a deepcopy.
        return deepcopy(BSON(bson_handle_ref[], enable_finalizer=false)), nothing
    else
        err = BSONError()
        if mongoc_cursor_error(cursor.handle, err)
            error("$err")
        end

        return nothing
    end
end

Base.iterate(cursor::Cursor, state::Nothing=nothing) = _iterate(cursor, state)

function Base.iterate(coll::Collection)
    cursor = find(coll)
    return iterate(coll, cursor)
end

function Base.iterate(coll::Collection, state::Cursor)
    next = _iterate(state)
    if next == nothing
        return nothing
    else
        doc, _ = next
        return doc, state
    end
end

Base.show(io::IO, uri::URI) = print(io, "URI(\"", uri.uri, "\")")
Base.show(io::IO, client::Client) = print(io, "Client(URI(\"", client.uri, "\"))")
Base.show(io::IO, db::Database) = print(io, "Database($(db.client), \"", db.name, "\")")
Base.show(io::IO, coll::Collection) = print(io, "Collection($(coll.database), \"", coll.name, "\")")

Base.getindex(client::Client, database::String) = Database(client, database)
Base.getindex(database::Database, collection_name::String) = Collection(database, collection_name)

Base.push!(collection::C, document::BSON; options::Union{Nothing, BSON}=nothing) where {C<:AbstractCollection} = insert_one(collection, document; options=options)
Base.append!(collection::C, documents::Vector{BSON}; bulk_options::Union{Nothing, BSON}=nothing, insert_options::Union{Nothing, BSON}=nothing) where {C<:AbstractCollection}= insert_many(collection, documents; bulk_options=bulk_options, insert_options=insert_options)

Base.length(collection::C, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) where {C<:AbstractCollection} = count_documents(collection, bson_filter; options=options)
Base.isempty(collection::C, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) where {C<:AbstractCollection} = count_documents(collection, bson_filter; options=options) == 0
Base.empty!(collection::C) where {C<:AbstractCollection} = delete_many(collection, BSON())

function Base.collect(cursor::Cursor) :: Vector{BSON}
    result = Vector{BSON}()
    for doc in cursor
        push!(result, doc)
    end
    return result
end

Base.collect(collection::C, bson_filter::BSON=BSON()) where {C<:AbstractCollection} = collect(find(collection, bson_filter))
