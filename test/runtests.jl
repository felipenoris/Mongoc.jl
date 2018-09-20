
#
# Tests depend on a running server at localhost:27017,
# and will create a database named "mongoc_tests".
#

import Mongoc

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
    using Dates
end

const DB_NAME = "mongoc"

#=
function gc_on_osx_v6()
    @static if VERSION < v"0.7-" && is_apple()
            gc()
    else
        nothing
    end
end
=#

@testset "BSON" begin

    @testset "as_json" begin
        @test_throws ErrorException Mongoc.BSON(""" { ajskdla sdjsafd } """)
        bson = Mongoc.BSON("""{"hey" : 1}""")
        @test bson["hey"] == 1
        @test Mongoc.as_json(bson) == """{ "hey" : 1 }"""
        @test Mongoc.as_json(bson, canonical=true) == """{ "hey" : { "\$numberInt" : "1" } }"""
    end

    @testset "oid conversion" begin
        local oid::Mongoc.BSONObjectId = "5b9fb22b3192e3fa155693a1"
        local oid_str::String = oid
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

    @testset "oid string" begin
        x = Mongoc.BSONObjectId()
        y = Mongoc.BSONObjectId(string(x))
        @test x == y

        @test_throws ErrorException Mongoc.BSONObjectId("invalid_objectid")
    end

    @testset "oid time" begin
        Mongoc.get_time( Mongoc.BSONObjectId("5b9eaa2711c3dd0d6a46a5c4") ) == DateTime(2018, 9, 16, 19, 8, 23) # 2018-09-16T19:08:23
    end

    # https://github.com/JuliaLang/julia/issues/29193
    #=
    if VERSION < v"0.7-"
        @testset "BSONObjectId segfault issue" begin
            io = IOBuffer()
            v = Vector{Mongoc.BSONObjectId}()

            for i in 1:5
                push!(v, Mongoc.BSONObjectId())
            end
            show(io, v)
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
    =#

    @testset "BSON Iterator" begin
        doc = Mongoc.BSON("""{ "a" : 1, "b" : 2.2, "str" : "my string", "bool_t" : true, "bool_f" : false, "array" : [1, 2, false, "inner_string"], "document" : { "a" : 1, "b" : "b_string"}  }""")

        new_id = Mongoc.BSONObjectId()
        doc["_id"] = new_id

        @test haskey(doc, "a")
        @test haskey(doc, "b")
        @test !haskey(doc, "c")
        @test haskey(doc, "str")
        @test haskey(doc, "_id")
        @test haskey(doc, "array")
        @test haskey(doc, "document")

        @test doc["a"] == 1
        @test doc["b"] == 2.2
        @test doc["str"] == "my string"
        @test doc["bool_t"]
        @test !doc["bool_f"]
        @test doc["_id"] == new_id
        @test doc["array"] == [1, 2, false, "inner_string"]
        @test doc["document"] == Dict("a"=>1, "b"=>"b_string")

        @test_throws ErrorException doc["invalid key"]

        doc_dict = Mongoc.as_dict(doc)
        @test doc_dict["a"] == 1
        @test doc_dict["b"] == 2.2
        @test doc_dict["str"] == "my string"
        @test doc_dict["bool_t"]
        @test !doc_dict["bool_f"]
        @test doc_dict["_id"] == new_id
        @test doc_dict["array"] == [1, 2, false, "inner_string"]
        @test doc_dict["document"] == Dict("a"=>1, "b"=>"b_string")
    end

    @testset "BSON write" begin
        bson = Mongoc.BSON()
        new_oid = Mongoc.BSONObjectId()
        bson["_id"] = new_oid
        bson["int32"] = Int32(10)
        bson["int64"] = Int64(20)
        bson["string"] = "hey you"
        bson["bool_true"] = true
        bson["bool_false"] = false
        bson["double"] = 2.3
        bson["datetime"] = DateTime(2018, 2, 1, 10, 20, 35, 10)
        bson["vector"] = collect(1:10)
        bson["source"] = Mongoc.BSONCode("function() = 1")
        @test_throws ErrorException bson["key"] = Date(2018, 9, 18)

        let
            sub_bson = Mongoc.BSON()
            sub_bson["hey"] = "you"
            sub_bson["num"] = 10
            bson["sub_document"] = sub_bson
        end

        @test bson["_id"] == new_oid
        @test bson["int32"] == Int32(10)
        @test bson["int64"] == Int64(20)
        @test bson["string"] == "hey you"
        @test bson["bool_true"]
        @test !bson["bool_false"]
        @test bson["double"] == 2.3
        @test bson["datetime"] == DateTime(2018, 2, 1, 10, 20, 35, 10)
        @test bson["sub_document"]["hey"] == "you"
        @test bson["sub_document"]["num"] == 10
        @test bson["vector"] == collect(1:10)
        @test bson["source"] == Mongoc.BSONCode("function() = 1")

        let
            sub_bson = bson["sub_document"]
            @test sub_bson["hey"] == "you"
            @test sub_bson["num"] == 10
        end
    end

    @testset "BSON to Dict conversion" begin
        dict = Dict("a" => 1, "b" => false, "c" => "string")
        doc = Mongoc.BSON(dict)
        @test doc["a"] == 1
        @test doc["b"] == false
        @test doc["c"] == "string"
        @test dict == Mongoc.as_dict(doc)
    end
