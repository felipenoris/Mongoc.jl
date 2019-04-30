
"""
`QueryFlags` correspond to the MongoDB wire protocol.
They may be bitwise or’d together.
They may modify how a query is performed in the MongoDB server.

These flags are passed as optional argument
for the aggregation function `Mongoc.aggregate`.

This data type mirrors C struct `mongoc_query_flags_t`.
See [libmongoc docs](http://mongoc.org/libmongoc/current/mongoc_query_flags_t.html)
for more information.

# Constants

`Mongoc.QUERY_FLAG_NONE`:
Specify no query flags.

`Mongoc.QUERY_FLAG_TAILABLE_CURSOR`:
Cursor will not be closed when the last data is retrieved. You can resume this cursor later.

`Mongoc.QUERY_FLAG_SLAVE_OK`:
Allow query of replica set secondaries.

`Mongoc.QUERY_FLAG_OPLOG_REPLAY`:
Used internally by MongoDB.

`Mongoc.QUERY_FLAG_NO_CURSOR_TIMEOUT`:
The server normally times out an idle cursor after an inactivity period (10 minutes).
This prevents that.

`Mongoc.QUERY_FLAG_AWAIT_DATA`:
Use with `Mongoc.MONGOC_QUERY_TAILABLE_CURSOR`. Block rather than returning no data.
After a period, time out.

`Mongoc.QUERY_FLAG_EXHAUST`:
Stream the data down full blast in multiple "reply" packets.
Faster when you are pulling down a lot of data and you know you want to retrieve it all.

`Mongoc.QUERY_FLAG_PARTIAL`:
Get partial results from mongos if some shards are down (instead of throwing an error).
"""
primitive type QueryFlags sizeof(Cint) * 8 end

"""
Adds one or more flags to the `FindAndModifyOptsBuilder`.
These flags can be *ORed* together,
as in `flags = Mongoc.FIND_AND_MODIFY_FLAG_UPSERT | Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW`.

* `FIND_AND_MODIFY_FLAG_NONE`: Default. Doesn’t add anything to the builder.

* `FIND_AND_MODIFY_FLAG_REMOVE`: Will instruct find_and_modify to remove the matching document.

* `FIND_AND_MODIFY_FLAG_UPSERT`: Update the matching document or, if no document matches, insert the document.

* `FIND_AND_MODIFY_FLAG_RETURN_NEW`: Return the resulting document.
"""
primitive type FindAndModifyFlags sizeof(Cint) * 8 end

const QueryOrFindAndModifyFlags = Union{QueryFlags, FindAndModifyFlags}

Base.convert(::Type{T}, t::QueryOrFindAndModifyFlags) where {T<:Number} = reinterpret(Cint, t)
Base.convert(::Type{Q}, n::T) where {Q<:QueryOrFindAndModifyFlags, T<:Number} = reinterpret(Q, n)
Cint(flags::QueryOrFindAndModifyFlags) = convert(Cint, flags)
Base.:(|)(flag1::T, flag2::T) where {T<:QueryOrFindAndModifyFlags} = T( Cint(flag1) | Cint(flag2) )
Base.:(&)(flag1::T, flag2::T) where {T<:QueryOrFindAndModifyFlags} = T( Cint(flag1) & Cint(flag2) )

QueryFlags(u::Cint) = convert(QueryFlags, u)
QueryFlags(i::Number) = QueryFlags(Cint(i))
Base.show(io::IO, flags::QueryFlags) = print(io, "QueryFlags($(Cint(flags)))")

FindAndModifyFlags(u::Cint) = convert(FindAndModifyFlags, u)
FindAndModifyFlags(i::Number) = FindAndModifyFlags(Cint(i))
Base.show(io::IO, flags::FindAndModifyFlags) = print(io, "FindAndModifyFlags($(Cint(flags)))")

