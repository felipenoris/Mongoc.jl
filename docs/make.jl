
using Documenter, Mongoc

makedocs(
    format = :html,
    sitename = "Mongoc.jl",
    modules = [ Mongoc ],
    pages = [ "Home" => "index.md",
              "Tutorial" => "tutorial.md",
              "CRUD Operations" => "crud.md",
              "Authentication" => "authentication.md",
              "Transactions" => "transaction.md",
              "API Reference" => "api.md" ]
)

deploydocs(
    repo = "github.com/felipenoris/Mongoc.jl.git",
    target = "build",
    julia  = "1.0",
    deps   = nothing,
    make   = nothing
)
