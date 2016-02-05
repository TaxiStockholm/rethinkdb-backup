#!/bin/bash

if [ "${RETHINKDB_ENV}" == "DEVELOPMENT" ]; then
    echo "ENVIRONMENT: DEV"
    RETHINKDB_HOST=${RETHINKDB_DEV_PORT_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_HOST=${RETHINKDB_DEV_PORT_1_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_PORT=${RETHINKDB_DEV_PORT_28015_TCP_PORT:-${RETHINKDB_PORT}}
    RETHINKDB_PORT=${RETHINKDB_DEV_PORT_1_28015_TCP_PORT:-${RETHINKDB_PORT}}

elif [ "${RETHINKDB_ENV}" == "TEST" ]; then
    echo "ENVIRONMENT: TEST"
    RETHINKDB_HOST=${RETHINKDB_TEST_PORT_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_HOST=${RETHINKDB_TEST_PORT_1_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_PORT=${RETHINKDB_TEST_PORT_28015_TCP_PORT:-${RETHINKDB_PORT}}
    RETHINKDB_PORT=${RETHINKDB_TEST_PORT_1_28015_TCP_PORT:-${RETHINKDB_PORT}}

else
    echo "ENVIRONMENT: PRODUCTION"
    RETHINKDB_HOST=${RETHINKDB_PORT_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_HOST=${RETHINKDB_PORT_1_28015_TCP_ADDR:-${RETHINKDB_HOST}}
    RETHINKDB_PORT=${RETHINKDB_PORT_28015_TCP_PORT:-${RETHINKDB_PORT}}
    RETHINKDB_PORT=${RETHINKDB_PORT_1_28015_TCP_PORT:-${RETHINKDB_PORT}}
fi

[ -z "${RETHINKDB_HOST}" ] && { echo "=> RETHINKDB_HOST cannot be empty" && exit 1; }
[ -z "${RETHINKDB_PORT}" ] && { echo "=> RETHINKDB_PORT cannot be empty" && exit 1; }

echo "RETHINKDB: HOST: ${RETHINKDB_HOST}, PORT: ${RETHINKDB_PORT}, DB ${RETHINKDB_DB}, EXTRA_OPTS ${EXTRA_OPTS}"

echo "=> Creating backup script"
rm -f /scripts/backups.sh
cat <<EOF >> /scripts/backups.sh
#!/bin/bash

export PATH=$PATH:/usr/local/bin/:/backups/:/scripts/

MAX_BACKUPS=${MAX_BACKUPS}
BACKUP_NAME=\rethinkdb_${RETHINKDB_ENV,,}_\$(date +\%m_\%d_\%Y_\%H_\%M_\%S).tar.gz
BACKUP_CMD="rethinkdb dump -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} -f /backups/\${BACKUP_NAME} ${EXTRA_OPTS}"

echo "=> Backup started: \${BACKUP_NAME} with \${BACKUP_CMD}"

if \${BACKUP_CMD} ;then
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backups/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backups -N1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backups -N1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backups/\${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup finished"

EOF
chmod +x /scripts/backups.sh

echo "=> Creating restore script"
rm -f /scripts/restore.sh
cat <<EOF >> /scripts/restore.sh
#!/bin/bash

export PATH=$PATH:/usr/local/bin/:/backups/:/scripts/

echo "=> Restore database from \$1"
if rethinkdb restore -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} < \$1 ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Restore Done"
EOF
chmod +x /scripts/restore.sh

touch /RETHINKDB_backup.log
tail -F /RETHINKDB_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /scripts/backups.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore lates backup"
    until nc -z $RETHINKDB_HOST $RETHINKDB_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backups/* | tail -1 | xargs /scripts/restore.sh
fi

# For details see man crontabs
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  *

echo "${CRON_TIME} /scripts/backups.sh >> /RETHINKDB_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running rethinkdb backups as a cron for ${CRON_TIME}"
exec cron -f
