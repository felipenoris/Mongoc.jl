
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
    domain = unsafe_string(domain)
    message = unsafe_string(message)
    @logmsg jlevel "$domain $message"
    nothing
end

function init_log_handler()
	mongoc_set_log_handler(@cfunction(_log_handler, Cvoid, (Cint, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cvoid})))
end
