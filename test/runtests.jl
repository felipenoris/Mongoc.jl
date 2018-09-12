
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
    bson = Mongoc.BSON("{\"hey\" : 1}")
    @test Mongoc.as_json_string(bson) == "{ \"hey\" : 1 }"
    @test Mongoc.as_json_string(bson, canonical=true) == "{ \"hey\" : { \"\$numberInt\" : \"1\" } }"
end

@testset "Types" begin
    @test_throws ErrorException Mongoc.Client("////invalid-url")
    cli = Mongoc.Client()
    @test cli.uri == "mongodb://localhost:27017"
    Mongoc.set_appname!(cli, "Runtests")
    db = Mongoc.DB(cli, DB_NAME)
    coll = Mongoc.Collection(cli, DB_NAME, "new_collection")
end

@testset "Connection" begin
    cli = Mongoc.Client()
    @test Mongoc.ping(cli) == "{ \"ok\" : 1.0 }"
    coll = Mongoc.Collection(cli, DB_NAME, "new_collection")
    bson_result = Mongoc.insert_one(coll, Mongoc.BSON("{ \"hello\" : \"world\" }"))
    @test Mongoc.as_json_string(bson_result) == "{ \"insertedCount\" : 1 }"

    bson_result = Mongoc.insert_one(coll, Mongoc.BSON("{ \"hey\" : \"you\" }"))
    @test Mongoc.as_json_string(bson_result) == "{ \"insertedCount\" : 1 }"

    i = 0
    for bson in Mongoc.find(coll)
        i += 1
    end
    @test i == length(coll)

    Mongoc.command_simple_as_json(coll, "{ \"collStats\" : \"new_collection\" }")
end
