#!/bin/sh
# $Id: etc-links.sh,v 1.1 2009/08/01 16:18:40 jepace Exp $
#
# Create links in /etc from the proper CVS file
#
host=`hostname -s`
dir=/etc

cd $dir
for file in *:$host
do
    basefile=`echo $file | cut -d: -f1`
    ln -fs $file $basefile
    echo "FILE: $file ==> $basefile"
done
