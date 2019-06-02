
# Transactions

Support for transactions is available from MongoDB v4.0.

## Setting up a Replica Set

As described in the [MongoDB Manual](https://docs.mongodb.com/manual/core/transactions/),
"*multi-document transactions are available for replica sets only. Transactions for sharded clusters are scheduled for MongoDB 4.2*".

Follow [these steps](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/)
to start a replica set. The following script will create a replica set with 3 nodes:

```shell
mkdir db1
mkdir db2
mkdir db3
mongod --dbpath ./db1 --port 27021 --replSet "rs0" --bind_ip 127.0.0.1
mongod --dbpath ./db2 --port 27022 --replSet "rs0" --bind_ip 127.0.0.1
mongod --dbpath ./db3 --port 27023 --replSet "rs0" --bind_ip 127.0.0.1
mongo --port 27021 replica_set_initiate.js
```

The contents of `replica_set_initiate.js` are:

```javascript
rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "127.0.0.1:27021" },
      { _id: 1, host: "127.0.0.1:27022" },
      { _id: 2, host: "127.0.0.1:27023" }
   ]
})
```

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
