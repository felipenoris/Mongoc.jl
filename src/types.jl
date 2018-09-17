
"`URI` is a wrapper for C struct `mongoc_uri_t`."
mutable struct URI
    uri::String
    handle::Ptr{Cvoid}

    function URI(uri_string::String)
        err = BSONError()
        handle = mongoc_uri_new_with_error(uri_string, err)
        if handle == C_NULL
            error("Failed to parse URI $uri_string. Error Message: $(err)")
        end
        new_uri = new(uri_string, handle)
        @compat finalizer(destroy!, new_uri)
        return new_uri
    end
end

"`Client` is a wrapper for C struct `mongoc_client_t`."
mutable struct Client
    uri::String
    handle::Ptr{Cvoid}

    function Client(uri::URI)
        client_handle = mongoc_client_new_from_uri(uri.handle)
        if client_handle == C_NULL
            error("Failed connecting to URI $uri.")
        end
        client = new(uri.uri, client_handle)
        @compat finalizer(destroy!, client)
        return client
    end
end

"`Database` is a wrapper for C struct `mongoc_database_t`."
mutable struct Database
    client::Client
    name::String
    handle::Ptr{Cvoid}

    function Database(client::Client, db_name::String)
        db = new(client, db_name, mongoc_client_get_database(client.handle, db_name))
        @compat finalizer(destroy!, db)
        return db
    end
end

"`Collection` is a wrapper for C struct `mongoc_collection_t`."
mutable struct Collection
    database::Database
    name::String
    handle::Ptr{Cvoid}

    function Collection(database::Database, coll_name::String, coll_handle::Ptr{Cvoid})
        coll = new(database, coll_name, coll_handle)
        @compat finalizer(destroy!, coll)
        return coll
    end
end

"`Cursor` is a wrapper for C struct `mongoc_cursor_t`."
mutable struct Cursor
    handle::Ptr{Cvoid}

    function Cursor(handle::Ptr{Cvoid})
        cursor = new(handle)
        @compat finalizer(destroy!, cursor)
        return cursor
    end
end

mutable struct BulkOperation
    collection::Collection
    handle::Ptr{Cvoid}
    executed::Bool

    function BulkOperation(collection::Collection; options::Union{Nothing, BSON}=nothing)
        options_handle = options == nothing ? C_NULL : options.handle
        handle = mongoc_collection_create_bulk_operation_with_opts(collection.handle, options_handle)
        if handle == C_NULL
            error("Failed to create a new bulk operation.")
        end
        bulk_operation = new(collection, handle, false)
        @compat finalizer(destroy!, bulk_operation)
        return bulk_operation
    end
end

#
# Basic functions for types
#

function destroy!(uri::URI)
    if uri.handle != C_NULL
        mongoc_uri_destroy(uri.handle)
        uri.handle = C_NULL
    end
    nothing
end

function destroy!(client::Client)
    if client.handle != C_NULL
        mongoc_client_destroy(client.handle)
        client.handle = C_NULL
    end
    nothing
end

function destroy!(database::Database)
    if database.handle != C_NULL
        mongoc_database_destroy(database.handle)
        database.handle = C_NULL
    end
    nothing
end

function destroy!(collection::Collection)
    if collection.handle != C_NULL
        mongoc_collection_destroy(collection.handle)
        collection.handle = C_NULL
    end
    nothing
end

function destroy!(cursor::Cursor)
    if cursor.handle != C_NULL
        mongoc_cursor_destroy(cursor.handle)
        cursor.handle = C_NULL
    end
    nothing
end

function destroy!(bulk_operation::BulkOperation)
    if bulk_operation.handle != C_NULL
        mongoc_bulk_operation_destroy(bulk_operation.handle)
        bulk_operation.handle = C_NULL
        bulk_operation.executed = true
    end
    nothing
end

struct InsertOneResult
    reply::BSON
    inserted_oid::Union{Nothing, String}
end

struct BulkOperationResult
    reply::BSON
    server_id::UInt32
    inserted_oids::Vector{Union{Nothing, String}}
end
