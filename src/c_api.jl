
#=
https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/
=#

#
# libbson
#

function bson_oid_init(oid::BSONObjectId, context::Ptr{Cvoid})
    ccall((:bson_oid_init, libbson), Cvoid, (Ref{BSONObjectId}, Ptr{Cvoid}), Ref(oid), context)
end

function bson_oid_to_string(oid::BSONObjectId)
    buffer_len = 25
    buffer = zeros(UInt8, buffer_len)
    ccall((:bson_oid_to_string, libbson), Cvoid, (Ref{BSONObjectId}, Ref{UInt8}), Ref(oid), Ref(buffer, 1))
    @assert buffer[end] == 0
    return String(buffer)
end

function bson_oid_compare(oid1::BSONObjectId, oid2::BSONObjectId)
    ccall((:bson_oid_compare, libbson), Cint, (Ref{BSONObjectId}, Ref{BSONObjectId}), Ref(oid1), Ref(oid2))
end

function bson_append_oid(bson_document::Ptr{Cvoid}, key::String, key_length::Int, oid::BSONObjectId)
    oid_copy = deepcopy(oid) # you get a segfault if you pass an oid to bson_append_oid and reuse it after bson_document is freed
    ccall((:bson_append_oid, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Ref{BSONObjectId}), bson_document, key, key_length, Ref(oid_copy))
end

function bson_new_from_json(data::String, len::Int=-1)
    ccall((:bson_new_from_json, libbson), Ptr{Cvoid}, (Ptr{UInt8}, Cssize_t, Ptr{Cvoid}), data, len, C_NULL)
end

function bson_destroy(bson_document::Ptr{Cvoid})
    ccall((:bson_destroy, libbson), Cvoid, (Ptr{Cvoid},), bson_document)
end

function bson_as_canonical_extended_json(bson_document::Ptr{Cvoid})
    ccall((:bson_as_canonical_extended_json, libbson), Cstring, (Ptr{Cvoid}, Ptr{Cvoid}), bson_document, C_NULL)
end

function bson_as_relaxed_extended_json(bson_document::Ptr{Cvoid})
    ccall((:bson_as_relaxed_extended_json, libbson), Cstring, (Ptr{Cvoid}, Ptr{Cvoid}), bson_document, C_NULL)
end

function bson_copy(bson_document::Ptr{Cvoid}) # (const bson_t *bson)
    ccall((:bson_copy, libbson), Ptr{Cvoid}, (Ptr{Cvoid},), bson_document)
end

function bson_has_field(bson_document::Ptr{Cvoid}, key::String)
    ccall((:bson_has_field, libbson), Bool, (Ptr{Cvoid}, Cstring), bson_document, key)
end

#
# libmongoc
#

function mongoc_init()
    ccall((:mongoc_init, libmongoc), Cvoid, ())
end

function mongoc_uri_new_with_error(uri_string::String, bson_error::BSONError)
    ccall((:mongoc_uri_new_with_error, libmongoc), Ptr{Cvoid}, (Cstring, Ref{BSONError}), uri_string, Ref(bson_error))
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

function mongoc_database_get_collection(database_handle::Ptr{Cvoid}, collection_name::String)
    ccall((:mongoc_database_get_collection, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), database_handle, collection_name)
end

function mongoc_client_command_simple(client_handle::Ptr{Cvoid}, db_name::String, bson_command::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_client_command_simple, libmongoc), Bool, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), client_handle, db_name, bson_command, read_prefs, bson_reply, Ref(bson_error))
end

#function mongoc_client_get_collection(client_handle::Ptr{Cvoid}, db_name::String, coll_name::String)
#    ccall((:mongoc_client_get_collection, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cstring), client_handle, db_name, coll_name)
#end

function mongoc_client_find_databases_with_opts(client_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_client_find_databases_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), client_handle, bson_opts)
end

function mongoc_collection_command_simple(collection_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_command_simple, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_command, read_prefs, bson_reply, Ref(bson_error))
end

function mongoc_collection_destroy(collection_handle::Ptr{Cvoid})
    ccall((:mongoc_collection_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), collection_handle)
end

function mongoc_collection_insert_one(collection_handle::Ptr{Cvoid}, bson_document::Ptr{Cvoid}, bson_options::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_insert_one, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_document, bson_options, bson_reply, Ref(bson_error))
end

function mongoc_collection_find_with_opts(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid})
    ccall((:mongoc_collection_find_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), collection_handle, bson_filter, bson_opts, read_prefs)
end

function mongoc_collection_count_documents(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_count_documents, libmongoc), Int64, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_filter, bson_opts, read_prefs, bson_reply, Ref(bson_error))
end

function mongoc_cursor_destroy(cursor_handle::Ptr{Cvoid})
    ccall((:mongoc_cursor_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), cursor_handle)
end

function mongoc_cursor_next(cursor_handle::Ptr{Cvoid}, bson_document_ref::Ref{Ptr{Cvoid}})
    ccall((:mongoc_cursor_next, libmongoc), Bool, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}), cursor_handle, bson_document_ref)
end

function mongoc_cursor_set_limit(cursor_handle::Ptr{Cvoid}, limit::Int)
    ccall((:mongoc_cursor_set_limit, libmongoc), Bool, (Ptr{Cvoid}, Int64), cursor_handle, limit)
end
