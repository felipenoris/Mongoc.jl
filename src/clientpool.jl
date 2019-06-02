
"""
    ClientPool(uri; [max_size])

Creates a pool of connections to a MongoDB instance.

# Example

```julia
const REPLICA_SET_URL = "mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0"

pool = Mongoc.ClientPool(REPLICA_SET_URL, max_size=2)

# create Clients from a pool
client1 = Mongoc.Client(pool)
client2 = Mongoc.Client(pool)
```

When you reach the maximum number of clients,
the next call to `Mongoc.Client(pool)` will block
until a `Client` is released.

Use `try_pop=true` option to throw an error instead
of blocking the current thread:

```julia
# will throw `AssertionError`
client3 = Mongoc.Client(pool, try_pop=true)
```
"""
function ClientPool(uri::String; max_size::Union{Nothing, Integer}=nothing)
    return ClientPool(URI(uri), max_size=max_size)
end

"""
    set_max_size(pool, max_size)

Set the maximum number of clients on the client pool.

# Example

```julia
const REPLICA_SET_URL = "mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0"
pool = Mongoc.ClientPool(REPLICA_SET_URL)

Mongoc.set_max_size(pool, 4)
```
"""
function set_max_size(client_pool::ClientPool, max_size::Integer)
    mongoc_client_pool_max_size(client_pool.handle, UInt32(max_size))
    nothing
end
