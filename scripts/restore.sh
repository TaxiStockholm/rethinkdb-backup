#!/bin/bash

echo "=> Restore database from $1"
RESTORE_CMD="rethinkdb restore $1 -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} ${EXTRA_OPTS}"
echo "=> Restore started: ${RESTORE_CMD}"
if ${RESTORE_CMD} ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Restore Done"
