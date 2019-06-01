
function ClientPool(uri::String; min_size::Union{Nothing, Integer}=nothing, max_size::Union{Nothing, Integer}=nothing)
    return ClientPool(URI(uri), min_size=min_size, max_size=max_size)
end

function set_min_size(client_pool::ClientPool, min_size::Integer)
    mongoc_client_pool_min_size(client_pool.handle, UInt32(min_size))
    nothing
end

function set_max_size(client_pool::ClientPool, max_size::Integer)
    mongoc_client_pool_max_size(client_pool.handle, UInt32(max_size))
    nothing
end
