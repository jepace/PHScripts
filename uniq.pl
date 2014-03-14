#!/usr/local/bin/perl -w
use strict;

# $Id: uniq.pl,v 1.1 2003/12/04 01:24:12 jepace Exp $
use Getopt::Std;

my %arg;
my ($cmd, $ret);
my $verbose =0;


getopts("v", \%arg);
$verbose++ if $arg{v};

my %hash;

my $count = 0;
my $hits = 0;
foreach my $file ( glob "*" )
{
    $cmd = "md5 -q \"$file\"";
    $ret = `$cmd 2>&1`;
    if ($? )
    {
        print "Problem with \"$file\". Skipping...\n";
        next;
    }
    chomp $ret;
    print "$cmd\n" if $verbose;

    $count++;

    my $sum = $ret;
    print "Sum: $sum\tFile: $file\n" if $verbose;

    if (defined $hash{$sum})
    {
        print "Collision:\n\t$file\n\t$hash{$sum}\n";
        $hits++;
    }
    else
    {
        $hash{$sum} = "$file";
    }
}
print "$hits collisions [checked $count files]\n";
