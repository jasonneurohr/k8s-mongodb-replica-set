#!/bin/bash

# By default reading from slaves is disabled to prevent apps having issues due to eventual 
#   consistency. To enable reading from the slaves add rs.slaveOk()
#
# mongodb0 is given a higher priority to ensure it is preferred as the master.
#
# NOTE: the username and password needs to be updated to match the environment variables declared
#   in the Kubernetes deployment.yml file.

echo "SLEEPING FOR 30 SECONDS"
sleep 30

echo "ENABLING THE REPLICA SET"
mongo <<EOF
use admin
db.auth("root", "password");
rs.initiate(
  {
    _id: "rs0",
    members: [
      { _id: 0, host: "mongodb0:27017", priority: 10},
      { _id: 1, host: "mongodb1:27017" },
      { _id: 2, host: "mongodb2:27017" },
    ]
  }
);
EOF

echo "SLEEPING FOR 30 SECONDS"
sleep 30

echo "WARMING UP THE DATABASE"
mongo <<EOF
use admin
db.auth("root", "password");
use your_database;
db.createCollection("your_collection");
db.your_collection.insert({"some_key": "some_value"})
EOF