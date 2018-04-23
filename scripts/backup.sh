#!/bin/bash

source /root/env.sh

MAX_BACKUPS=${MAX_BACKUPS}
BACKUP_NAME=rethinkdb_${RETHINKDB_ENV}_$(date +%Y_%m_%d_%H_%M_%S).tar.gz
BACKUP_CMD="rethinkdb dump -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} -f /backups/${BACKUP_NAME} ${EXTRA_OPTS}"

echo "=> Backup started: ${BACKUP_NAME} with ${BACKUP_CMD}"

if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backups/${BACKUP_NAME}
fi

if [ -n "${MAX_BACKUPS}" ]; then
    while [ $(ls /backups -N1 | wc -l) -gt ${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=$(ls /backups -N1 | sort | head -n 1)
        echo "   Backup ${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backups/${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup finished"
