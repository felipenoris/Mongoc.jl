
# Transactions

Support for transactions is available from MongoDB v4.0.

## Setting up a Replica Set

As described in the [MongoDB Manual](https://docs.mongodb.com/manual/core/transactions/),
"*multi-document transactions are available for replica sets only. Transactions for sharded clusters are scheduled for MongoDB 4.2*".

Follow [these steps](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/)
to start a replica set.

## Executing Transactions

In MongoDB, **transactions** are bound to **Sessions**.

In **Mongoc.jl**, use the function `Mongoc.transaction` with *do-syntax* to execute a transaction,
and use the argument `session` to get database and collection references bound to the session
that will execute the transaction.

Just use the `session` object the same way you would use a `Client`.

!!! note

    Database and Collection references that are not created
    from a `session` object are not bound to the transaction.

## Example

```julia
import Mongoc

# connect to a Replica Set
client = Mongoc.Client("mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0")

# this collection reference is not bounded to the transaction
collection_unbounded = client["my_database"]["my_collection"]

# insert a dummy document, just to make sure the collection exists
push!(collection_unbounded, Mongoc.BSON("""{ "test" : 1 }"""))
empty!(collection_unbounded)

Mongoc.transaction(client) do session
    database = session["my_database"]
    collection = database["my_collection"]
    new_item = Mongoc.BSON()
    new_item["inserted"] = true
    push!(collection, new_item)
    println("collection_bounded is empty? ", isempty(collection_unbounded))
    println("collection is empty? ", isempty(collection))
end

println(collect(collection_unbounded))
```

The script output is:

```
collection_bounded is empty? true
collection is empty? false
Mongoc.BSON[BSON("{ "_id" : { "$oid" : "5ba4251f3192e3298b62c5a3" }, "inserted" : true }")]
```
