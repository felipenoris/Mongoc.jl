
__precompile__(true)
module Mongoc

@static if VERSION < v"0.7-"
    const Nothing = Void
    const Cvoid   = Void
    Base.replace(s::AbstractString, pair::Pair) = replace(s, pair[1], pair[2])
end

# load libmongoc
const libmongocpath = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(libmongocpath)
    error("Mongoc.jl is not installed properly, run Pkg.build(\"Mongoc\") and restart Julia.")
end
include(libmongocpath)

include("compat.jl")
include("types.jl")
include("c_api.jl")
include("api.jl")

function __init__()
    check_deps()
    mongoc_init()
end

atexit() do
    @static if VERSION < v"0.7-"
        gc()
    else
        GC.gc()
    end
end

end # module Mongoc
