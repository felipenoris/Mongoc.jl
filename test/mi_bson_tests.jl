import Mongoc

using Test

@testset "MI_BSON" begin
    @testset "roundtrip" begin
        y = 8
        doc = Mongoc.write_symbol(y)
        y_ret = Mongoc.load_symbol(doc)
        @test y == 8
        
        f = x->x*3
        doc = Mongoc.write_symbol(f)
        f_ret = Mongoc.load_symbol(doc)
        @test f_ret(3)==9
    end
end