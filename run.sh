#!/bin/bash

RETHINKDB_HOST=${RETHINKDB_PORT_28015_TCP_ADDR:-${RETHINKDB_HOST}}
RETHINKDB_HOST=${RETHINKDB_PORT_1_28015_TCP_ADDR:-${RETHINKDB_HOST}}
RETHINKDB_PORT=${RETHINKDB_PORT_28015_TCP_PORT:-${RETHINKDB_PORT}}
RETHINKDB_PORT=${RETHINKDB_PORT_1_28015_TCP_PORT:-${RETHINKDB_PORT}}

[ -z "${RETHINKDB_HOST}" ] && { echo "=> RETHINKDB_HOST cannot be empty" && exit 1; }
[ -z "${RETHINKDB_PORT}" ] && { echo "=> RETHINKDB_PORT cannot be empty" && exit 1; }

echo "RETHINKDB: HOST: ${RETHINKDB_HOST} | PORT: ${RETHINKDB_PORT}"

BACKUP_CMD="rethinkdb dump -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} -e ${RETHINKDB_DB} ${EXTRA_OPTS} > ~/backup/"'${BACKUP_NAME}'
# rethinkdb dump -c 172.17.0.2:28015 > /backup/x
echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S).data

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backup/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup -N1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup -N1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup finished"

EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash
echo "=> Restore database from \$1"
if rethinkdb -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} < \$1 ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Restore Done"
EOF
chmod +x /restore.sh

touch /RETHINKDB_backup.log
tail -F /RETHINKDB_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore lates backup"
    until nc -z $RETHINKDB_HOST $RETHINKDB_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backup/* | tail -1 | xargs /restore.sh
fi

echo "${CRON_TIME} /backup.sh >> /RETHINKDB_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
