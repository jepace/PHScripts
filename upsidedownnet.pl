#!/usr/bin/perl
# $Id: upsidedownnet.pl,v 1.3 2013/08/19 04:38:44 jepace Exp $
use strict;
$|=1;

my $count = 0;
my $savedir="/pool/www/upsidedown/images";
my $webpath="upsidedown/images";
my $server="http://tigger.pacehouse.com";
my $fetch="/usr/bin/fetch";
my $imgprogram="/usr/local/bin/mogrify";
#my $imgflags="-flop";
#my $imgflags="-flip";
#my $imgflags="-blur 4";
#my $imgflags="-polaroid 10";
# my $imgflags="-swirl 45";
my $imgflags="-flip -swirl 45";
#my $imgflags="-transpose";
#my $imgflags="-transverse";
my $pid = $$;
my $url;
my $command;
my $line;
my $who;
my $debug = 0;

umask 0033;
while (<>) 
{ 
    chomp $_; 
    $line = $_;
    warn "upsidedownnet: $line\n" if $debug;

    # Get IP of requestor
    /.* ([0-9.]+)\//;
    $who = $1;
    warn "Who?: $who\n" if $debug;
    unless ($who =~ /192.168.42.2[3-4]\d/ )
    {
        print "$_\n";
        next;
    }
    warn "Doing it .. $who\n" if $debug;

    if ($_ =~ /(.*\.jpg)/i) 
    { 
        $url = $1; 
        $command = "$fetch -o $savedir/$pid-$count.jpg $url";
        unless (system("$command") == 0)
        {
            warn "upsidedownnet: $command: $!\nInput Line: $line\n";
            print "$url\n";
            next;
        }

        # Process the image
        $command = "$imgprogram $imgflags $savedir/$pid-$count.jpg";
        unless (system("$command") == 0)
        {
            warn "upsidedownnet: $command: $!\nInput Line: $line\n";
            print "$url\n";
            next;
        }
        print "$server/$webpath/$pid-$count.jpg\n"; 
    } 
    elsif ($_ =~ /(.*\.gif)/i) 
    { 
        $url = $1; 
        $command = "$fetch -o $savedir/$pid-$count.gif $url";
        unless (system("$command") == 0)
        {
            warn "upsidedownnet: $command: $!\nInput Line: $line\n";
            print "$url\n";
            next;
        }

        # Modify the image
        $command = "$imgprogram $imgflags $savedir/$pid-$count.gif";
        unless (system("$command") == 0)
        {
            warn "upsidedownnet: $command: $!\nInput Line: $line\n";
            print "$url\n";
            next;
        }
        print "$server/$webpath/$pid-$count.gif\n";
    }
    else 
    { 
        print "$_\n"; 
    } 
    $count++;
}
