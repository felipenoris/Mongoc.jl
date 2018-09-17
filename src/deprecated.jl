
function command_simple(client::Client, database::String, command::BSON)
    warn("`Mongoc.command_simple(client, database_name, command)` is deprecated. Use `Mongoc.command_simple(client[\"database_name\"], command)`.")
    return command_simple(client[database], command)
end
