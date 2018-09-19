
#=
https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/
=#

#
# libbson
#

function bson_oid_init(oid_ref::Ref{BSONObjectId}, context::Ptr{Cvoid})
    ccall((:bson_oid_init, libbson), Cvoid, (Ref{BSONObjectId}, Ptr{Cvoid}), oid_ref, context)
end

function bson_oid_init_from_string(oid_ref::Ref{BSONObjectId}, oid_string::String)
    ccall((:bson_oid_init_from_string, libbson), Cvoid, (Ref{BSONObjectId}, Cstring), oid_ref, oid_string)
end

function bson_oid_to_string(oid::BSONObjectId)
    buffer_len = 25
    buffer = zeros(UInt8, buffer_len)
    ccall((:bson_oid_to_string, libbson), Cvoid, (Ref{BSONObjectId}, Ref{UInt8}), Ref(oid), Ref(buffer, 1))
    @assert buffer[end] == 0
    return String(buffer[1:end-1])
end

function bson_oid_compare(oid1::BSONObjectId, oid2::BSONObjectId)
    ccall((:bson_oid_compare, libbson), Cint, (Ref{BSONObjectId}, Ref{BSONObjectId}), Ref(oid1), Ref(oid2))
end

function bson_oid_get_time_t(oid::BSONObjectId)
    ccall((:bson_oid_get_time_t, libbson), Clong, (Ref{BSONObjectId},), Ref(oid))
end

function bson_oid_is_valid(str::String)
    str_length = Csize_t(length(str))
    ccall((:bson_oid_is_valid, libbson), Bool, (Cstring, Csize_t), str, str_length)
end

function bson_append_oid(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::BSONObjectId)
    ccall((:bson_append_oid, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Ref{BSONObjectId}), bson_document, key, key_length, value)
end

function bson_append_int32(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Int32)
    ccall((:bson_append_int32, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Cint), bson_document, key, key_length, value)
end

function bson_append_int64(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Int64)
    ccall((:bson_append_int64, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Clonglong), bson_document, key, key_length, value)
end

function bson_append_utf8(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::String, len::Int)
    ccall((:bson_append_utf8, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Cstring, Cint), bson_document, key, key_length, value, len)
end

function bson_append_bool(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Bool)
    ccall((:bson_append_bool, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Bool), bson_document, key, key_length, value)
end

function bson_append_double(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Float64)
    ccall((:bson_append_double, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Cdouble), bson_document, key, key_length, value)
end

function bson_append_date_time(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Int64)
    ccall((:bson_append_date_time, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Clonglong), bson_document, key, key_length, value)
end

function bson_append_document(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Ptr{Cvoid})
    ccall((:bson_append_document, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Ptr{Cvoid}), bson_document, key, key_length, value)
end

function bson_append_array(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::Ptr{Cvoid})
    ccall((:bson_append_array, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Ptr{Cvoid}), bson_document, key, key_length, value)
end

function bson_append_code(bson_document::Ptr{Cvoid}, key::String, key_length::Int, value::String)
    ccall((:bson_append_code, libbson), Bool, (Ptr{Cvoid}, Cstring, Cint, Cstring), bson_document, key, key_length, value)
end

function bson_new()
    ccall((:bson_new, libbson), Ptr{Cvoid}, ())
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

function bson_copy(bson_document::Ptr{Cvoid})
    ccall((:bson_copy, libbson), Ptr{Cvoid}, (Ptr{Cvoid},), bson_document)
end

function bson_has_field(bson_document::Ptr{Cvoid}, key::String)
    ccall((:bson_has_field, libbson), Bool, (Ptr{Cvoid}, Cstring), bson_document, key)
end

function bson_iter_init(iter_ref::Ref{BSONIter}, bson_document::Ptr{Cvoid})
    ccall((:bson_iter_init, libbson), Bool, (Ref{BSONIter}, Ptr{Cvoid}), iter_ref, bson_document)
end

function bson_iter_next(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_next, libbson), Bool, (Ref{BSONIter},), iter_ref)
end

function bson_iter_find(iter_ref::Ref{BSONIter}, key::String)
    ccall((:bson_iter_find, libbson), Bool, (Ref{BSONIter}, Cstring), iter_ref, key)
end

function bson_iter_init_find(iter_ref::Ref{BSONIter}, bson_document::Ptr{Cvoid}, key::String)
    ccall((:bson_iter_init_find, libbson), Bool, (Ref{BSONIter}, Ptr{Cvoid}, Cstring), iter_ref, bson_document, key)
end

function bson_iter_type(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_type, libbson), BSONType, (Ref{BSONIter},), iter_ref)
end

