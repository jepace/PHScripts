#!/usr/bin/perl
use strict;

# $Id: ubhlib.pm,v 1.2 2003/12/07 23:23:55 jepace Exp $

use File::Copy;
use Cwd;            # For getting current directory
use Cwd 'abs_path'; # For getting current directory
use DB_File;        # Load database module
use Data::Dumper;

my $verbose = 1;

my $db;     # result of tie
sub dump_database
{
    my (%database) = @_;

    print "Entering dump_database ('%database')\n" if ($verbose);
    die "dump_database: database required\n" unless %database;

    foreach (sort { $database{$a} cmp $database{$b} } keys %database)
    {
        print "File: '$database{$_}' Sum: '$_'\n";
    }

    print "Leaving dump_database\n" if $verbose;
}

sub open_database
{
    my $dbfile = shift; # File to open database from
    my %database = shift;   # Structure opened by function

    print "Entering open_database($dbfile)\n" if ($verbose);
    die "open_database: database file required\n" unless $dbfile;

    tie %database, "DB_File", $dbfile, O_CREAT|O_RDWR, 0600, $DB_HASH
        or die "open_database: database '$dbfile': $!\n";

    my $num_elem=0;
    $num_elem++ foreach (keys %database);

    print "Leaving open_database ($num_elem records)\n" if $verbose;
}

sub close_database
{
    my (%database) = @_;

    print "Entering close_database\n" if ($verbose);
#    print Dumper %database if $verbose;

    untie %database;

    # Release database lock
#    unlink ("$dbfile.lock");
}

sub sync_database
{
    $db->sync();
}

sub parse_rc
{
    my ($rcfile) = @_;
    my %rc;

    open(UBHRC, $rcfile)
        or die "parse_rc: open '$rcfile': $!\n";

    while (<UBHRC>) {
        chomp;

        next if (/\s*\#.*/);

        if (m/(\w+)\s*=\s*(.*)$/)
        {
            my $keyword = $1;
            my $value   = $2;

            # That .* grabbed everything to the end-of-line, including
            # any trailing whitespace, so eat any such trailing whitespace.
            # (See Perl Cookbook, recipe 1.14 "Trimming Blanks from the
            # Ends of a String".)
            $value =~ s/\s+$//;

            if ($keyword =~ /DATADIR/)
            {
                $rc{"DATADIR"} = $value;
            }

            # XXX: Add more as needed...
        }
    }

    close (UBHRC);

    return %rc;
}

sub parse_grouplist
{
    my ($groupfile) = @_;
    my @groups = ();
    my $index=0;

    open (GROUPS, $groupfile) or 
        die "parse_grouplist: open '$groupfile': $!\n";

    while (<GROUPS>)
    {
        next if (/^\s*$/);      # Blank lines
        next if (/^\s*\#.*/);   # Comment lines

        /^([^:]+):/;
        $groups[$index++] = $1;
    }

    return @groups;
}

sub ubhname
{
    my $return;
    my ($file, $root) = @_;
    my ($realfile, $realroot);

    print "Entering ubhname($file, $root)\n" if ($verbose);
    die "ubhname: Need filename\n" unless $file;
    die "ubhname: Need root directory\n" unless $root;

    $realroot = abs_path ($root);

    # Ensure absolute path
    unless ( $file =~ /^\//)
    {
        $return = cwd . "/$file";
    }

    if ($return !~ /^$realroot/)
    {
        return undef;
    }

#    print "Early ubhname: '$return'\n";

    # Get rid of '/..'
    while ($return =~ /\.\./)
    {
        $_ = $return;
        # foo/bar/../file ==> foo/file
        /^(.+)\/.+\/\.\.(.*)$/;
        $return = $1;
        $return =  $return . "/" . $2 if ($2);
#        print "dotdot handler: '$return'\n";
    }

    # Get rid of trailing '.'
    while ( $return =~ /\/\.$/ )
    {
        $_ = $return;
        ($return) = /^(.+)\/\.$/;
#        print "slashdot handler: '$return'\n";
    }

    # Get rid of trailing superflous '/./'
    while ($return =~ /\/\.\//)
    {
        $_ = $return;
        /^(.+)\/\.\/(.+)$/;
        $return = $1 . "/" . $2;
#        print "dotslash handler: '$return'\n";
    }

    # Drop off the $start_dir portion of the filename
    $_ = $return;
    ($return) = /^$realroot[\.\/]*(.+)$/;

    # XXX: Hack based on how ubhpal starts up, with '.' as the arg to
    # find.
    if (! $return)
    {
        $return = ".";
    }
    elsif ($return !~ /^\//)
    {
        $return = "./" . $return;
    }

    print "Leaving ubhname($file, $root): '$return'\n" if ($verbose);
    
    return $return;
}

return 1;
