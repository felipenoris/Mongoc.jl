
"""
Mirrors C struct `bson_error_t`.

`BSONError` instances addresses are passed
to libmongoc API using `Ref{BSONError}(error)`,
and are owned by the Julia process.

```c
typedef struct {
   uint32_t domain;
   uint32_t code;
   char message[504];
} bson_error_t;
```
"""
mutable struct BSONError
    domain::UInt32
    code::UInt32
    message::NTuple{504, UInt8}

    BSONError() = new(0, 0, tuple(zeros(UInt8, 504)...))
end

"`BSON` is a wrapper for C struct `bson_t`."
mutable struct BSON
    handle::Ptr{Cvoid}

    function BSON(handle::Ptr{Cvoid})
        new_bson = new(handle)
        @compat finalizer(destroy!, new_bson)
        return new_bson
    end
end

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
    db_name::String
    handle::Ptr{Cvoid}

    function Database(client::Client, db_name::String)
        db = new(client, db_name, mongoc_client_get_database(client.handle, db_name))
        @compat finalizer(destroy!, db)
        return db
    end
end

"`Collection` is a wrapper for C struct `mongoc_collection_t`."
mutable struct Collection
    client::Client
    db_name::String
    coll_name::String
    handle::Ptr{Cvoid}

    function Collection(client::Client, db_name::String, coll_name::String)
        coll_handle = mongoc_client_get_collection(client.handle, db_name, coll_name)
        if coll_handle == C_NULL
            error("Failed creating collection $coll_name on db $db_name.")
        end
        coll = new(client, db_name, coll_name, coll_handle)
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

#
# Basic functions for types
#

Base.show(io::IO, err::BSONError) = print(io, replace(String([ i for i in err.message]), '\0' => ""))
Base.show(io::IO, uri::URI) = print(io, "URI(\"", uri.uri, "\")")
Base.show(io::IO, client::Client) = print(io, "Client(URI(\"", client.uri, "\"))")
Base.show(io::IO, db::Database) = print(io, "Database($(db.client), \"", db.name, "\")")
Base.show(io::IO, coll::Collection) = print(io, "Collection($(coll.client), \"", coll.db_name, "\", \"", coll.coll_name, "\")")

function destroy!(bson::BSON)
    if bson.handle != C_NULL
        bson_destroy(bson.handle)
        bson.handle = C_NULL
    end
    nothing
end

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
