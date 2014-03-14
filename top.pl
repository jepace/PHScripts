#!/usr/local/bin/perl -w
use strict;

# $Id: top.pl,v 1.1 2003/12/04 01:34:32 jepace Exp $

my @classes = (
    "Archeologist",
    "Barbarian",
    "Caveman",
    "Healer",
    "Knight",
    "Monk",
    "Priest",
    "Rogue",
    "Ranger",
    "Samurai",
    "Tourist",
    "Valkyrie",
    "Wizard",
);

my $cmd;
my ($rank, $points, $user);
my $message;

my %table;

my $debug = 0;

my $me = shift;

foreach my $class ( sort @classes )
{
    print "Class: $class\n" if $debug;

    my $found = 0;

    $cmd="/usr/local/bin/nethack -s -v -p $class";
    open FILE, "$cmd |" or die "$cmd: $!\n";
    while ( <FILE> )
    {
        next if /^\s*$/;
        next if /^\s*No\s*Points/;
        next unless /^\s*\d+/;  # kill 3rd tombstone line

        $message = $_;
        ($rank, $points, $user) = /^\s*(\d+)\s+(\d+)\s+(\w+)-/;
        $message .= <FILE>;

        if ($debug)
        {
            print "User: $user, Rank: $rank, Points: $points\n";
            print "Message: $message\n\n";
        }

        if (defined $me)
        {
            if ( $user eq $me )
            {
                $found++;
                $table{$rank} = $message;
                last;
            }
        }
        else
        {
            $table{$rank} = $message;
            last;
        }
    }
    close FILE;
    print "Never played $class\n" if (defined $me && ! $found);
}

foreach ( sort {return $a <=> $b; } keys %table )
{
    print $table{$_};
}
