# rethinkdb-backup

This image runs rethinkdb dump to backup data using cronjob to folder `/backup`

## Usage:

    docker run -d \
        --env RETHINKDB_HOST=rethinkdb.host \
        --env RETHINKDB_PORT=27017 \
        --volume host.folder:/backup
        iteam1337/rethinkdb-backup

Moreover, if you link `rethinkdb-backup` to a rethinkdb container(e.g. `rethinkdb`) with an alias named rethinkdb, this image will try to auto load the `host`, `port` if possible.

    docker run -d -p 27017:27017 -p 28017:28017 -e --name rethinkdb tutum/rethinkdb
    docker run -d --link rethinkdb:rethinkdb -v host.folder:/backup tutum/rethinkdb-backup

## Parameters

    RETHINKDB_HOST      the host/ip of your rethinkdb database
    RETHINKDB_PORT      the port number of your rethinkdb database
    RETHINKDB_DB        the database name to dump. Default: `test`
    EXTRA_OPTS      the extra options to pass to rethinkdb dump command
    CRON_TIME       the interval of cron job to run rethinkdb dump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS     the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP     if set, create a backup when the container starts
    INIT_RESTORE_LATEST if set, restores latest backup

## Restore from a backup

See the list of backups, you can run:

    docker exec tutum-backup ls /backup

To restore database from a certain backup, simply run:

    docker exec tutum-backup /restore.sh /backup/2015.08.06.171901
