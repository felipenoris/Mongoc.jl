
#
# Types
#

"BSONType mirrors C enum bson_type_t."
primitive type BSONType 8 end

Base.convert(::Type{T}, t::BSONType) where {T<:Number} = reinterpret(UInt8, t)
Base.convert(::Type{BSONType}, n::T) where {T<:Number} = reinterpret(BSONType, n)
BSONType(u::UInt8) = convert(BSONType, u)

#
# Constants for BSONType
#

const BSON_TYPE_EOD        = BSONType(0x00)
const BSON_TYPE_DOUBLE     = BSONType(0x01)
const BSON_TYPE_UTF8       = BSONType(0x02)
const BSON_TYPE_DOCUMENT   = BSONType(0x03)
const BSON_TYPE_ARRAY      = BSONType(0x04)
const BSON_TYPE_BINARY     = BSONType(0x05)
const BSON_TYPE_UNDEFINED  = BSONType(0x06)
const BSON_TYPE_OID        = BSONType(0x07)
const BSON_TYPE_BOOL       = BSONType(0x08)
const BSON_TYPE_DATE_TIME  = BSONType(0x09)
const BSON_TYPE_NULL       = BSONType(0x0A)
const BSON_TYPE_REGEX      = BSONType(0x0B)
const BSON_TYPE_DBPOINTER  = BSONType(0x0C)
const BSON_TYPE_CODE       = BSONType(0x0D)
const BSON_TYPE_SYMBOL     = BSONType(0x0E)
const BSON_TYPE_CODEWSCOPE = BSONType(0x0F)
const BSON_TYPE_INT32      = BSONType(0x10)
const BSON_TYPE_TIMESTAMP  = BSONType(0x11)
const BSON_TYPE_INT64      = BSONType(0x12)
const BSON_TYPE_DECIMAL128 = BSONType(0x13)
const BSON_TYPE_MAXKEY     = BSONType(0x7F)
const BSON_TYPE_MINKEY     = BSONType(0xFF)



"BSONSubType mirrors C enum bson_subtype_t."
primitive type BSONSubType 8 end

Base.convert(::Type{T}, t::BSONSubType) where {T<:Number} = reinterpret(UInt8, t)
Base.convert(::Type{BSONSubType}, n::T) where {T<:Number} = reinterpret(BSONSubType, n)
BSONType(u::UInt8) = convert(BSONSubType, u)

#
# Constants for BSONSubType
#

const BSON_SUBTYPE_BINARY            = BSONSubType(0x00)
const BSON_SUBTYPE_FUNCTION          = BSONSubType(0x01)
const BSON_SUBTYPE_BINARY_DEPRECATED = BSONSubType(0x02)
const BSON_SUBTYPE_UUID_DEPRECATED   = BSONSubType(0x03)
const BSON_SUBTYPE_UUID              = BSONSubType(0x04)
const BSON_SUBTYPE_MD5               = BSONSubType(0x05)
const BSON_SUBTYPE_USER              = BSONSubType(0x80)



"""
BSONIter mirrors C struct bson_iter_t and can be allocated in the stack.

According to [libbson documentation](http://mongoc.org/libbson/current/bson_iter_t.html),
it is meant to be used on the stack and can be discarded at any time
as it contains no external allocation.
The contents of the structure should be considered private
and may change between releases, however the structure size will not change.

Inspecting its size in C, we get:

```c
sizeof(bson_iter_t) == 80
```
"""
primitive type BSONIter 80 * 8 end # 80 bytes

"""
Mirrors C struct `bson_oid_t`.

`BSONObjectId` instances addresses are passed
to libbson/libmongoc API using `Ref(oid)`,
and are owned by the Julia process.

```c
typedef struct {
   uint8_t bytes[12];
} bson_oid_t;
```
"""
primitive type BSONObjectId 12 * 8 end # 12 bytes

function BSONObjectId()
    oid_ref = Ref{BSONObjectId}()
    bson_oid_init(oid_ref, C_NULL)
    return oid_ref[]
end

function BSONObjectId(oid_string::String)
    if !bson_oid_is_valid(oid_string)
        error("'$oid_string' is not a valid ObjectId.")
    end
    oid_ref = Ref{BSONObjectId}()
    bson_oid_init_from_string(oid_ref, oid_string)
    return oid_ref[]
end

"""
Mirrors C struct `bson_error_t` and can be allocated in the stack.

`BSONError` instances addresses are passed
to libbson/libmongoc API using `Ref(error)`,
and are owned by the Julia process.

```c
typedef struct {
   uint32_t domain;
   uint32_t code;
   char message[504];
} bson_error_t;
```
"""
mutable struct BSONError
    domain::UInt32
    code::UInt32
    message::NTuple{504, UInt8}

    BSONError() = new(0, 0, tuple(zeros(UInt8, 504)...))
