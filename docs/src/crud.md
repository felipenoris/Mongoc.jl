
# CRUD Operations

## Insert

### API

```julia
Mongoc.insert_one(collection::Collection, document::BSON; options::Union{Nothing, BSON}=nothing)

Mongoc.insert_many(collection::Collection, documents::Vector{BSON}; bulk_options::Union{Nothing, BSON}=nothing, insert_options::Union{Nothing, BSON}=nothing)
```

`Mongoc.insert_one` is equivalent to `Base.push!` for a collection.
The same applies to `Mongoc.insert_many` in relation to `Base.append!`.

### Examples

```julia
push!(collection, Mongoc.BSON("""{ "hello" : "world" }"""))

append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
```

## Select

### API

```julia
find_one(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

find(collection::Collection, bson_filter::BSON=BSON(); options::Union{Nothing, BSON}=nothing) :: Cursor
```

### Examples

```julia
bson = Mongoc.find_one(collection, Mongoc.BSON("""{ "third" : 3 }"""))

for doc in Mongoc.find(collection)
    println(doc)
end
```

## Update

### API

```julia
Mongoc.update_one(collection::Collection, selector::BSON, update::BSON; options::Union{Nothing, BSON}=nothing)

Mongoc.update_many(collection::Collection, selector::BSON, update::BSON; options::Union{Nothing, BSON}=nothing)
```

### Examples

```julia
selector = Mongoc.BSON("""{ "delete" : false }""")
update = Mongoc.BSON("""{ "\$set" : { "delete" : true, "new_field" : 1 } }""")
Mongoc.update_one(collection, selector, update)

selector = Mongoc.BSON("""{ "delete" : true }""")
update = Mongoc.BSON("""{ "\$set" : { "delete" : false } }""")
Mongoc.update_many(collection, selector, update)
```

## Delete

### API

```julia
Mongoc.delete_one(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)

Mongoc.delete_many(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)
```

### Examples

```julia
selector = Mongoc.BSON()
selector["_id"] = oid
Mongoc.delete_one(collection, selector)

# deletes all elements in a collection
Mongoc.delete_many(collection, Mongoc.BSON()) # equivalent to `empty!(collection)`
```
