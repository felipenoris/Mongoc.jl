
using Documenter, Mongoc

makedocs(
    format = :html,
    sitename = "Mongoc.jl",
    modules = [ Mongoc ],
    pages = [ "index.md", "tutorial.md", "api.md" ]
)

deploydocs(
    repo = "github.com/felipenoris/Mongoc.jl.git",
    target = "build",
    julia  = "1.0",
    deps   = nothing,
    make   = nothing
)
