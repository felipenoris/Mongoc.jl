
module Mongoc

using Dates

# load libmongoc
const libmongocpath = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(libmongocpath)
    error("Mongoc.jl is not installed properly, run Pkg.build(\"Mongoc\") and restart Julia.")
end
include(libmongocpath)

# utility functions for date conversion
const ISODATE_OFFSET = Dates.UNIXEPOCH + 31536000000 # offsets an additional year from UNIXEPOCH. Number of millis in a year: 24 * 60 * 60 * 1000 * 365
isodate2datetime(millis::Int64) = Dates.epochms2datetime(millis + ISODATE_OFFSET)
datetime2isodate(dt::DateTime) = Dates.datetime2epochms(dt) - ISODATE_OFFSET

include("bson.jl")
include("types.jl")
include("c_api.jl")
include("api.jl")
include("session.jl")

function __init__()
    check_deps()
    mongoc_init()
end

end # module Mongoc
