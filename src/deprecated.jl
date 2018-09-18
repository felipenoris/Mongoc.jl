
@static if VERSION < v"0.7-"
    function command_simple(client::Client, database::String, command::BSON)
        warn("`Mongoc.command_simple(client, database_name, command)` is deprecated. Use `Mongoc.command_simple(client[\"database_name\"], command)`.")
        return command_simple(client[database], command)
    end

    function Collection(client::Client, db_name::String, coll_name::String)
        warn("`Mongoc.Collection(client, db_name, coll_name)` is deprecated. Use `client[db_name][coll_name]`.")
        database = Database(client, db_name)
        return Collection(database, coll_name)
    end
else
    function command_simple(client::Client, database::String, command::BSON)
        @warn("`Mongoc.command_simple(client, database_name, command)` is deprecated. Use `Mongoc.command_simple(client[\"database_name\"], command)`.")
        return command_simple(client[database], command)
    end

    function Collection(client::Client, db_name::String, coll_name::String)
        @warn("`Mongoc.Collection(client, db_name, coll_name)` is deprecated. Use `client[db_name][coll_name]`.")
        database = Database(client, db_name)
        return Collection(database, coll_name)
    end
end
