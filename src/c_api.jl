
#=
https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/

Passing Pointers for Modifying Inputs
Because C doesn't support multiple return values, often C functions will take pointers to data that the function will modify. To accomplish this within a ccall, you need to first encapsulate the value inside a Ref{T} of the appropriate type. When you pass this Ref object as an argument, Julia will automatically pass a C pointer to the encapsulated data:

width = Ref{Cint}(0)
range = Ref{Cfloat}(0)
ccall(:foo, Cvoid, (Ref{Cint}, Ref{Cfloat}), width, range)
Upon return, the contents of width and range can be retrieved (if they were changed by foo) by width[] and range[]; that is, they act like zero-dimensional arrays.
=#

#
# libbson
#

function bson_new_from_json(data::String, len::Int=-1)
    ccall((:bson_new_from_json, libbson), Ptr{Cvoid}, (Ptr{UInt8}, Cssize_t, Ptr{Cvoid}), data, len, C_NULL)
end

function bson_destroy(bson_handle::Ptr{Cvoid})
    ccall((:bson_destroy, libbson), Cvoid, (Ptr{Cvoid},), bson_handle)
end

function bson_as_canonical_extended_json(bson_handle::Ptr{Cvoid})
    ccall((:bson_as_canonical_extended_json, libbson), Cstring, (Ptr{Cvoid}, Ptr{Cvoid}), bson_handle, C_NULL)
end

function bson_as_relaxed_extended_json(bson_handle::Ptr{Cvoid})
    ccall((:bson_as_relaxed_extended_json, libbson), Cstring, (Ptr{Cvoid}, Ptr{Cvoid}), bson_handle, C_NULL)
end

function bson_copy(bson_document::Ptr{Cvoid}) # (const bson_t *bson)
    ccall((:bson_copy, libbson), Ptr{Cvoid}, (Ptr{Cvoid},), bson_document)
end

#
# libmongoc
#

function mongoc_init()
    ccall((:mongoc_init, libmongoc), Cvoid, ())
end

function mongoc_uri_new_with_error(uri_string::String, bson_error::BSONError)
    ccall((:mongoc_uri_new_with_error, libmongoc), Ptr{Cvoid}, (Cstring, Ref{BSONError}), uri_string, Ref{BSONError}(bson_error))
end

function mongoc_uri_destroy(uri_handle::Ptr{Cvoid})
    ccall((:mongoc_uri_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), uri_handle)
end

function mongoc_client_new_from_uri(uri_handle::Ptr{Cvoid})
    ccall((:mongoc_client_new_from_uri, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid},), uri_handle)
end

function mongoc_client_destroy(client_handle::Ptr{Cvoid})
    ccall((:mongoc_client_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), client_handle)
end

function mongoc_client_set_appname(client_handle::Ptr{Cvoid}, appname::String)
    ccall((:mongoc_client_set_appname, libmongoc), Bool, (Ptr{Cvoid}, Cstring), client_handle, appname)
end

function mongoc_client_get_database(client_handle::Ptr{Cvoid}, db_name::String)
    ccall((:mongoc_client_get_database, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), client_handle, db_name)
end

function mongoc_database_destroy(database_handle::Ptr{Cvoid})
    ccall((:mongoc_database_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), database_handle)
end

function mongoc_client_command_simple(client_handle::Ptr{Cvoid}, db_name::String, bson_command::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_client_command_simple, libmongoc), Bool, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), client_handle, db_name, bson_command, read_prefs, bson_reply, Ref{BSONError}(bson_error))
end

function mongoc_client_get_collection(client_handle::Ptr{Cvoid}, db_name::String, coll_name::String)
    ccall((:mongoc_client_get_collection, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cstring), client_handle, db_name, coll_name)
end

function mongoc_collection_command_simple(collection_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_command_simple, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_command, read_prefs, bson_reply, Ref{BSONError}(bson_error))
end

function mongoc_collection_destroy(collection_handle::Ptr{Cvoid})
    ccall((:mongoc_collection_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), collection_handle)
end

function mongoc_collection_insert_one(collection_handle::Ptr{Cvoid}, bson_document::Ptr{Cvoid}, bson_options::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_insert_one, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_document, bson_options, bson_reply, Ref{BSONError}(bson_error))
end

function mongoc_collection_find_with_opts(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid})
    ccall((:mongoc_collection_find_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), collection_handle, bson_filter, bson_opts, read_prefs)
end

function mongoc_cursor_destroy(cursor_handle::Ptr{Cvoid})
    ccall((:mongoc_cursor_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), cursor_handle)
end

function mongoc_cursor_next(cursor_handle::Ptr{Cvoid}, bson_document_ref::Ref{Ptr{Cvoid}})
    ccall((:mongoc_cursor_next, libmongoc), Bool, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}), cursor_handle, bson_document_ref)
end

function mongoc_collection_count_documents(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_count_documents, libmongoc), Int64, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_filter, bson_opts, read_prefs, bson_reply, Ref{BSONError}(bson_error))
end
