
# Mongoc.jl

[![License][license-img]](LICENSE)
[![travis][travis-img]][travis-url]
[![appveyor][appveyor-img]][appveyor-url]
[![codecov][codecov-img]][codecov-url]
[![dev][docs-dev-img]][docs-dev-url]
[![stable][docs-stable-img]][docs-stable-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[travis-img]: https://img.shields.io/travis/felipenoris/Mongoc.jl/master.svg?logo=travis&label=Linux+/+macOS&style=flat-square
[travis-url]: https://travis-ci.org/felipenoris/Mongoc.jl
[appveyor-img]: https://img.shields.io/appveyor/ci/felipenoris/mongoc-jl/master.svg?logo=appveyor&label=Windows&style=flat-square
[appveyor-url]: https://ci.appveyor.com/project/felipenoris/mongoc-jl/branch/master
[codecov-img]: https://img.shields.io/codecov/c/github/felipenoris/Mongoc.jl/master.svg?label=codecov&style=flat-square
[codecov-url]: http://codecov.io/github/felipenoris/Mongoc.jl?branch=master
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg?style=flat-square
[docs-dev-url]: https://felipenoris.github.io/Mongoc.jl/dev
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square
[docs-stable-url]: https://felipenoris.github.io/Mongoc.jl/stable

**Mongoc.jl** is a [MongoDB](https://www.mongodb.com/) driver for the Julia Language.

It is implemented as a thin wrapper around [libmongoc](http://mongoc.org/), the official client library for C applications.

Given that [BSON](http://bsonspec.org/) is the document format for MongoDB,
this package also implements a wrapper around [libbson](http://mongoc.org/libbson/current/index.html),
which provides a way to create and manipulate BSON documents.

## Requirements

* MongoDB 3.0 or newer.

* Julia v1.0 or newer.

* Linux, macOS

* Windows (experimental).

## Windows Support

This package is known to work on Windows 7 and Windows Server.
For Windows 10, however, dependencies may fail to install.
See [#44](https://github.com/felipenoris/Mongoc.jl/issues/44).

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

## Documentation

The documentation for this package is hosted at https://felipenoris.github.io/Mongoc.jl/stable.

## License

The source code for the package `Mongoc.jl` is licensed under the [MIT License](https://github.com/felipenoris/Mongoc.jl/blob/master/LICENSE).

This repository distributes binary assets built from [mongo-c-driver](https://github.com/mongodb/mongo-c-driver) source code,
which is licensed under [Apache-2.0](https://github.com/mongodb/mongo-c-driver/blob/master/COPYING).

## Alternative Libraries

* [LibBSON.jl](https://github.com/ScottPJones/LibBSON.jl.git)

* [Mongo.jl](https://github.com/ScottPJones/Mongo.jl.git)
