#!/usr/bin/perl
use strict;

# parkwatch
# Apparantly the WDGreen drives park themselves after 8 seconds of
# inactivity.  i want to watch the count of parks to make sure things
# arent going crazy.
#
# TODO:
#   - open log file
#   - make sure root
#   - command line options

my $sleeptime = 600;

# must be root
while (1)
{
    for (my $id = 0; $id < 3; $id++)
    {
        # Display date
        my $drive = "/dev/ada$id";
        my $count = $_;
        my $output = `smartctl -a $drive | grep Load_Cycle_Count`;
        $output =~ /(\d+)\s*$/;
        my $count = $1;
        print "[" . localtime() . "] $drive: $count\n";
    }
    print "==\n";
    sleep $sleeptime;
}
