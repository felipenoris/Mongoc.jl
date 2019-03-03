
import Mongoc

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
    using Dates
end

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

    @testset "BSONObjectId segfault issue (#2)" begin
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

    @testset "BSON Iterator" begin
        doc = Mongoc.BSON("""{ "a" : 1, "b" : 2.2, "str" : "my string", "bool_t" : true, "bool_f" : false, "array" : [1, 2, false, "inner_string"], "document" : { "a" : 1, "b" : "b_string"}, "null" : null  }""")

        new_id = Mongoc.BSONObjectId()
        doc["_id"] = new_id

        @test haskey(doc, "a")
        @test haskey(doc, "b")
        @test !haskey(doc, "c")
        @test haskey(doc, "str")
        @test haskey(doc, "_id")
        @test haskey(doc, "array")
        @test haskey(doc, "document")
        @test haskey(doc, "null")

        @test doc["a"] == 1
        @test doc["b"] == 2.2
        @test doc["str"] == "my string"
        @test doc["bool_t"]
        @test !doc["bool_f"]
        @test doc["_id"] == new_id
        @test doc["array"] == [1, 2, false, "inner_string"]
        @test doc["document"] == Dict("a"=>1, "b"=>"b_string")
        @test doc["null"] == nothing

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
        @test doc_dict["null"] == nothing
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
        bson["null"] = nothing
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
        @test bson["null"] == nothing

        let
            sub_bson = bson["sub_document"]
            @test sub_bson["hey"] == "you"
            @test sub_bson["num"] == 10
        end
    end

    @testset "BSON to Dict conversion" begin
        dict = Dict("a" => 1, "b" => false, "c" => "string", "d" => nothing)
        doc = Mongoc.BSON(dict)
        @test doc["a"] == 1
        @test doc["b"] == false
        @test doc["c"] == "string"
        @test doc["d"] == nothing
        @test dict == Mongoc.as_dict(doc)
    end
end
