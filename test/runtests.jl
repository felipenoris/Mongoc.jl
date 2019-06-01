
#using BinaryProvider
#@info("Testing for platform: ", platform_key_abi())

include("bson_tests.jl")
include("mongodb_tests.jl")

if !Sys.iswindows()
	include("replica_set_tests.jl")
end