end

"BSON element with JavaScript source code."
struct BSONCode
    code::String
end

"`BSON` is a wrapper for C struct `bson_t`."
mutable struct BSON
    handle::Ptr{Cvoid}

    function BSON(handle::Ptr{Cvoid})
        new_bson = new(handle)
        @compat finalizer(destroy!, new_bson)
        return new_bson
    end
end

function destroy!(bson::BSON)
    if bson.handle != C_NULL
        bson_destroy(bson.handle)
        bson.handle = C_NULL
    end
    nothing
end

function Base.deepcopy(bson::BSON) :: BSON
    return BSON(bson_copy(bson.handle))
end

#
# API
#

Base.convert(::Type{String}, oid::BSONObjectId) = bson_oid_to_string(oid)
Base.string(oid::BSONObjectId) = convert(String, oid)
Base.convert(::Type{BSONObjectId}, oid_string::String) = BSONObjectId(oid_string)

Base.convert(::Type{String}, code::BSONCode) = code.code
Base.string(code::BSONCode) = convert(String, code)
Base.convert(::Type{BSONCode}, code_string::String) = BSONCode(code_string)

@static if VERSION < v"0.7-"
    Base.:(==)(c1::BSONCode, c2::BSONCode) = c1.code == c2.code
end

Base.show(io::IO, oid::BSONObjectId) = print(io, "BSONObjectId(\"", string(oid), "\")")
Base.show(io::IO, bson::BSON) = print(io, "BSON(\"", as_json(bson), "\")")
Base.show(io::IO, code::BSONCode) = print(io::IO, "BSONCode(\"$(code.code)\")")

function Base.show(io::IO, err::BSONError)
    for c in err.message
        c_char = Char(c)
        if c_char == '\0'
            break
        else
            print(io, c_char)
        end
    end
end

function get_time(oid::BSONObjectId)
    return Dates.unix2datetime(bson_oid_get_time_t(oid))
end

function BSON()
    handle = bson_new()
    if handle == C_NULL
        error("Failed to create a new BSON document.")
    end
    return BSON(handle)
end

function BSON(json_string::String)
    handle = bson_new_from_json(json_string)
    if handle == C_NULL
        error("Failed parsing JSON to BSON. $json_string.")
    end
    return BSON(handle)
end


function BSON(dict::Dict)
    result = BSON()

    for (k, v) in pairs(dict)
        result[k] = v
    end

    return result
end

function BSON(vector::Vector)
    result = BSON()

    for (i, v) in enumerate(vector)
        result[string(i-1)] = v
    end

    return result
end

"""
    as_json(bson::BSON; canonical::Bool=false) :: String

Converts a `bson` object to a JSON string.

# Example

```julia
julia> document = Mongoc.BSON("{ \"hey\" : 1 }")
BSON("{ "hey" : 1 }")

julia> Mongoc.as_json(document)
"{ \"hey\" : 1 }"

julia> Mongoc.as_json(document, canonical=true)
"{ \"hey\" : { \"\$numberInt\" : \"1\" } }"
```

# C API

* [`bson_as_canonical_extended_json`](http://mongoc.org/libbson/current/bson_as_canonical_extended_json.html)

* [`bson_as_relaxed_extended_json`](http://mongoc.org/libbson/current/bson_as_relaxed_extended_json.html)

"""
function as_json(bson::BSON; canonical::Bool=false) :: String
    cstring = canonical ? bson_as_canonical_extended_json(bson.handle) : bson_as_relaxed_extended_json(bson.handle)
    if cstring == C_NULL
        error("Couldn't convert bson to json.")
    end
    result = unsafe_string(cstring)

    @static if VERSION < v"0.7-"
        bson_free(convert(Ptr{Cvoid}, convert(Ptr{UInt8}, cstring)))
    else
        bson_free(convert(Ptr{Cvoid}, cstring))
    end

    return result
end

#
# Read values from BSON
#

has_field(bson::BSON, key::String) = bson_has_field(bson.handle, key)
Base.haskey(bson::BSON, key::String) = has_field(bson, key)

function bson_iter_init(document::BSON) :: Ref{BSONIter}
    iter_ref = Ref{BSONIter}()
    ok = bson_iter_init(iter_ref, document.handle)
    if !ok
        error("Couldn't create iterator for BSON document.")
    end
    return iter_ref
end

function as_dict(document::BSON)
    iter_ref = bson_iter_init(document)
    return as_dict(iter_ref)
end

function as_dict(iter_ref::Ref{BSONIter})
    result = Dict()
    while bson_iter_next(iter_ref)
        result[unsafe_string(bson_iter_key(iter_ref))] = get_value(iter_ref)
    end
    return result
