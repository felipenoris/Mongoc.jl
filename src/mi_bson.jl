

"""Write a symbol using the Mike Innes' encoding"""
function write_symbol(symbol)
    buf = IOBuffer()
    mi.BSON.@save buf symbol
    buf_start=seek(buf, 0)
    k = read_bson(buf_start)
    close(bufs)
    k
end

"Strip additional query information from a BSON result."
strip_info(doc::Dict) = filter( kv->kv[1]!="_id", doc)
strip_info(doc::BSON) = BSON( strip_info(Dict(doc)) )

"""
Load a symbol from a Mongoc document that was written using the Mike Innes'
 encoding
"""
function load_symbol(g_doc::Mongoc.BSON)
    g_doc_stripped = strip_info(g_doc)
    buf_read = IOBuffer()
    write_bson(buf_read, g_doc_stripped )
    buf_read_start = seek(buf_read,0)
    mi.BSON.@load buf_read_start symbol
    close(buf_read_start)
    symbol
end
