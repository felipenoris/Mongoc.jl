
"""
Mirrors C struct `mongoc_query_flags_t`.

These flags correspond to the MongoDB wire protocol.
They may be bitwise or’d together. They may modify how a query is performed in the MongoDB server.

From: http://mongoc.org/libmongoc/current/mongoc_query_flags_t.html
"""
primitive type QueryFlags sizeof(Cint) * 8 end

Base.convert(::Type{T}, t::QueryFlags) where {T<:Number} = reinterpret(Cint, t)
Base.convert(::Type{QueryFlags}, n::T) where {T<:Number} = reinterpret(QueryFlags, n)
QueryFlags(u::Cint) = convert(QueryFlags, u)
QueryFlags(i::Number) = QueryFlags(Cint(i))
Cint(flags::QueryFlags) = convert(Cint, flags)
Base.:(|)(flag1::QueryFlags, flag2::QueryFlags) = QueryFlags( Cint(flag1) | Cint(flag2) )
Base.:(&)(flag1::QueryFlags, flag2::QueryFlags) = QueryFlags( Cint(flag1) & Cint(flag2) )
Base.show(io::IO, flags::QueryFlags) = print(io, "QueryFlags($(Cint(flags)))")

"Specify no query flags."
const QUERY_FLAG_NONE              = QueryFlags(0)

"Cursor will not be closed when the last data is retrieved. You can resume this cursor later."
const QUERY_FLAG_TAILABLE_CURSOR   = QueryFlags(1 << 1)

"Allow query of replica set secondaries."
const QUERY_FLAG_SLAVE_OK          = QueryFlags(1 << 2)

"Used internally by MongoDB."
const QUERY_FLAG_OPLOG_REPLAY      = QueryFlags(1 << 3)

"The server normally times out an idle cursor after an inactivity period (10 minutes). This prevents that."
const QUERY_FLAG_NO_CURSOR_TIMEOUT = QueryFlags(1 << 4)

"Use with MONGOC_QUERY_TAILABLE_CURSOR. Block rather than returning no data. After a period, time out."
const QUERY_FLAG_AWAIT_DATA        = QueryFlags(1 << 5)

"Stream the data down full blast in multiple “reply” packets. Faster when you are pulling down a lot of data and you know you want to retrieve it all."
const QUERY_FLAG_EXHAUST           = QueryFlags(1 << 6)

"Get partial results from mongos if some shards are down (instead of throwing an error)."
const QUERY_FLAG_PARTIAL           = QueryFlags(1 << 7)

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
        finalizer(destroy!, new_uri)
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
        finalizer(destroy!, client)
        return client
    end
end

abstract type AbstractDatabase end
abstract type AbstractCollection end

"`Database` is a wrapper for C struct `mongoc_database_t`."
mutable struct Database <: AbstractDatabase
    client::Client
    name::String
    handle::Ptr{Cvoid}

    function Database(client::Client, db_name::String)
        db = new(client, db_name, mongoc_client_get_database(client.handle, db_name))
        finalizer(destroy!, db)
        return db
    end
end

"`Collection` is a wrapper for C struct `mongoc_collection_t`."
mutable struct Collection <: AbstractCollection
    database::Database
    name::String
    handle::Ptr{Cvoid}

    function Collection(database::Database, collection_name::String)
        collection_handle = mongoc_database_get_collection(database.handle, collection_name)
        if collection_handle == C_NULL
            error("Failed creating collection $collection_name on db $(database.name).")
        end
        collection = new(database, collection_name, collection_handle)
        finalizer(destroy!, collection)
        return collection
    end
end

const CursorSource = Union{Client, AbstractDatabase, AbstractCollection}

"`Cursor` is a wrapper for C struct `mongoc_cursor_t`."
mutable struct Cursor{T<:CursorSource}
    source::T
    handle::Ptr{Cvoid}

    function Cursor(source::T, handle::Ptr{Cvoid}) where {T<:CursorSource}
        cursor = new{T}(source, handle)
        finalizer(destroy!, cursor)
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
        finalizer(destroy!, bulk_operation)
        return bulk_operation
    end
end

struct InsertOneResult{T}
    reply::BSON
    inserted_oid::T
end

struct BulkOperationResult{T}
    reply::BSON
    server_id::UInt32
    inserted_oids::Vector{T}
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

#
# Session Types
#

mutable struct SessionOptions
    handle::Ptr{Cvoid}

    function SessionOptions(; casual_consistency::Bool=true)
        session_options_handle = mongoc_session_opts_new()
        if session_options_handle == C_NULL
            error("Couldn't create SessionOptions.")
        end

        session_options = new(session_options_handle)
        finalizer(destroy!, session_options)
        set_casual_consistency!(session_options, casual_consistency)
        return session_options
    end
end

mutable struct Session
    client::Client
    options::SessionOptions
    handle::Ptr{Cvoid}

    function Session(client::Client; options::SessionOptions=SessionOptions())
        err = BSONError()
        session_handle = mongoc_client_start_session(client.handle, options.handle, err)
        if session_handle == C_NULL
            error("$err")
        end
        session = new(client, options, session_handle)
        finalizer(destroy!, session)
        return session
    end
end

struct DatabaseSession <: AbstractDatabase
    database::Database
    session::Session
end

struct CollectionSession <: AbstractCollection
    database_session::DatabaseSession
    collection::Collection
end

#=
struct BulkOperationSession
    collection_session::CollectionSession
    bulk_operation::BulkOperation

    function BulkOperationSession(collection_session::CollectionSession, options::Union{Nothing, BSON})
        options_with_session = _join(options, get_session(collection_session))
        bulk_operation = BulkOperation(collection_session.collection, options=options_with_session)
        return BulkOperationSession(collection_session, bulk_operation)
    end
end
=#

function destroy!(session_options::SessionOptions)
    if session_options.handle != C_NULL
        mongoc_session_opts_destroy(session_options.handle)
        session_options.handle = C_NULL
    end
    nothing
end

function destroy!(session::Session)
    if session.handle != C_NULL
        mongoc_client_session_destroy(session.handle)
        session.handle = C_NULL
    end
    nothing
end
