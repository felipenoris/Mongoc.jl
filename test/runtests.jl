
#using BinaryProvider
#@info("Testing for platform: ", platform_key_abi())

include("bson_tests.jl")
include("mongodb_tests.jl")
include("mi_bson_tests.jl")