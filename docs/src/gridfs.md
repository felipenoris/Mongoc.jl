
# GridFS

## Upload and Download a file

```julia
db = client[DB_NAME]
bucket = Mongoc.GridFSBucket(db)

local_fp = "/path/to/a/local/file.txt"
@assert isfile(local_fp)
remote_filename = "remote_file.txt"

Mongoc.upload(bucket, remote_filename, local_fp)

download_filepath = "/path/to/a/local/download_file.txt"

Mongoc.download(bucket, remote_filename, download_filepath)
```

## Find and Delete files in Bucket

```
for doc in Mongoc.find(bucket)
    println("Deleting $(doc["filename"])")
    Mongoc.delete(bucket, doc)
end
```
