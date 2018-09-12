var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Mongoc.jl",
    "title": "Mongoc.jl",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Mongoc.jl-1",
    "page": "Mongoc.jl",
    "title": "Mongoc.jl",
    "category": "section",
    "text": "MongoDB driver for the Julia Language.This is a thin wrapper around libmongoc, the official client library for C applications."
},

{
    "location": "api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api.html#Mongoc.BSON",
    "page": "API",
    "title": "Mongoc.BSON",
    "category": "type",
    "text": "BSON is a wrapper for C struct bson_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.BSONError",
    "page": "API",
    "title": "Mongoc.BSONError",
    "category": "type",
    "text": "Mirrors C struct bson_error_t.\n\nBSONError instances addresses are passed to libmongoc API using Ref{BSONError}(error), and are owned by the Julia process.\n\ntypedef struct {\n   uint32_t domain;\n   uint32_t code;\n   char message[504];\n} bson_error_t;\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.Client",
    "page": "API",
    "title": "Mongoc.Client",
    "category": "type",
    "text": "Client is a wrapper for C struct mongoc_client_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.Collection",
    "page": "API",
    "title": "Mongoc.Collection",
    "category": "type",
    "text": "Collection is a wrapper for C struct mongoc_collection_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.Cursor",
    "page": "API",
    "title": "Mongoc.Cursor",
    "category": "type",
    "text": "Cursor is a wrapper for C struct mongoc_cursor_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.Database",
    "page": "API",
    "title": "Mongoc.Database",
    "category": "type",
    "text": "Database is a wrapper for C struct mongoc_database_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.URI",
    "page": "API",
    "title": "Mongoc.URI",
    "category": "type",
    "text": "URI is a wrapper for C struct mongoc_uri_t.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.as_json_string-Tuple{Mongoc.BSON}",
    "page": "API",
    "title": "Mongoc.as_json_string",
    "category": "method",
    "text": "as_json_string(bson::BSON; canonical::Bool=false) :: String\n\nConverts a bson object to a JSON string.\n\nExample\n\njulia> document = Mongoc.BSON(\"{ \"hey\" : 1 }\")\nMongoc.BSON(Ptr{Nothing} @0x00007fbc8e62cc30)\n\njulia> Mongoc.as_json_string(document)\n\"{ \"hey\" : 1 }\"\n\njulia> Mongoc.as_json_string(document, canonical=true)\n\"{ \"hey\" : { \"$numberInt\" : \"1\" } }\"\n\nC API\n\nbson_as_canonical_extended_json\n`bsonasrelaxedextendedjson\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.command_simple-Tuple{Mongoc.Client,String,Mongoc.BSON}",
    "page": "API",
    "title": "Mongoc.command_simple",
    "category": "method",
    "text": "command_simple(client::Client, database::String, command::Union{String, BSON}) :: BSON\n\nExecutes a command given by a JSON string or a BSON instance.\n\nExample\n\njulia> client = Mongoc.Client() # connects to localhost at port 27017\nClient(URI(\"mongodb://localhost:27017\"))\n\njulia> bson_result = Mongoc.command_simple(client, \"admin\", \"{ \"ping\" : 1 }\")\nMongoc.BSON(Ptr{Nothing} @0x00007f8663e0d8d0)\n\njulia> println(Mongoc.as_json_string(bson_result))\n{ \"ok\" : 1.0 }\n\nSee also: command_simple_as_json.\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.command_simple_as_json-Tuple{Mongoc.Client,String,Union{String, BSON}}",
    "page": "API",
    "title": "Mongoc.command_simple_as_json",
    "category": "method",
    "text": "command_simple_as_json(client::Client, database::String, command::Union{String, BSON}) :: String\n\nSame as command_simple, but returns a JSON string.\n\nExample\n\njulia> client = Mongoc.Client() # connects to localhost at port 27017\nClient(URI(\"mongodb://localhost:27017\"))\n\njulia> result = Mongoc.command_simple_as_json(client, \"admin\", \"{ \"ping\" : 1 }\")\n\"{ \"ok\" : 1.0 }\"\n\n\n\n\n\n"
},

{
    "location": "api.html#Mongoc.set_appname!-Tuple{Mongoc.Client,String}",
    "page": "API",
    "title": "Mongoc.set_appname!",
    "category": "method",
    "text": "set_appname!(client::Client, appname::String)\n\nSets the application name for this client.\n\nThis string, along with other internal driver details, is sent to the server as part of the initial connection handshake.\n\nC API\n\nmongoc_client_set_appname.\n\n\n\n\n\n"
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [Mongoc]"
},

]}