function bson_iter_key(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_key, libbson), Cstring, (Ref{BSONIter},), iter_ref)
end

function bson_iter_int32(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_int32, libbson), Int32, (Ref{BSONIter},), iter_ref)
end

function bson_iter_int64(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_int64, libbson), Int64, (Ref{BSONIter},), iter_ref)
end

function bson_iter_utf8(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_utf8, libbson), Cstring, (Ref{BSONIter}, Ptr{Cvoid}), iter_ref, C_NULL)
end

function bson_iter_bool(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_bool, libbson), Bool, (Ref{BSONIter},), iter_ref)
end

function bson_iter_double(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_double, libbson), Float64, (Ref{BSONIter},), iter_ref)
end

function bson_iter_oid(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_oid, libbson), Ptr{BSONObjectId}, (Ref{BSONIter},), iter_ref)
end

function bson_iter_date_time(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_date_time, libbson), Clonglong, (Ref{BSONIter},), iter_ref)
end

function bson_iter_recurse(iter_ref::Ref{BSONIter}, child_iter_ref::Ref{BSONIter})
    ccall((:bson_iter_recurse, libbson), Bool, (Ref{BSONIter}, Ref{BSONIter}), iter_ref, child_iter_ref)
end

function bson_iter_code(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_code, libbson), Cstring, (Ref{BSONIter}, Ptr{UInt32}), iter_ref, C_NULL)
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

function mongoc_client_find_databases_with_opts(client_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_client_find_databases_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), client_handle, bson_opts)
end

function mongoc_database_destroy(database_handle::Ptr{Cvoid})
    ccall((:mongoc_database_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), database_handle)
end

function mongoc_database_get_collection(database_handle::Ptr{Cvoid}, collection_name::String)
    ccall((:mongoc_database_get_collection, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), database_handle, collection_name)
end

function mongoc_database_find_collections_with_opts(database_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_database_find_collections_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), database_handle, bson_opts)
end

function mongoc_database_command_simple(database_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid}, read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_database_command_simple, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), database_handle, bson_command, read_prefs, bson_reply, Ref(bson_error))
end

function mongoc_database_add_user(database_handle::Ptr{Cvoid}, username::String, password::String, bson_roles::Ptr{Cvoid}, bson_custom_data::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_database_add_user, libmongoc), Bool, (Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), database_handle, username, password, bson_roles, bson_custom_data, Ref(bson_error))
end

function mongoc_database_remove_user(database_handle::Ptr{Cvoid}, username::String, bson_error::BSONError)
    ccall((:mongoc_database_remove_user, libmongoc), Bool, (Ptr{Cvoid}, Cstring, Ref{BSONError}), database_handle, username, Ref(bson_error))
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

function mongoc_collection_create_bulk_operation_with_opts(collection_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_collection_create_bulk_operation_with_opts, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), collection_handle, bson_opts)
end

function mongoc_collection_delete_one(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_delete_one, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_selector, bson_opts, bson_reply, Ref(bson_error))
end

function mongoc_collection_delete_many(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_delete_many, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_selector, bson_opts, bson_reply, Ref(bson_error))
end

function mongoc_collection_update_one(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid}, bson_update::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_update_one, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_selector, bson_update, bson_opts, bson_reply, Ref(bson_error))
end

function mongoc_collection_update_many(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid}, bson_update::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_collection_update_many, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), collection_handle, bson_selector, bson_update, bson_opts, bson_reply, Ref(bson_error))
end

function mongoc_collection_aggregate(collection_handle::Ptr{Cvoid}, flags::QueryFlags, bson_pipeline::Ptr{Cvoid}, bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid})
    ccall((:mongoc_collection_aggregate, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid}, Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), collection_handle, flags, bson_pipeline, bson_opts, read_prefs)
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

function mongoc_bulk_operation_destroy(bulk_operation_handle::Ptr{Cvoid})
    ccall((:mongoc_bulk_operation_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), bulk_operation_handle)
end

function mongoc_bulk_operation_insert_with_opts(bulk_operation_handle::Ptr{Cvoid}, bson_document::Ptr{Cvoid}, bson_options::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_bulk_operation_insert_with_opts, libmongoc), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), bulk_operation_handle, bson_document, bson_options, Ref(bson_error))
end

function mongoc_bulk_operation_execute(bulk_operation_handle::Ptr{Cvoid}, bson_reply::Ptr{Cvoid}, bson_error::BSONError)
    ccall((:mongoc_bulk_operation_execute, libmongoc), UInt32, (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}), bulk_operation_handle, bson_reply, Ref(bson_error))
end
