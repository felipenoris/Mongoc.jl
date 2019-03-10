
#
# Stress test to check for memory leaks (#24)
#

using Mongoc

client = Mongoc.Client() # default locahost:27017
db = client["testDB"]
collection=db["testCollection"]

document = Mongoc.BSON()
document["name"] = "Felipe"
document["age"] = 35
document["preferences"] = [ "Music", "Computer", "Photography" ]

# generate some entries
for i in 1:100000
    push!(collection, document)
end

# read bson documents from collection
for i in 1:10000
    for entry in collection
    end
end
