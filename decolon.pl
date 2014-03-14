#!/usr/local/bin/perl -w
use strict;
use Getopt::Std;
#
# $Id: decolon.pl,v 1.3 2013/07/01 18:38:27 jepace Exp $
# decolon.pl
#
# This utility removes any NTFS forbidden characters from the files
# in the current directory.
#
# TODO:
#   - Command line directory name
#   - Recursive option
#   - Exit codes
#   - Does the non-ASCII stuff work?
#
my $desired_dir = ".";
my $verbose = 0;
my $debug = 0;
my $recursive = 0;
my %arg;

getopts ("dhrv", \%arg);
$verbose++ if $arg{v};
$debug++ if $arg{d};
$recursive++ if $arg{r};

$desired_dir = shift;
$desired_dir = "." unless $desired_dir;


if ($arg{h})
{
    print "Remove non-NTFS-safe characters from filenames in the specificed directory.\n";
    print "Usage: $0 [-dhrv] [directory, default:current]\n";
    print "\t-d - Debug.  Don't rename files.\n";
    print "\t-h - Help [you're looking at it]\n";
    print "\t-r - Recursive [NOT IMPLEMENTED]. Try:\n\t\tfind $desired_dir -type d -exec $0 \\;\n";
    print "\t-v - Verbose. Display what's happening.\n";
    exit 0;
}

# FIXME
if ($arg{r})
{
    print "Recursive mode is not implemented. Try:\n";
    print "    find $desired_dir -type d -exec $0 ";
    print "-d " if $debug;
    print "-v " if $verbose;
    print "\\;\n";
    exit 1;
}

# Change to the directory, then open '.' to avoid issues with
# mointpoints and symlinks or other stranger cases.
print "Directory: '$desired_dir'\n" if $verbose;
chdir("$desired_dir") || die "chdir $desired_dir: $!";
opendir(DIR, ".") || die "opendir $desired_dir: $!";

while(my $file = readdir DIR)
{
       next if -d $file;
       # preform operations below on $file 
       my $name = $file;
       print "Checking '$file'\n" if $verbose;

       # Windows Frobidden characters:
       # / ? < > \ : * |
       # Change non-ASCII characters too. Does this work?
       #($name) =~ s/[\/\?\<\>\\\:\*\|[^\x00-\x7f]]/-/g;
       ($name) =~ s/[\/\?\<\>\\\:\*\|]/-/g;
       next if ($file eq $name);
       print "Found '$file'\n" if $verbose;

       # Make sure new name is unique
       my $index = 0;
       if ( -e $name)
       {
            $index++ while ( -e "$name.$index");
            print "Name collision '$name' [Using: $index]" if $verbose;
            $name .= ".$index";
       }
       print "Renaming to '$name'\n" if $verbose;
       print "rename $file $name\n";
       unless ($debug)
       {
            rename $file, $name || warn "$0: rename $file $name: $!";
       }
}
closedir DIR;
