
# Mongoc.jl

MongoDB driver for the Julia Language.

This is a thin wrapper around [libmongoc](http://mongoc.org/), the official client library for C applications.

## Requirements

* MongoDB 3.0 or newer

* On Linux x64: Julia v0.6, v0.7, v1.0.

* On Mac: Julia v0.7, v1.0.

## MongoDB C Driver

This packages downloads precompiled binaries for [MongoDB C Driver v1.12.0](http://mongoc.org)
from [mongo-c-driver-builder](https://github.com/felipenoris/mongo-c-driver-builder).

The binaries are compiled by Travis CI, using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

Windows is currently not supported because the C driver requires Visual Studio to be compiled.

If your platform is not supported and can be compiled by
[BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl),
please open an [issue](https://github.com/felipenoris/Mongoc.jl/issues).

## Instructions

The public API for this package is available at `api.jl` source file.

Check `tests/runtests.jl` for code examples.
