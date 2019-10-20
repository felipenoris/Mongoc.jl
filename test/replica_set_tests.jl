
#=
https://docs.mongodb.com/manual/tutorial/deploy-replica-set/

mkdir tmp
cd tmp

mkdir db1
mkdir db2
mkdir db3

mongod --dbpath ./db1 --port 27021 --replSet "rst" --bind_ip 127.0.0.1
mongod --dbpath ./db2 --port 27022 --replSet "rst" --bind_ip 127.0.0.1
mongod --dbpath ./db3 --port 27023 --replSet "rst" --bind_ip 127.0.0.1

mongo --port 27021 replica_set_initiate.js
=#

let
    fp_replicaset_script = joinpath(@__DIR__, "replica_set_initiate.js")
    @assert isfile(fp_replicaset_script)
    run(`mongo --port 27021 $fp_replicaset_script`)
    sleep(20)
end

import Mongoc

using Test
using Dates

const DB_REPLICA_NAME = "mongoc_replica"
const REPLICA_SET_URL = "mongodb://127.0.0.1:27021,127.0.0.1:27022,127.0.0.1:27023/?replicaSet=rst"

@testset "Connect to ReplicaSet" begin
    client = Mongoc.Client(REPLICA_SET_URL)
    database = client[DB_REPLICA_NAME]
    collection = database["my_collection"]
    @test isempty(collection)
    push!(collection, Mongoc.BSON("""{ "hey" : 1  }"""))
    @test length(collection) == 1
    doc = collect(collection)[1]
    @test doc["hey"] == 1
    empty!(collection)
end

@testset "Transaction API" begin
    client = Mongoc.Client(REPLICA_SET_URL)
    database = client[DB_REPLICA_NAME]
    collection = database["transaction"]
    @test isempty(collection)
    push!(collection, Mongoc.BSON("""{ "outside_transaction" : 1 }"""))
    @test length(collection) == 1

    session = Mongoc.Session(client)

    Mongoc.start_transaction!(session)
    @test Mongoc.in_transaction(session)
    collection_session = session[DB_REPLICA_NAME]["transaction"]
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
    client = Mongoc.Client(REPLICA_SET_URL)

    collection_unbounded = client[DB_REPLICA_NAME]["transaction"]
    @assert isempty(collection_unbounded) # test precondition

    Mongoc.transaction(client) do session # session = Mongoc.Session(client); Mongoc.start_transaction!(session)
        @test Mongoc.in_transaction(session)

        database = session[DB_REPLICA_NAME]
        collection = database["transaction"]
        @test isempty(collection)

        let # insert_many
            items = Vector{Mongoc.BSON}()
            push!(items, Mongoc.BSON("""{ "item" : 1 }"""))
            push!(items, Mongoc.BSON("""{ "item" : 2 }"""))
            push!(items, Mongoc.BSON("""{ "item" : 3 }"""))
            append!(collection, items)
            @test length(collection) == 3
            @test isempty(collection_unbounded)
            empty!(collection)
        end

        @test isempty(collection)
        @test Mongoc.in_transaction(session)

        let # insert_one
            new_item = Mongoc.BSON()
            new_item["inserted"] = true
            push!(collection, new_item)
            @test isempty(collection_unbounded)
            @test !isempty(collection)
        end

        @test Mongoc.in_transaction(session)

        let # delete_one
            item_to_delete = Mongoc.BSON()
            item_to_delete["inserted"] = true
            item_to_delete["to_delete"] = true
            push!(collection, item_to_delete)

            @test length(collection) == 2
            @test isempty(collection_unbounded)

            Mongoc.delete_one(collection, Mongoc.BSON("""{ "to_delete" : true }"""))

            @test length(collection) == 1
            @test isempty(collection_unbounded)
        end

        @test Mongoc.in_transaction(session)

        let # delete_many
            item_to_delete = Mongoc.BSON()
            item_to_delete["inserted"] = true
            item_to_delete["to_delete"] = true
            push!(collection, item_to_delete)

            @test length(collection) == 2
            @test isempty(collection_unbounded)

            Mongoc.delete_many(collection, Mongoc.BSON("""{ "to_delete" : true }"""))

            @test length(collection) == 1
            @test isempty(collection_unbounded)
        end

        @test Mongoc.in_transaction(session)

        let # update_one
            selector = Mongoc.BSON()
            update = Mongoc.BSON("""{ "\$set" : { "update_one" : true } }""")
            Mongoc.update_one(collection, selector, update)
        end

        @test Mongoc.in_transaction(session)

        let # update_many
            selector = Mongoc.BSON()
            update = Mongoc.BSON("""{ "\$set" : { "update_many" : true } }""")
            Mongoc.update_many(collection, selector, update)
        end

        @test Mongoc.in_transaction(session)

        let # check updates
            doc = Mongoc.find_one(collection, Mongoc.BSON())
            @test doc["update_one"]
            @test doc["update_many"]
            @test isempty(collection_unbounded)
        end

        @test Mongoc.in_transaction(session)
    end

    @test !isempty(collection_unbounded)
    empty!(collection_unbounded)

    try
        Mongoc.transaction(client) do session
            database = session[DB_REPLICA_NAME]
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

@testset "ClientPool" begin
    @testset "Create/Destroy" begin
        pool = Mongoc.ClientPool(REPLICA_SET_URL)
        Mongoc.destroy!(pool)
    end

    @testset "Client from ClientPool" begin
        pool = Mongoc.ClientPool(REPLICA_SET_URL, max_size=4)

        client1 = Mongoc.Client(pool)
        client2 = Mongoc.Client(pool)
        client3 = Mongoc.Client(pool)

        client = Mongoc.Client(pool)
        database = client[DB_REPLICA_NAME]
        collection = database["my_collection"]
        @test isempty(collection)
        push!(collection, Mongoc.BSON("""{ "hey" : 1  }"""))
        @test length(collection) == 1
        doc = collect(collection)[1]
        @test doc["hey"] == 1
        empty!(collection)

        @test_throws AssertionError Mongoc.Client(pool, try_pop=true)
    end
end
