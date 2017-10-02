#!/bin/sh
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/PATH/TO/BACLUPSCRIPTS

THESITE="SITE_TO_BACKUP"
THEDB=$THESITE
THEDBUSER=$THESITE


THEDBPW="DB_PASSWORD"
THEDATE=`date +%d-%m-%y_%H-%M-%S`

mysqldump -u $THEDBUSER -p${THEDBPW} $THEDB | gzip > /path/to/backups/dbbackup_${THEDB}_${THEDATE}.bak.gz

tar czf /path/to/backups/sitebackup_${THESITE}_${THEDATE}.tar -C / SITE_LOCATION
gzip /path/to/backups/sitebackup_${THESITE}_${THEDATE}.tar

find /path/to/backups/site* -mtime +5 -exec rm {} \;
find /path/to/backups/db* -mtime +5 -exec rm {} \;
