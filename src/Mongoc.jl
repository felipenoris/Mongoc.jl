
module Mongoc
using MongoC_jll

import Base.UUID
using Dates, DecFP, Logging, Serialization

#
# utility functions for date conversion
#

# offsets an additional year from UNIXEPOCH in milliseconds.
const ISODATE_OFFSET = Dates.UNIXEPOCH + 24 * 60 * 60 * 1000 * 365
isodate2datetime(millis::Int64) = Dates.epochms2datetime(millis + ISODATE_OFFSET)
datetime2isodate(dt::DateTime) = Dates.datetime2epochms(dt) - ISODATE_OFFSET

include("bson.jl")
include("types.jl")
include("c_api.jl")
include("client.jl")
include("clientpool.jl")
include("database.jl")
include("collection.jl")
include("session.jl")
include("streams.jl")
include("gridfs.jl")

const MONGOC_LOG_LEVEL_ERROR = 0
const MONGOC_LOG_LEVEL_CRITICAL = 1
const MONGOC_LOG_LEVEL_WARNING = 2
const MONGOC_LOG_LEVEL_MESSAGE = 3
const MONGOC_LOG_LEVEL_INFO = 4
const MONGOC_LOG_LEVEL_DEBUG = 5
const MONGOC_LOG_LEVEL_TRACE = 6

function _log_handler(level::Cint, domain::Ptr{UInt8}, message::Ptr{UInt8}, ::Ptr{Cvoid})
    jlevel = if level == MONGOC_LOG_LEVEL_ERROR
        Logging.Error
    elseif level == MONGOC_LOG_LEVEL_CRITICAL
        Logging.Error
    elseif level == MONGOC_LOG_LEVEL_WARNING
        Logging.Warn
    elseif level == MONGOC_LOG_LEVEL_MESSAGE
        Logging.Info
    elseif level == MONGOC_LOG_LEVEL_INFO
        Logging.Info
    elseif level == MONGOC_LOG_LEVEL_DEBUG
        Logging.Debug
    elseif level == MONGOC_LOG_LEVEL_TRACE
        Logging.Debug
    else
        error("Unexpected mongoc log level $level")
    end
    domain=unsafe_string(domain)
    message=unsafe_string(message)
    @logmsg jlevel "$domain $message"
    nothing
end

function __init__()
    ccall(
        (:mongoc_log_set_handler, libmongoc),
        Cvoid,
        (Ptr{Cvoid}, Ptr{Cvoid}),
        @cfunction(_log_handler, Cvoid, (Cint, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cvoid})), C_NULL
    )
    mongoc_init()
    atexit(mongoc_cleanup)
end

end # module Mongoc
