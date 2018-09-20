
#=
https://docs.mongodb.com/manual/tutorial/deploy-replica-set/

mkdir tmp
cd tmp

mkdir db1
mkdir db2
mkdir db3

mongod --dbpath ./db1 --port 27021 --replSet "rs0" --bind_ip 127.0.0.1
mongod --dbpath ./db2 --port 27022 --replSet "rs0" --bind_ip 127.0.0.1
mongod --dbpath ./db3 --port 27023 --replSet "rs0" --bind_ip 127.0.0.1

mongo --port 27021 replica_set_initiate.js

=#

import Mongoc

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
    using Dates
end

const DB_NAME = "mongoc"

@testset "Connect to ReplicaSet" begin
    client = Mongoc.Client("mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0")
    database = client[DB_NAME]
    collection = database["my_collection"]
    @test isempty(collection)
    push!(collection, Mongoc.BSON("""{ "hey" : 1  }"""))
    @test length(collection) == 1
    doc = collect(collection)[1]
    @test doc["hey"] == 1
    empty!(collection)
end

@testset "Transaction API" begin
    client = Mongoc.Client("mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0")
    database = client[DB_NAME]
    collection = database["transaction"]
    @test isempty(collection)
    push!(collection, Mongoc.BSON("""{ "outside_transaction" : 1 }"""))
    @test length(collection) == 1

    session = Mongoc.Session(client)

    Mongoc.start_transaction!(session)
    @test Mongoc.in_transaction(session)
    collection_session = session[DB_NAME]["transaction"]
    push!(collection_session, Mongoc.BSON("""{ "inside_transaction" : 1 }"""))
    @test length(collection_session) == 2
    @test length(collection) == 1

    Mongoc.abort_transaction!(session)
    @test !Mongoc.in_transaction(session)
    @test length(collection_session) == 1

    Mongoc.start_transaction!(session)
    @test Mongoc.in_transaction(session)
    push!(collection_session, Mongoc.BSON("""{ "inside_transaction" : 2 }"""))
    @test length(collection_session) == 2
    @test length(collection) == 1

    Mongoc.commit_transaction!(session)
    @test length(collection_session) == 2
    @test length(collection) == 2

    empty!(collection)
end

@testset "Transaction High-Level API" begin
    client = Mongoc.Client("mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rs0")

    collection_unbounded = client[DB_NAME]["transaction"]

    Mongoc.transaction(client) do session
        database = session[DB_NAME]
        collection = database["transaction"]
        new_item = Mongoc.BSON()
        new_item["inserted"] = true
        push!(collection, new_item)
        @test isempty(collection_unbounded)
        @test !isempty(collection)
    end

    @test !isempty(collection_unbounded)
    empty!(collection_unbounded)

    try
        Mongoc.transaction(client) do session
            database = session[DB_NAME]
            collection = database["transaction"]
            new_item = Mongoc.BSON()
            new_item["inserted"] = true
            push!(collection, new_item)
            @test isempty(collection_unbounded)
            @test !isempty(collection)
            error("abort transaction")
        end
    catch e
        println("got an error: $e")
    end

    @test isempty(collection_unbounded)
end