end

# function get_value(::BSON_TYPE_UTF8, iter_ref::Ref{BSONIter})
#
# end

function get_value(iter_ref::Ref{BSONIter})

    local bson_type::BSONType = bson_iter_type(iter_ref)

    if bson_type == BSON_TYPE_UTF8
        return unsafe_string(bson_iter_utf8(iter_ref))
    elseif bson_type == BSON_TYPE_INT64
        return bson_iter_int64(iter_ref)
    elseif bson_type == BSON_TYPE_INT32
        return bson_iter_int32(iter_ref)
    elseif bson_type == BSON_TYPE_DOUBLE
        return bson_iter_double(iter_ref)
    elseif bson_type == BSON_TYPE_OID
        return unsafe_load(bson_iter_oid(iter_ref)) # converts Ptr{BSONObjectId} to BSONObjectId
    elseif bson_type == BSON_TYPE_BOOL
        return bson_iter_bool(iter_ref)
    elseif bson_type == BSON_TYPE_DATE_TIME
        millis = Int64(bson_iter_date_time(iter_ref))
        return isodate2datetime(millis)

    elseif bson_type == BSON_TYPE_ARRAY || bson_type == BSON_TYPE_DOCUMENT

        child_iter_ref = Ref{BSONIter}()
        ok = bson_iter_recurse(iter_ref, child_iter_ref)
        if !ok
            error("Could't iterate array inside BSON.")
        end

        if bson_type == BSON_TYPE_ARRAY
            result_vector = Vector()
            while bson_iter_next(child_iter_ref)
                push!(result_vector, get_value(child_iter_ref))
            end
            return result_vector
        else
            @assert bson_type == BSON_TYPE_DOCUMENT
            return as_dict(child_iter_ref)
        end
    elseif bson_type == BSON_TYPE_CODE
        return BSONCode(unsafe_string(bson_iter_code(iter_ref)))
    else
        error("BSON Type not supported: $bson_type.")
    end
end

function Base.getindex(document::Mongoc.BSON, key::String)
    iter_ref = Ref{BSONIter}()
    ok = bson_iter_init_find(iter_ref, document.handle, key)
    if !ok
        error("Key $key not found.")
    end
    return get_value(iter_ref)
end

#
# Write values to BSON
#

function Base.setindex!(document::BSON, value::BSONObjectId, key::String)
    ok = bson_append_oid(document.handle, key, -1, value)
    if !ok
        error("Couldn't append oid to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::Int64, key::String)
    ok = bson_append_int64(document.handle, key, -1, value)
    if !ok
        error("Couldn't append Int64 to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::Int32, key::String)
    ok = bson_append_int32(document.handle, key, -1, value)
    if !ok
        error("Couldn't append Int32 to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::String, key::String)
    ok = bson_append_utf8(document.handle, key, -1, value, -1)
    if !ok
        error("Couldn't append String to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::Bool, key::String)
    ok = bson_append_bool(document.handle, key, -1, value)
    if !ok
        error("Couldn't append Bool to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::Float64, key::String)
    ok = bson_append_double(document.handle, key, -1, value)
    if !ok
        error("Couldn't append Float64 to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::DateTime, key::String)
    ok = bson_append_date_time(document.handle, key, -1, datetime2isodate(value))
    if !ok
        error("Couldn't append DateTime to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::BSON, key::String)
    ok = bson_append_document(document.handle, key, -1, value.handle)
    if !ok
        error("Couldn't append Sub-Document BSON to BSON document.")
    end
    nothing
end

Base.setindex!(document::BSON, value::Dict, key::String) = setindex!(document, BSON(value), key)


function Base.setindex!(document::BSON, value::Vector{T}, key::String) where T
    sub_document = BSON(value)
    ok = bson_append_array(document.handle, key, -1, sub_document.handle)
    if !ok
        error("Couldn't append array to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::BSONCode, key::String)
    ok = bson_append_code(document.handle, key, -1, value.code)
    if !ok
        error("Couldn't append String to BSON document.")
    end
    nothing
end

function Base.setindex!(document::BSON, value::Date, key::String)
    error("BSON format does not support `Date` type. Use `DateTime` instead.")
end

# Base.setindex!(::Mongoc.BSON, ::UInt8, ::String) # Binary:  MethodError: no method matching
function Base.setindex!(document::BSON, value::Vector{UInt8}, key::String)::Nothing
  # sub_document = BSON(value) # doesn't seem to be necessary, would need Base.setindex!(document::BSON, value::UInt8, key::String)::Bool
  ok = bson_append_binary(document.handle, key, -1, BSON_SUBTYPE_BINARY, value, UInt32(length(value)))
  if !ok
      error("Couldn't append array to BSON document.")
  end
  nothing
end
