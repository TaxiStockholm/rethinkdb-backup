#!/bin/bash

RETHINKDB_HOST=${RETHINKDB_PORT_28015_TCP_ADDR:-${RETHINKDB_HOST}}
RETHINKDB_HOST=${RETHINKDB_PORT_1_28015_TCP_ADDR:-${RETHINKDB_HOST}}
RETHINKDB_PORT=${RETHINKDB_PORT_28015_TCP_PORT:-${RETHINKDB_PORT}}
RETHINKDB_PORT=${RETHINKDB_PORT_1_28015_TCP_PORT:-${RETHINKDB_PORT}}

[ -z "${RETHINKDB_HOST}" ] && { echo "=> RETHINKDB_HOST cannot be empty" && exit 1; }
[ -z "${RETHINKDB_PORT}" ] && { echo "=> RETHINKDB_PORT cannot be empty" && exit 1; }

echo "RETHINKDB: HOST: ${RETHINKDB_HOST}, PORT: ${RETHINKDB_PORT}, DB ${RETHINKDB_DB}, EXTRA_OPTS ${EXTRA_OPTS}"

touch /RETHINKDB_backup.log
tail -F /RETHINKDB_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore latest backup"
    until nc -z $RETHINKDB_HOST $RETHINKDB_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backups/* | tail -1 | xargs /restore.sh && exit 0
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
printenv | sed 's/^\(.*\)$/export \1/g' > /root/env.sh
chmod +x /root/env.sh

echo "${CRON_TIME} /backup.sh >> /RETHINKDB_backup.log 2>&1" > /crontab.conf
# echo "* * * * * root echo \"Hello world\" >> /var/log/cron.log 2>&1" > /crontab.conf
crontab /crontab.conf
echo "=> Running rethinkdb backups as a cron for ${CRON_TIME}"
exec cron -f