const QUERY_FLAG_NONE              = QueryFlags(0)
const QUERY_FLAG_TAILABLE_CURSOR   = QueryFlags(1 << 1)
const QUERY_FLAG_SLAVE_OK          = QueryFlags(1 << 2)
const QUERY_FLAG_OPLOG_REPLAY      = QueryFlags(1 << 3)
const QUERY_FLAG_NO_CURSOR_TIMEOUT = QueryFlags(1 << 4)
const QUERY_FLAG_AWAIT_DATA        = QueryFlags(1 << 5)
const QUERY_FLAG_EXHAUST           = QueryFlags(1 << 6)
const QUERY_FLAG_PARTIAL           = QueryFlags(1 << 7)

const FIND_AND_MODIFY_FLAG_NONE = FindAndModifyFlags(0)
const FIND_AND_MODIFY_FLAG_REMOVE = FindAndModifyFlags(1 << 0)
const FIND_AND_MODIFY_FLAG_UPSERT = FindAndModifyFlags(1 << 1)
const FIND_AND_MODIFY_FLAG_RETURN_NEW = FindAndModifyFlags(1 << 2)

# `URI` is a wrapper for C struct `mongoc_uri_t`."
mutable struct URI
    uri::String
    handle::Ptr{Cvoid}

    function URI(uri_string::String)
        err_ref = Ref{BSONError}()
        handle = mongoc_uri_new_with_error(uri_string, err_ref)
        if handle == C_NULL
            throw(err_ref[])
        end
        new_uri = new(uri_string, handle)
        finalizer(destroy!, new_uri)
        return new_uri
    end
end

# `Client` is a wrapper for C struct `mongoc_client_t`.
mutable struct Client
    uri::String
    handle::Ptr{Cvoid}

    function Client(uri::URI)
        client_handle = mongoc_client_new_from_uri(uri.handle)
        @assert client_handle != C_NULL "Failed to create client handle to URI $uri."
        client = new(uri.uri, client_handle)
        finalizer(destroy!, client)
        return client
    end
end

abstract type AbstractDatabase end
abstract type AbstractCollection end

# `Database` is a wrapper for C struct `mongoc_database_t`.
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

# `Collection` is a wrapper for C struct `mongoc_collection_t`.
mutable struct Collection <: AbstractCollection
    database::Database
    name::String
    handle::Ptr{Cvoid}

    function Collection(database::Database, collection_name::String)
        collection_handle = mongoc_database_get_collection(database.handle, collection_name)
        @assert collection_handle != C_NULL "Failed to create a collection handle to $collection_name on db $(database.name)."
        collection = new(database, collection_name, collection_handle)
        finalizer(destroy!, collection)
        return collection
    end
end

const CursorSource = Union{Client, AbstractDatabase, AbstractCollection}

# `Cursor` is a wrapper for C struct `mongoc_cursor_t`.
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
        @assert handle != C_NULL "Failed to create a bulk operation handle."
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
        @assert session_options_handle != C_NULL "Failed to create session options handle."
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
        err_ref = Ref{BSONError}()
        session_handle = mongoc_client_start_session(client.handle, options.handle, err_ref)
        if session_handle == C_NULL
            throw(err_ref[])
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

mutable struct FindAndModifyOptsBuilder
    handle::Ptr{Cvoid}

    function FindAndModifyOptsBuilder(;
        update::Union{Nothing, BSON}=nothing,
        sort::Union{Nothing, BSON}=nothing,
        fields::Union{Nothing, BSON}=nothing,
        flags::Union{Nothing, FindAndModifyFlags}=nothing,
        bypass_document_validation::Bool=false,
    )

        opts = new(mongoc_find_and_modify_opts_new())
        finalizer(destroy!, opts)

        if update != nothing
            opts.update = update
        end

        if sort != nothing
            opts.sort = sort
        end

        if fields != nothing
            opts.fields = fields
        end

        if flags != nothing
            opts.flags = flags
        end

        opts.bypass_document_validation = bypass_document_validation

        return opts
    end
end

function destroy!(opts::FindAndModifyOptsBuilder)
    if opts.handle != C_NULL
        mongoc_find_and_modify_opts_destroy(opts.handle)
        opts.handle = C_NULL
    end
    nothing
end
