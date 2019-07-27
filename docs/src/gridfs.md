
# GridFS

GridFS is a MongoDB feature to store large files.

A BSON document can be use to store arbitrary data,
but the size limit is 16MB.
With GridFS, you can store files that exceed this limit.

Refer to [GridFS docs website](https://docs.mongodb.com/manual/core/gridfs/)
for more information.

## Buckets

Files in GridFS are organized inside Buckets.

First, create a Bucket associated with a database.
Then, add files to that bucket.

```julia
db = client[DB_NAME]
bucket = Mongoc.Bucket(db)
```

## Upload and Download a file

The following example shows how to upload
and download a file to/from a `Bucket`
represented by the variable `bucket`.

```julia
local_fp = "/path/to/a/local/file.txt"
@assert isfile(local_fp)
remote_filename = "remote_file.txt"

# will upload `local_fp` to `bucket`.
# On the remote bucket, the file will be named `remote_file.txt`.
Mongoc.upload(bucket, remote_filename, local_fp)

# downloads `remote_file.txt` to `download_filepath`.
download_filepath = "/path/to/a/local/download_file.txt"
Mongoc.download(bucket, remote_filename, download_filepath)
```

## Upload and Download using streams

Use [`Mongoc.open_upload_stream`](@ref)
and [`Mongoc.open_download_stream`](@ref)
to execute stream based upload and download
operations.

```julia
remote_filename = "uploaded_file.txt"

io = Mongoc.open_upload_stream(bucket, remote_filename)
msg = "hey you out there"
write(io, msg)
close(io)

Mongoc.open_download_stream(bucket, remote_filename) do io
    tmp_str = read(io, String)
    println( msg == tmp_str )
end
```

## Find and Delete files in Bucket

Use `Mongoc.find` on a bucket to search for files,
and `Mongoc.delete` to delete.

```julia
for doc in Mongoc.find(bucket)
    println("Deleting $(doc["filename"])")
    Mongoc.delete(bucket, doc)
end
```
