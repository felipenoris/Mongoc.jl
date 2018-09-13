
#
# Tests depend on a running server at localhost:27017,
# and will create a database named "mongoc_tests".
#

import Mongoc

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
end

const DB_NAME = "mongoc_tests"

@testset "BSON" begin

    @testset "as_json" begin
        bson = Mongoc.BSON("{\"hey\" : 1}")
        @test Mongoc.as_json(bson) == "{ \"hey\" : 1 }"
        @test Mongoc.as_json(bson, canonical=true) == "{ \"hey\" : { \"\$numberInt\" : \"1\" } }"
    end

    @testset "BSONObjectId segfault issue" begin
        io = IOBuffer()
        v = Vector{Mongoc.BSONObjectId}()

        for i in 1:5
            push!(v, Mongoc.BSONObjectId())
        end
        show(io, v)
    end

    @testset "oid compare" begin
        x = Mongoc.BSONObjectId()
        y = Mongoc.BSONObjectId()
        @test x != y
        @test x == x
        @test y == y
        @test hash(x) == hash(x)
        @test hash(y) == hash(y)
        @test hash(x) != hash(y)
        @test Mongoc.bson_oid_compare(x, y) < 0
        @test Mongoc.bson_oid_compare(y, x) > 0
        @test Mongoc.bson_oid_compare(x, x) == 0
        @test Mongoc.bson_oid_compare(y, y) == 0
    end

    @testset "oid sort" begin
        v = Vector{Mongoc.BSONObjectId}()
        for i in 1:10_000
            push!(v, Mongoc.BSONObjectId())
        end
        @test length(v) == length(unique(v))

        v_sorted = sort(v, lt = (a,b) -> Mongoc.bson_oid_compare(a,b) < 0)
        @test length(v_sorted) == length(v)
        for i in 1:length(v_sorted)
            @test v_sorted[i] == v[i]
        end
    end
end

@testset "Types" begin
    bson = Mongoc.BSON()
    @test_throws ErrorException Mongoc.Client("////invalid-url")
    cli = Mongoc.Client()
    @test cli.uri == "mongodb://localhost:27017"
    Mongoc.set_appname!(cli, "Runtests")
    db = cli[DB_NAME]
    coll = db["new_collection"]

    io = IOBuffer()
    show(io, bson)
    show(io, cli)
    show(io, db)
    show(io, coll)
end

@testset "Connection" begin
    cli = Mongoc.Client()

    @testset "ping" begin
        bson_ping_result = Mongoc.ping(cli)
        @test haskey(bson_ping_result, "ok")
        @test Mongoc.as_json(Mongoc.ping(cli)) == "{ \"ok\" : 1.0 }"
    end

    @testset "new_collection" begin
        coll = cli[DB_NAME]["new_collection"]
        result = push!(coll, "{ \"hello\" : \"world\" }")
        @test Mongoc.as_json(result.reply) == "{ \"insertedCount\" : 1 }"
        result = push!(coll, "{ \"hey\" : \"you\" }")
        @test Mongoc.as_json(result.reply) == "{ \"insertedCount\" : 1 }"

        i = 0
        for bson in Mongoc.find(coll)
            i += 1
        end
        @test i == Mongoc.count_documents(coll)

        Mongoc.command_simple(coll, "{ \"collStats\" : \"new_collection\" }")
    end

    @testset "find_databases" begin
        found = false
        prefix = "{ \"name\" : \"mongoc_tests\""
        for obj in Mongoc.find_databases(cli)
            if startswith(Mongoc.as_json(obj), prefix)
                found = true
            end
        end
        @test found
    end
end
