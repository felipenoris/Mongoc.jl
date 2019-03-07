
# Mongoc.jl

## Introduction

**Mongoc.jl** is a [MongoDB](https://www.mongodb.com/) driver for the Julia Language.

It is implemented as a thin wrapper around [libmongoc](http://mongoc.org/), the official client library for C applications.

Given that [BSON](http://bsonspec.org/) is the document format for MongoDB,
this package also implements a wrapper around [libbson](http://mongoc.org/libbson/current/index.html),
which provides a way to create and manipulate BSON documents.

## Requirements

* MongoDB 3.0 or newer.

* Julia versions v0.7 or newer.

* Linux or macOS.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("Mongoc")
```

## MongoDB C Driver

This packages downloads precompiled binaries for [MongoDB C Driver](http://mongoc.org)
from [mongo-c-driver-builder](https://github.com/felipenoris/mongo-c-driver-builder).

The binaries are compiled by Travis CI, using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

Windows is currently not supported because the C driver requires Visual Studio to be compiled.

If your platform is not supported and can be compiled by
[BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl),
please open an [issue](https://github.com/felipenoris/Mongoc.jl/issues).

## Source Code

The source code for this package is hosted at
[https://github.com/felipenoris/Mongoc.jl](https://github.com/felipenoris/Mongoc.jl).

## License

The source code for the package **Mongoc.jl** is licensed under the [MIT License](https://github.com/felipenoris/Mongoc.jl/blob/master/LICENSE).

This repository distributes binary assets built from [mongo-c-driver](https://github.com/mongodb/mongo-c-driver) source code,
which is licensed under [Apache-2.0](https://github.com/mongodb/mongo-c-driver/blob/master/COPYING).

## References

* [libbson documentation](http://mongoc.org/libbson/current/index.html)

* [libmongoc documentation](http://mongoc.org/libmongoc/current/index.html)
