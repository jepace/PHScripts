#!/bin/sh
#
# $Id: backup.sh,v 1.2 2013/08/24 23:19:22 jepace Exp $
#
# backup.sh
#
# TODO:
#   Deal with zfs filesystems not mounted in /pool
#   Skip filesystems I don't want backed up
#   More error checking
#   Pretty fancy to auto generate a list, but stupid to then test to
#   remove most of them...
#   Dump databases: pg_dumpall > postgresql-YYMMDD.sql
#
#set -x

DIR=/pool
SRC=CVS_Repository

TAR=/usr/bin/tar
TARFLAGS="-cyp"
DESTDIR="$DIR/Backup"
DATE=`date +%y%m%d`

ZFSLIST="zfs list -H -t filesystem -o name"
ZFSSNAP="zfs snapshot"

for filesystem in `$ZFSLIST`
do
    if [ "$filesystem" == "pool" ] || \
       [ "$filesystem" == "pool/tmp" ] || \
       [ "$filesystem" == "pool/VirtualDrives" ] || \
       [ "$filesystem" == "pool/X" ] || \
       [ "$filesystem" == "pool/X2" ] 
    then
        echo "Skipping $filesystem..."
        continue
    fi
    echo "** Processing $filesystem..."

    zfs destroy $filesystem@$DATE > /dev/null 2>&1
    $ZFSSNAP $filesystem@$DATE
    if [ $? -ne 0 ]
    then
        echo "zfs snapshot failed. (Are you root?)"
        exit 1
    fi

    # Make a tarball of some critical systems
    if [ "$filesystem" == "pool/CVS_Repository" ] || \
       [ "$filesystem" == "pool/www" ]
    then
        FS=`basename /$filesystem`
        cd /$filesystem/.zfs/snapshot/$DATE
        echo "Creating $DESTDIR/$FS-$DATE.tar.bz2"
        $TAR $TARFLAGS -f $DESTDIR/$FS-$DATE.tar.bz2 .
    fi

#    zfs destroy $filesystem@$DATE
done

# Snapshot pool/Backup at the end of this, not the beginning
zfs destroy pool/Backup@$DATE
$ZFSSNAP pool/Backup@$DATE
