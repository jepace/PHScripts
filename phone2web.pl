#!/usr/local/bin/perl -w
use strict;

# $Id: phone2web.pl,v 1.1 2005/01/18 17:13:20 jepace Exp $

=head1 NAME

phone2web.pl - Post camera phone pictures on to a Gallery

=head1 SYNOPSIS

phone2web.pl <email message from cameraphone>

=head1 DESCRIPTION

The email message is parsed and the sender and title, as well as the
attached picture are extracted.  This is then posted into the
appropriate Gallery.

=cut
use File::Path;     # for rmtree

my ($cmd, $ret);
my $verbose = 1;

# Path to stuff
my $GALLERYADD = "/local/usr/bin/galleryadd.pl";
my $RIPMIME = "/usr/local/bin/ripmime";
my $RIPMIME_FLAGS = "--syslog --paranoid --name-by-type --postfix";
my $TEMPDIR = "/tmp/phone2web.$$";
my $GALLERY_URL = "http://www.pacehouse.com";

my $user="unknown";
my $password = "PHONE2WEB";
my $album;

# Extract user name and picture name and picture
while (<>)
{
    print "$_\n" if $verbose;
}

exit;

$album = $user;

mkdir $TEMPDIR, 0777 or die "mkdir $TEMPDIR: $!\n";
print "mkdir $TEMPDIR\n" if $verbose;

$cmd="$RIPMIME -i $TEMPDIR/mime -d $TEMPDIR -p phone $RIPMIME_FLAGS";
$ret=`$cmd 2>&1`;
die "$cmd: $ret\n" if $?;
print "$cmd\n" if $verbose;

$cmd="$GALLERYADD -captions -l $GALLERY_URL -u $user -p $password -a $album $TEMPDIR";
$ret=`$cmd 2>&1`;
die "$cmd: $ret\n" if $?;
print "$cmd\n" if $verbose;

# Cleanup
rmtree ($TEMPDIR) or die "rmtree $TEMPDIR: $!\n";
