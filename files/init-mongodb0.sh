#!/usr/bin/sh

# This script is executed when the MongoDB container starts for the first time.

echo "FORKING TO POST INIT SCRIPT"
/etc/mongo/init-mongodb0-post.sh &