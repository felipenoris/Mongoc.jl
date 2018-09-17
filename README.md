
# Mongoc.jl

[![License][license-img]](LICENSE)
[![travis][travis-img]][travis-url]
[![codecov][codecov-img]][codecov-url]
[![latest][docs-latest-img]][docs-latest-url]
[![stable][docs-stable-img]][docs-stable-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[travis-img]: https://img.shields.io/travis/felipenoris/Mongoc.jl/master.svg?label=Linux+/+macOS
[travis-url]: https://travis-ci.org/felipenoris/Mongoc.jl
[codecov-img]: https://img.shields.io/codecov/c/github/felipenoris/Mongoc.jl/master.svg?label=codecov
[codecov-url]: http://codecov.io/github/felipenoris/Mongoc.jl?branch=master
[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://felipenoris.github.io/Mongoc.jl/latest
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://felipenoris.github.io/Mongoc.jl/stable

MongoDB driver for the Julia Language.

This is a thin wrapper around [libmongoc](http://mongoc.org/), the official client library for C applications.

## Requirements

* MongoDB 3.0 or newer

* Julia versions v0.6, v0.7 or v1.0.

* Linux or OSX.

## MongoDB C Driver

This packages downloads precompiled binaries for [MongoDB C Driver v1.12.0](http://mongoc.org)
from [mongo-c-driver-builder](https://github.com/felipenoris/mongo-c-driver-builder).

The binaries are compiled by Travis CI, using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

Windows is currently not supported because the C driver requires Visual Studio to be compiled.

If your platform is not supported and can be compiled by
[BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl),
please open an [issue](https://github.com/felipenoris/Mongoc.jl/issues).

## Documentation

The documentation for this package is hosted at https://felipenoris.github.io/Mongoc.jl/latest/.

## Alternative Libraries

* [LibBSON.jl](https://github.com/ScottPJones/LibBSON.jl.git)

* [Mongo.jl](https://github.com/ScottPJones/Mongo.jl.git)
