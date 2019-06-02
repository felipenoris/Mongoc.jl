
#
# Streams
#

"""
    MongoStreamFile(filepath; [flags=JL_O_RDONLY], [mode=0])

Creates a stream from file located at `filepath`.

`flags` is the input to pass to `open`. Must be one of the constants
defined at `Base.Filesystem`: `Base.Filesystem.JL_O_RDONLY`,
`Base.Filesystem.JL_O_CREAT`, etc.

`mode` is an optional mode to pass to `open`.
"""
function MongoStreamFile(filepath::AbstractString; flags::Integer=Base.Filesystem.JL_O_RDONLY, mode::Integer=0)
    handle = mongoc_stream_file_new_for_path(filepath, flags, mode)
    if handle == C_NULL
        error("Couldn't create stream for $filepath.")
    end
    return MongoStreamFile(handle)
end

function close(stream::AbstractMongoStream)
    ok = mongoc_stream_close(stream.handle)
    if ok == -1
        error("Error closing stream.")
    end
    @assert ok == 0 "Unexpected result from mongoc_stream_close: $(Int(ok))"
    nothing
end

#
# Bucket
#

"""
    upload(bucket::GridFSBucket, filename::AbstractString, source::AbstractMongoStream;
        options::Union{Nothing, BSON}=nothing)

Uploads data from `source` to a GridFS file `filename`.
"""
function upload(bucket::GridFSBucket, filename::AbstractString, source::AbstractMongoStream;
        options::Union{Nothing, BSON}=nothing)

    options_handle = options == nothing ? C_NULL : options.handle
    err_ref = Ref{BSONError}()

    ok = mongoc_gridfs_bucket_upload_from_stream(
            bucket.handle,
            filename,
            source.handle,
            options_handle,
            C_NULL,
            err_ref
        )

    if !ok
        throw(err_ref[])
    end

    nothing
end

"""
    upload(bucket::GridFSBucket, remote_filename::AbstractString, local_source_filepath::AbstractString;
            flags::Integer=Base.Filesystem.JL_O_RDONLY,
            mode::Integer=0,
            options::Union{Nothing, BSON}=nothing)

High-level interface to upload a local file to a GridFS bucket.
"""
function upload(bucket::GridFSBucket, remote_filename::AbstractString, local_source_filepath::AbstractString;
        flags::Integer=Base.Filesystem.JL_O_RDONLY,
        mode::Integer=0,
        options::Union{Nothing, BSON}=nothing)

    @assert isfile(local_source_filepath) "Couldn't find $local_source_filepath."
    source_stream = MongoStreamFile(local_source_filepath, flags=flags, mode=mode)

    try
        upload(bucket, remote_filename, source_stream, options=options)
    finally
        close(source_stream)
    end
end

"""
    download(bucket::GridFSBucket, file_id::BSONValue, target::AbstractMongoStream)

Download a GridFS file identified by `file_id` to `target` stream.
"""
function download(bucket::GridFSBucket, file_id::BSONValue, target::AbstractMongoStream)
    err_ref = Ref{BSONError}()
    ok = mongoc_gridfs_bucket_download_to_stream(
            bucket.handle, file_id.handle, target.handle, err_ref
        )

    if !ok
        throw(err_ref[])
    end
    nothing
end

"""
    download(bucket::GridFSBucket, filename::AbstractString, target::AbstractMongoStream)

Download a GridFS file named `filename` to `target` stream.
"""
function download(bucket::GridFSBucket, filename::AbstractString, target::AbstractMongoStream)
    bson_filter = BSON()
    bson_filter["filename"] = String(filename)

    local found::Bool=false
    for doc in find(bucket, bson_filter)
        @assert !found "More than 1 file was found with name $filename."
        found = true

        file_id = get_as_bson_value(doc, "_id")
        download(bucket, file_id, target)
    end

    @assert found "Coudln't find file with name $filename."
end

"""
    download(bucket::GridFSBucket, remote_filename::AbstractString, local_filepath::AbstractString;
        flags::Integer=(Base.Filesystem.JL_O_CREAT | Base.Filesystem.JL_O_RDWR), mode::Integer=0o600

Downloads a GridFS file named `remote_filename` to `local_filepath`.
"""
function download(bucket::GridFSBucket, remote_filename::AbstractString, local_filepath::AbstractString;
        flags::Integer=(Base.Filesystem.JL_O_CREAT | Base.Filesystem.JL_O_RDWR), mode::Integer=0o600
    )

    download_file_stream = Mongoc.MongoStreamFile(local_filepath, flags=(Base.Filesystem.JL_O_CREAT | Base.Filesystem.JL_O_RDWR), mode=0o600)

    try
        Mongoc.download(bucket, remote_filename, download_file_stream)
    finally
        Mongoc.close(download_file_stream)
    end
end

"""
    find(bucket::GridFSBucket, bson_filter::BSON=BSON();
        options::BSON=BSON()) :: Cursor

Looks for files in GridFS bucket.
"""
function find(bucket::GridFSBucket, bson_filter::BSON=BSON();
        options::BSON=BSON()) :: Cursor

    cursor_handle = mongoc_gridfs_bucket_find(bucket.handle, bson_filter.handle, options.handle)

    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(bucket, cursor_handle)
end

"""
    delete(bucket::GridFSBucket, id::BSONValue)
    delete(bucket::GridFSBucket, file_metadata::BSON)

Deletes a file from a GridFS Bucket.
"""
function delete(bucket::GridFSBucket, id::BSONValue)
    err_ref = Ref{BSONError}()
    ok = mongoc_gridfs_bucket_delete_by_id(bucket.handle, id.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end

function delete(bucket::GridFSBucket, file_metadata::BSON)
    oid_as_bson_value = Mongoc.get_as_bson_value(file_metadata, "_id")
    delete(bucket, oid_as_bson_value)
end