end

@testset "MongoDB" begin

    client = Mongoc.Client()

    @testset "Types" begin
        bson = Mongoc.BSON()
        @test_throws ErrorException Mongoc.Client("////invalid-url")
        @test client.uri == "mongodb://localhost:27017"
        Mongoc.set_appname!(client, "Runtests")
        db = client[DB_NAME]
        coll = db["new_collection"]

        io = IOBuffer()
        show(io, bson)
        show(io, client)
        show(io, db)
        show(io, coll)
        show(io, Mongoc.BSONCode("function() = 1"))
        show(io, Mongoc.QUERY_FLAG_TAILABLE_CURSOR)
    end

    @testset "Connection" begin

        @testset "ping" begin
            bson_ping_result = Mongoc.ping(client)
            @test haskey(bson_ping_result, "ok")
            @test Mongoc.as_json(Mongoc.ping(client)) == """{ "ok" : 1.0 }"""
        end

        @testset "Server Status" begin
            bson_server_status = Mongoc.command_simple(client["admin"], Mongoc.BSON("""{ "serverStatus" : 1 }"""))
            println("Server Mongo Version: ", bson_server_status["version"])
        end

        @testset "error print" begin
            error_happened = false
            try
                Mongoc.command_simple(client["hey"], Mongoc.BSON("""{ "you" : 1 }"""))
            catch e
                println(IOBuffer(), e)
                error_happened = true
            end

            @test error_happened
        end

        @testset "new_collection" begin
            coll = client[DB_NAME]["new_collection"]
            result = push!(coll, Mongoc.BSON("""{ "hello" : "world" }"""))
            @test Mongoc.as_json(result.reply) == """{ "insertedCount" : 1 }"""
            result = push!(coll, Mongoc.BSON("""{ "hey" : "you" }"""))
            @test Mongoc.as_json(result.reply) == """{ "insertedCount" : 1 }"""

            bson = Mongoc.BSON()
            bson["hey"] = "you"

            bson["zero_date"] = DateTime(0)
            bson["date_2018"] = DateTime(2018)

            result = push!(coll, bson)
            @test Mongoc.as_json(result.reply) == """{ "insertedCount" : 1 }"""

            i = 0
            for bson in Mongoc.find(coll)
                @test haskey(bson, "hello") || haskey(bson, "hey")
                i += 1
            end
            @test i == length(coll)

            i = 0
            for bson in Mongoc.find(coll, Mongoc.BSON("""{ "hello" : "world" }"""))
                i += 1
            end
            @test i == 1

            Mongoc.command_simple(coll, Mongoc.BSON("""{ "collStats" : "new_collection" }"""))
            empty!(coll)
        end

        #gc_on_osx_v6() # avoid segfault on Cursor destroy

        @testset "find_databases" begin
            found = false
            for obj in Mongoc.find_databases(client)
                if obj["name"] == "mongoc_tests"
                    found = true
                end
            end
            @test found

            @test "mongoc_tests" ∈ Mongoc.get_database_names(client)
        end

        @testset "find_collections" begin
            for obj in Mongoc.find_collections(client["local"])
                @test obj["name"] == "startup_log"
            end

            @test Mongoc.get_collection_names(client["local"]) == [ "startup_log" ]
        end

        @testset "BulkOperation" begin
            coll = client[DB_NAME]["new_collection"]
            bulk_operation = Mongoc.BulkOperation(coll)
            Mongoc.destroy!(bulk_operation)
            bulk_2 = Mongoc.BulkOperation(coll) # will be freed by GC
        end

        @testset "insert_many" begin
            collection = client[DB_NAME]["insert_many"]
            vector = Vector{Mongoc.BSON}()
            push!(vector, Mongoc.BSON("""{ "hey" : "you" }"""))
            push!(vector, Mongoc.BSON("""{ "out" : "there" }"""))
            push!(vector, Mongoc.BSON("""{ "count" : 3 }"""))

            append!(collection, vector)
            @test length(collection) == 3
            @test length(collect(collection)) == 3

            empty!(collection)
            @test isempty(collection)
        end

        @testset "delete_one" begin
            collection = client[DB_NAME]["delete_one"]
            doc = Mongoc.BSON("""{ "to" : "delete", "hey" : "you" }""")
            doc2 = Mongoc.BSON("""{ "to" : "keep", "out" : "there" }""")
            insert_result = push!(collection, doc)
            oid = Mongoc.BSONObjectId(insert_result.inserted_oid)
            push!(collection, doc2)

            selector = Mongoc.BSON()
            selector["_id"] = oid
            @test length(collection, selector) == 1
            result = Mongoc.delete_one(collection, selector)
            @test result["deletedCount"] == 1
            @test length(collection, selector) == 0

            empty!(collection)
        end

        @testset "delete_many" begin
            collection = client[DB_NAME]["delete_many"]
            append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
            @test length(collection) == 3
            result = Mongoc.delete_many(collection, Mongoc.BSON("""{ "delete" : true }"""))
            @test result["deletedCount"] == 2
            @test length(collection) == 1
            result = Mongoc.delete_many(collection, Mongoc.BSON())
            @test result["deletedCount"] == 1
            @test isempty(collection)
        end

        @testset "update_one, update_many" begin
            collection = client[DB_NAME]["update_one"]
            append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
            @test length(collection) == 3

            selector = Mongoc.BSON("""{ "delete" : false }""")
            update = Mongoc.BSON("""{ "\$set" : { "delete" : true, "new_field" : 1 } }""")
            result = Mongoc.update_one(collection, selector, update)

            @test result["modifiedCount"] == 1
            @test result["matchedCount"] == 1
            @test result["upsertedCount"] == 0

            updated_bson = Mongoc.find_one(collection, Mongoc.BSON("""{ "third" : 3 }"""))
            @test updated_bson != nothing
            @test updated_bson["delete"] == true
            @test updated_bson["new_field"] == 1

            selector = Mongoc.BSON("""{ "delete" : true }""")
            update = Mongoc.BSON("""{ "\$set" : { "delete" : false } }""")
            result = Mongoc.update_many(collection, selector, update)
            @test result["modifiedCount"] == 3
            @test result["matchedCount"] == 3
            @test result["upsertedCount"] == 0

            for doc in Mongoc.find(collection)
                @test doc["delete"] == false
            end

            @test Mongoc.find_one(collection, Mongoc.BSON("""{ "delete" : true }""")) == nothing

            empty!(collection)
        end

        @testset "aggregation, map_reduce" begin
            # reproducing the examples at https://docs.mongodb.com/manual/aggregation/
            docs = [
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
            ]

            database = client[DB_NAME]
            collection = database["aggregation_example"]
            append!(collection, docs)
            @test length(collection) == 4

            # Aggregation
            let
                bson_pipeline = Mongoc.BSON("""
                    [
                        { "\$match" : { "status" : "A" } },
                        { "\$group" : { "_id" : "\$cust_id", "total" : { "\$sum" : "\$amount" } } }
                    ]""")

                # Response should be
                #   BSON("{ "_id" : "B212", "total" : 200 }")
                #   BSON("{ "_id" : "A123", "total" : 750 }")
                for doc in Mongoc.aggregate(collection, bson_pipeline)
                    if doc["_id"] == "A123"
                        @test doc["total"] == 750
                    elseif doc["_id"] == "B212"
                        @test doc["total"] == 200
                    else
                        # shouldn't get in here
                        @test false
                    end
                end
            end

            # map_reduce
            let
                input_collection_name = "aggregation_example"
                mapper = Mongoc.BSONCode(""" function() { emit( this.cust_id, this.amount ); } """)
                reducer = Mongoc.BSONCode(""" function(key, values) { return Array.sum( values ) } """)
                output_collection_name = "order_totals"
                query = Mongoc.BSON("""{ "status" : "A" }""")

                map_reduce_command = Mongoc.BSON()
                map_reduce_command["mapReduce"] = input_collection_name
                map_reduce_command["map"] = mapper
                map_reduce_command["reduce"] = reducer
                map_reduce_command["out"] = output_collection_name
                map_reduce_command["query"] = query

                result = Mongoc.command_simple(database, map_reduce_command)
                @test result["result"] == "order_totals"
                @test result["ok"] == 1.0

                for doc in Mongoc.find(database["order_totals"])
                   if doc["_id"] == "A123"
                        @test doc["value"] == 750
                    elseif doc["_id"] == "B212"
                        @test doc["value"] == 200
                    else
                        # shouldn't get in here
                        @test false
                    end
                end

               # Response should be
               # BSON("{ "_id" : "A123", "value" : 750.0 }")
               # BSON("{ "_id" : "B212", "value" : 200.0 }")
            end

            empty!(collection)
        end

        #gc_on_osx_v6() # avoid segfault on Cursor destroy
    end

    @testset "Users" begin
        # creates admin user - https://docs.mongodb.com/manual/tutorial/enable-authentication/
        @test Mongoc.has_database(client, DB_NAME) # at this point, DB_NAME should exist
        database = client[DB_NAME]

        user_name = "myUser"
        pass = "abc123"
        roles = Mongoc.BSON()

        if Mongoc.has_user(database, user_name)
            Mongoc.remove_user(database, user_name)
        end

        Mongoc.add_user(database, user_name, pass, roles)
        Mongoc.remove_user(database, user_name)
        @test !Mongoc.has_user(database, user_name)
    end

    #gc_on_osx_v6()

    @testset "Session Options" begin
        opt = Mongoc.SessionOptions()
        @test Mongoc.get_casual_consistency(opt)
        Mongoc.set_casual_consistency!(opt, false)
        @test !Mongoc.get_casual_consistency(opt)
    end

    server_version = Mongoc.get_server_mongodb_version(client)

    if server_version < v"3.6"
        @static if VERSION < v"0.7"
            warn("MongoDB server version $server_version does not support Sessions. Skipping tests.")
        else
            @warn("MongoDB server version $server_version does not support Sessions. Skipping tests.")
        end
    else
        @testset "Session" begin
            session = Mongoc.Session(client)
            db = session[DB_NAME]
            collection = db["session_collection"]
            push!(collection, Mongoc.BSON("""{ "try-insert" : 1 }"""))
            empty!(collection)
        end
    end
end
