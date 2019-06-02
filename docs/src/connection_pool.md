
# Connection Pool

A `ClientPool` is a *thread-safe* pool of connections to a MongoDB instance.

From a `ClientPool` you can create regular `Client` connections to MongoDB.

```julia
const REPLICA_SET_URL = "mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0"

# creates a ClientPool with a maximum of 4 connections.
pool = Mongoc.ClientPool(REPLICA_SET_URL, max_size=4)

# create Clients from a pool
client1 = Mongoc.Client(pool)
client2 = Mongoc.Client(pool)
client3 = Mongoc.Client(pool)
client4 = Mongoc.Client(pool)
```

When you reach the maximum number of clients,
the next call to `Mongoc.Client(pool)` will block
until a `Client` is released.

Use `try_pop=true` option to throw an error instead
of blocking the current thread:

```julia
# will throw `AssertionError`
client5 = Mongoc.Client(pool, try_pop=true)
```
