#!/bin/bash

echo "=> Restore database from $1"
if rethinkdb restore $1 -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} --force ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Restore Done"
