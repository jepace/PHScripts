#!/usr/bin/perl -w
#
# $Id: temp.pl,v 1.1 2011/03/18 20:29:18 jepace Exp $
#
use strict;

my ($temp, $c_temp, $last_temp, $min_temp, $max_temp);
my $now;
my ($sleep, $max_sleep, $min_sleep);
my $dir = "-";
my $cycle = 0;
my $debug = 0;

$max_temp = 32;
$min_temp = 212;
$last_temp = 212;

$sleep = 0;
$max_sleep = 30;
$min_sleep = 5;

while (1)
{
    $now = localtime();
    $c_temp=`sysctl -n hw.acpi.thermal.tz0.temperature`;
    chomp $c_temp;
    chop $c_temp;    # Get rid of "C"
    $temp = (9 * $c_temp / 5) + 32;     # I'm American, so I suck

    $max_temp = $temp if ($temp > $max_temp);
    $min_temp = $temp if ($temp < $min_temp);

    # Record high temperature .. watch closely
    if ($temp > $max_temp)
    {
        $sleep = $min_sleep;
        print "** High record. Sleep $min_sleep\n" if $debug;
        $dir = "^";
    }

    # Is temp rising or falling?
    if ($temp < $last_temp)
    {
        $sleep += 5;
        print "** Increasing sleep to $sleep\n" if $debug;
        $dir = "|";
    }
    elsif ($temp > $last_temp)
    {
        # Getting hotter .. watch closer
        $sleep -= 5;
        print "** Reducing sleep to $sleep\n" if $debug;
        $dir = "^";
    }
    else { $dir = "-";}

    $last_temp = $temp;
    $sleep = $min_sleep if ($sleep < $min_sleep);
    $sleep = $max_sleep if ($sleep > $max_sleep);

    print "[$now] $temp\xB0F $dir [Max:$max_temp\xB0 Min:$min_temp\xB0 *$sleep] #$cycle\n";
    sleep $sleep;
    $cycle++;
}
