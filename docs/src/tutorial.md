
# Tutorial

This tutorial illustrates common use cases for accessing a MongoDB database with **Mongoc.jl** package.

## Setup

First, make sure you have **Mongoc.jl** package installed.

```julia
julia> using Pkg

julia> Pkg.add("Mongoc")
```

The following tutorial assumes that a MongoDB instance is running on the
default host and port: `localhost:27017`.

To start a new server instance on the default location use the following command on your shell.

```shell
$ mkdir db

$ mongod --dbpath ./db --smallfiles
```

## Connecting to MongoDB

Connect to a MongoDB instance using a `Mongoc.Client`.
Use the [MongoDB URI format](https://docs.mongodb.com/manual/reference/connection-string/) to set the server location.

```julia
julia> import Mongoc

julia> client = Mongoc.Client("mongodb://localhost:27017")
Client(URI("mongodb://localhost:27017"))
```

As a shorthand, you can also use:

```julia
julia> client = Mongoc.Client("localhost", 27017)
```

To connect to the server at the default location `localhost:27017`
you can use the `Mongoc.Client` constructor with no arguments.

```julia
julia> client = Mongoc.Client()
```

One thing to keep in mind about MongoDB is that operations are usually lazy.
So you don't actually connect to the database until you need to issue a command or query.

If you need to check the connection status before sending commands,
use Mongoc.ping(client) to ping the server.

```julia
julia> Mongoc.ping(client)
BSON("{ "ok" : 1.0 }")
```

## Getting a Database

A MongoDB instance consists on a set of independent databases.
You get a Database reference using the following command.

```julia
julia> database = client["my-database"]
Database(Client(URI("mongodb://localhost:27017")), "my-database")
```

If `"my-database"` does not exist on your MongoDB instance, it will be created
in the first time you insert a document in it.

## Getting a Collection

A Collection is a set of documents in a MongoDB database.
You get a collection reference using the following command.

```julia
julia> collection = database["my-collection"]
Collection(Database(Client(URI("mongodb://localhost:27017")), "my-database"), "my-collection")
```

If it does not exist inside your database, the Collection
is created in the first time you insert a document in it.

## BSON Documents

[BSON](http://bsonspec.org/) is the document format for MongoDB.

To create a BSON document instance in **Mongoc.jl** just use Dictionary syntax,
using `String`s as keys.

```julia
julia> document = Mongoc.BSON()

julia> document["name"] = "Felipe"

julia> document["age"] = 35

julia> document["preferences"] = [ "Music", "Computer", "Photography" ]

julia> document["null_value"] = nothing # maps to BSON null value

julia> using Dates; document["details"] = Dict("birth date" => DateTime(1983, 4, 16), "location" => "Rio de Janeiro")
```

To convert a BSON to a JSON string, use:

```julia
julia> Mongoc.as_json(document)
"{ \"name\" : \"Felipe\", \"age\" : 35, \"preferences\" : [ \"Music\", \"Computer\", \"Photography\" ], \"null_value\" : null, \"details\" : { \"location\" : \"Rio de Janeiro\", \"birth date\" : { \"\$date\" : \"1983-04-16T00:00:00Z\" } } }"
```

You can also create a BSON document from a JSON string.

```julia
julia> document = Mongoc.BSON("""{ "hey" : "you" }""")
```

And also from a Dictionary.

```julia
julia> dict = Dict("hey" => "you")
Dict{String,String} with 1 entry:
  "hey" => "you"

julia> document = Mongoc.BSON(dict)
BSON("{ "hey" : "you" }")
```

To convert a BSON document to a Dictionary, use `Mongoc.as_dict`.

```julia
julia> Mongoc.as_dict(document)
Dict{Any,Any} with 1 entry:
  "hey" => "you"
```

## Read/Write BSON documents from/to IO Stream

You can read and write BSON documents in binary format to IO streams.

The following shows how to:

1. Create a vector of BSON documents.
2. Save the vector to a file.
3. Read back the vector of BSON documents from a file.

```julia
using Test

filepath = "data.bson"
list = Vector{Mongoc.BSON}()

let
    src = Mongoc.BSON()
    src["id"] = 1
    src["name"] = "1st"
    push!(list, src)
end

let
    src = Mongoc.BSON()
    src["id"] = 2
    src["name"] = "2nd"
    push!(list, src)
end

open(filepath, "w") do io
    Mongoc.write_bson(io, list)
end

list_from_file = Mongoc.read_bson(filepath)
@test length(list_from_file) == 2

let
    fst_bson = list_from_file[1]
    @test fst_bson["id"] == 1
    @test fst_bson["name"] == "1st"
end

let
    sec_bson = list_from_file[2]
    @test sec_bson["id"] == 2
    @test sec_bson["name"] == "2nd"
end
```

## Inserting Documents

To insert a single document into a collection, just `Base.push!` a BSON document to it.
The result of this operation wraps the server reply and the inserted oid.

```julia
julia> document = Mongoc.BSON("""{ "hey" : "you" }""")
BSON("{ "hey" : "you" }")

julia> result = push!(collection, document)
Mongoc.InsertOneResult{Mongoc.BSONObjectId}(BSON("{ "insertedCount" : 1 }"), BSONObjectId("5c9fdb5d11c3dd04a83ba6c2"))

julia> result.inserted_oid
BSONObjectId("5c9fdb5d11c3dd04a83ba6c2")
```

Use `Base.append!` to insert a vector of documents to a collection.
The result of this operation also wraps the server reply and the inserted oids.

```julia
julia> doc1 = Mongoc.BSON("""{ "hey" : "you", "out" : "there" }""")
BSON("{ "hey" : "you", "out" : "there" }")

julia> doc2 = Mongoc.BSON("""{ "hey" : "others", "in the" : "cold" }""")
BSON("{ "hey" : "others", "in the" : "cold" }")

julia> vector = [ doc1, doc2 ]
2-element Array{Mongoc.BSON,1}:
 BSON("{ "hey" : "you", "out" : "there" }")
 BSON("{ "hey" : "others", "in the" : "cold" }")

julia> append!(collection, vector)
Mongoc.BulkOperationResult{Union{Nothing, BSONObjectId}}(BSON("{ "nInserted" : 2, "nMatched" : 0, "nModified" : 0, "nRemoved" : 0, "nUpserted" : 0, "writeErrors" : [  ] }"), 0x00000001, Union{Nothing, BSONObjectId}[BSONObjectId("5c9fdbab11c3dd04a83ba6c3"), BSONObjectId("5c9fdbab11c3dd04a83ba6c4")])
```

## Querying Documents

To query a single document, use `Mongoc.find_one`. Pass a BSON argument as a query filter.

```julia
julia> document = Mongoc.find_one(collection, Mongoc.BSON("""{ "hey" : "you" }"""))
BSON("{ "_id" : { "$oid" : "5b9ef9cc11c3dd1da14675c3" }, "hey" : "you" }")
```

To iterate all documents from a collection, just use a for loop on a `collection`.

```julia
julia> for document in collection
        println(document)
       end
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e5" }, "hey" : "you", "out" : "there" }")
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

To query multiple documents, use `Mongoc.find`. Pass a BSON query argument as a query filter.
It returns a iterator of BSON documents that can be read using a `for` loop.

```julia
julia> for document in Mongoc.find(collection, Mongoc.BSON("""{ "in the" : "cold" }"""))
           println(document)
       end
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

Use `Base.collect` to convert the result of `Mongoc.find` into a vector of BSON documents.

Also, applying `Base.collect` to a Collection gathers all documents in the collection.

```julia
julia> collect(collection)
2-element Array{Mongoc.BSON,1}:
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e5" }, "hey" : "you", "out" : "there" }")
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

## Counting Documents

Use `Base.length` function to count the number of documents in a collection.
Pass a BSON argument as a query filter.

```julia
julia> length(collection)
2

julia> length(collection, Mongoc.BSON("""{ "in the" : "cold" }"""))
1
```

## Aggregation and Map-Reduce

Use `Mongoc.aggregate` to execute an aggregation command.

The following reproduces the example from the [MongoDB Tutorial](https://docs.mongodb.com/manual/aggregation/).

```julia
docs = [
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
]

collection = client["my-database"]["aggregation-collection"]
append!(collection, docs)

# Sets the pipeline command
bson_pipeline = Mongoc.BSON("""
    [
        { "\$match" : { "status" : "A" } },
        { "\$group" : { "_id" : "\$cust_id", "total" : { "\$sum" : "\$amount" } } }
    ]
""")

for doc in Mongoc.aggregate(collection, bson_pipeline)
  println(doc)
end
```

The result of the script above is:

```
BSON("{ "_id" : "B212", "total" : 200 }")
BSON("{ "_id" : "A123", "total" : 750 }")
```

A **Map-Reduce** operation can be executed with `Mongoc.command_simple`.

```julia
input_collection_name = "aggregation-collection"
output_collection_name = "order_totals"
query = Mongoc.BSON("""{ "status" : "A" }""")

# use `Mongoc.BSONCode` to represent JavaScript elements in BSON
mapper = Mongoc.BSONCode(""" function() { emit( this.cust_id, this.amount ); } """)
reducer = Mongoc.BSONCode(""" function(key, values) { return Array.sum( values ) } """)

map_reduce_command = Mongoc.BSON()
map_reduce_command["mapReduce"] = input_collection_name
map_reduce_command["map"] = mapper
map_reduce_command["reduce"] = reducer
map_reduce_command["out"] = output_collection_name
map_reduce_command["query"] = query

result = Mongoc.command_simple(database, map_reduce_command)
println(result)

for doc in Mongoc.find(database["order_totals"])
   println(doc)
end
```

The result of the script above is:

```
BSON("{ "result" : "order_totals", "timeMillis" : 135, "counts" : { "input" : 3, "emit" : 3, "reduce" : 1, "output" : 2 }, "ok" : 1.0 }")
BSON("{ "_id" : "A123", "value" : 750.0 }")
BSON("{ "_id" : "B212", "value" : 200.0 }")
```
