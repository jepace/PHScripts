#!/bin/sh
# $Id: pfbf.sh,v 1.2 2014/03/03 17:56:18 jepace Exp $
#set -x

tfile="/tmp/pfbf.$$"
dest="/etc/pf.bruteforce"
DATE=`date +%y%m%d`

# Record live list and merge in any text file changes
rm -f $tfile
pfctl -Ts -tbruteforce | sed 's/^ *//g' > $tfile
cat $dest | sed 's/^ *//g' >> $tfile
sort -n $tfile | uniq > $tfile.2

# Backup existing list
rm -f $dest.$DATE
cp -fp $dest $dest.$DATE
if [ $? -ne 0 ]
then
    echo "Error: Backup of $dest failed."
    exit 1
fi
chmod 440 $dest.$DATE
chown root:wheel $dest.$DATE
echo "Backup: $dest.$DATE"

# Move new list into place
cp $tfile.2 $dest
chmod 640 $dest
chown root:wheel $dest

# Do it
pfctl -f /etc/pf.conf

# Cleanup
rm -f $tfile
rm -f $tfile.2
