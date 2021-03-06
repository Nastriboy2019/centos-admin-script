#!/bin/sh

# Backup script.
#
# Usage:
# ./backup.sh full|diff SourceDevice BackupFilename
#

. $(dirname $0)/password.conf

BACKUP_LOG=$BACKUP_DIR/backup_`date +%Y_week%U`.log
#BACKUP_CONTAINER=Backup

#source ~yuriko/OpenStackAuth.sh		# Swift Auth Credential
#source /opt/rh/rh-php70/enable		# Enable php7

# Check Args
if [ $# -ne 2 ]; then
  echo "Usage:" 1>&2
  echo "./backup.sh full|diff SourceDevice" 1>&2
  exit 1
fi

# Delete old backup and log.
/usr/bin/find $BACKUP_DIR -maxdepth 1 -mtime +60 -name 'vda4_diff_*' -exec rm -f {} \;
/usr/bin/find $BACKUP_DIR -maxdepth 1 -mtime +180 -name 'backup_????_week??.log' -exec rm -f {} \;

# TODO Create snapshot.
/bin/sync;/bin/sync;/bin/sync
#/sbin/lvcreate --snapshot --size=500M --name backup_snap $2 >> $BACKUP_LOG

if [ "$1" = "full" ] ; then
	DUMP_LEVEL=0
	ARCHIVER="gzip -1"
	EXT=gz

#	Delete all old backups
#	/usr/bin/find $BACKUP_DIR -maxdepth 1 -name 'NCroot_*' -exec rm -f {} \;
fi
if [ "$1" = "diff" ] ; then
	DUMP_LEVEL=1
	ARCHIVER="bzip2 -9"
	EXT=bz2
fi
BACKUP_FILENAME=$(basename $2)_`date +%Y%m%d`.dump.$EXT

# Do Backup
/usr/sbin/xfsdump -e -l$DUMP_LEVEL - $2 2>> $BACKUP_LOG | ${ARCHIVER} > $BACKUP_DIR/$BACKUP_FILENAME

# TODO Remove snapshot.
#/sbin/lvremove -f /dev/conoha/backup_snap >> $BACKUP_LOG

# Upload to Object Storage.
#/usr/bin/swift upload --object-name system/$BACKUP_FILENAME $BACKUP_CONTAINER $BACKUP_DIR/$BACKUP_FILENAME 1>&2 >> $BACKUP_LOG

# set Auto delete
#/usr/bin/swift post -H "X-Delete-After: $(php /root/scripts_git/hanoi-tower-backup.php)" $BACKUP_CONTAINER system/$BACKUP_FILENAME
