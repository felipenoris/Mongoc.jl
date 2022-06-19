
# Logging

The following example uses `Mongoc.mongoc_set_log_handler`
to set a customized log handler. In this example, the setup is done by calling `init_log_handler_if_safe()`.

```julia
using Logging

const MONGOC_LOG_LEVEL_ERROR = 0
const MONGOC_LOG_LEVEL_CRITICAL = 1
const MONGOC_LOG_LEVEL_WARNING = 2
const MONGOC_LOG_LEVEL_MESSAGE = 3
const MONGOC_LOG_LEVEL_INFO = 4
const MONGOC_LOG_LEVEL_DEBUG = 5
const MONGOC_LOG_LEVEL_TRACE = 6

if VERSION >= v"v1.7"
    @inline _isjuliathread() = @ccall(jl_get_pgcstack()::Ptr{Cvoid}) != C_NULL
else
    @inline _isjuliathread() = false
end

@noinline function _log_handler_do(level::Cint, domain::Ptr{UInt8}, message::Ptr{UInt8})
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

function _log_handler(level::Cint, domain::Ptr{UInt8}, message::Ptr{UInt8}, fallback::Ptr{Cvoid})
    # If called on a non-julia thread, e.g., from server monitor, fall back to default log handler.
    # TODO: change this when Julia safely supports foreign thread calls.
    if _isjuliathread()
        _log_handler_do(level, domain, message)
    else
        ccall(
            fallback,
            Cvoid,
            (Cint, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cvoid}),
            level, domain, message, C_NULL
        )
    end
end

function init_log_handler()
    _isjuliathread() || error("Intercepting mongo logging unsupported on $(VERSION)")
    Mongoc.mongoc_set_log_handler(
        @cfunction(_log_handler, Cvoid, (Cint, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cvoid})),
        cglobal((:mongoc_log_default_handler, Mongoc.libmongoc))
    )
end

function init_log_handler_if_safe()
    if _isjuliathread()
        init_log_handler()
    end
end
```
