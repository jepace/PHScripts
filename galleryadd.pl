#!/usr/bin/perl
use strict;
my $Version = ".07alpha";

########################################################
# README
# Previously I went to the trouble of building a whole
# distribution with README files and installation help.
# Since modifications to the script by 3rd parties were
# distributed without the accompanying files, I merged
# them all into this file.

########################################################
# MISC
# Script:   galleryadd.pl
# http://jpmullan.com/galleryupdates/
# Purpose:  Adds an image or recursive directory structure
# 			to a gallery
# Author:   Jesse Mullan <jmullan@visi.com>
# Comment:  I'd still rather be programming


########################################################
# LICENSE
# Copyright (C) 2002 Jesse Mullan
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

########################################################
# AUTHORS
# Jesse Mullan        <jmullan@visi.com>
# Here is a list of folks in alphabetical
# order who have contributed to the
# project in the form of new code,
# patches, bug fixes, or support.
# Corrections are welcome.
# Send them to jmullan@visi.com
# Bharat Mediratta    <bharat@menalto.com>
# Greg Ewing          <greg.ewing@pobox.com>

########################################################
# REQUIREMENTS
# Assuming that you have all of the requirements, simply
# make galleryadd.pl executable by you and run it.
#	chmod u+x galleryadd.pl
#	or use perl to run it
#	perl galleryadd.pl
# galleryadd.pl requires gallery_remote2.php from
# gallery 1.3.3 or better
# galleryadd.pl requires a few perl modules.
# These modules are all available via CPAN.
# CPAN has instructions for retrieving modules.
# http://www.cpan.org/modules/
# If you don't know if you are missing any modules, try running galleryadd.pl.
# perl will complain about any missing modules like this:
#   "Can't locate LWP/UserAgent1.pm in @INC (@INC contains"
# and so on.
# Here are the modules that galleryadd.pl tries to use:
# LWP::UserAgent
# http://www.linpro.no/lwp/
# http://www.perldoc.com/perl5.6.1/lib/LWP.html
require LWP::UserAgent;

# HTTP::Request::Common
# http://www.perldoc.com/perl5.6.1/lib/HTTP/Request/Common.html
use HTTP::Request::Common;

# HTTP::Cookies
# http://www.perldoc.com/perl5.6.1/lib/HTTP/Cookies.html
use HTTP::Cookies;

# HTTP::Response
# http://www.perldoc.com/perl5.6.1/lib/HTTP/Response.html
use HTTP::Response;

# Getopt::Simple
# http://search.cpan.org/author/RSAVAGE/Getopt-Simple-1.45/Simple.pm
use Getopt::Simple;

# Data::Dumper;
# when debugging we might use Data::Dumper
# http://www.perldoc.com/perl5.6.1/lib/Data/Dumper.html
#use Data::Dumper;

# constants
my $gallery_remote_protocol_version = '2.1';
my $gallery_file = '/gallery_remote2.php';
my @formats = ('JPG','jpeg','jpg', 'gif', 'png', 'crw','avi', 'mpg', 'mpeg', 'wmv', 'mov', 'swf');

# variables
#  derived from arguments
my $gallery_location;
my $gallery_album;
my $gallery_username;
my $gallery_password;
my $gallery_setcaption;
my $gallery_runquiet;
my $gallery_versiononly;
my $gallery_noverify;
my $gallery_log = 0;
my $gallery_log_filename = '';
my $gallery_log_open = 0;
#  calculated
my $gallery_album_exists;
my $gallery_filename;
my $correct_arguments = 0;
my $gallery_url;
my $ua;
my $response;
my $gallery_response_text;
my $gallery_response_throwaway;
my $gallery_response_code;
my @gallery_files =();
my $gallery_file_count;
my @gallery_response_array;
my @items;
my @albums;
my @albumnames;
my $dir;
my $i;
my $return;

# program logic and control
if ($gallery_log && $gallery_log_filename) {
    open(LOG, '>>~/galleryadd.log') || die 'Could not open logfile';
    $gallery_log_open =1;
}

my($options) = {
    'help' => {
	'type'          => '',
	'env'           => '-',
	'default'       => '',
#               'verbose'       => '',  # Not needed on every key.
	'order'         => 1,
    },
    'quiet' => {
	'type'          => '!',
	'env'           => '-',
	'default'       => '0',
	'verbose'       => 'Do not print anything unless errors are encountered',
	'order'         => 2,
    },
    'captions' => {
	'type'          => '!',
	'env'           => '-',
	'default'       => '0',
	'verbose'       => 'Use the filename to provide a caption for the image',
	'order'         => 3,
    },
    'noverify' => {
	'type'          => '!',
	'env'           => '-',
	'default'       => '0',
	'verbose'       => 'Don\'t check if the album exists before attempting to upload',
	'order'         => 4,
    },
    'location' => {
	'type'          => '=s',
	'env'           => '-',
	'default'       => '',
	'verbose'       => 'Specify the url of your gallery',
	'order'         => 5,
    },
    'album' => {
	'type'          => '=s',
	'env'           => '-',
	'default'       => '',
	'verbose'       => 'Specify the album in which to put the image',
	'order'         => 6,
    },
    'username' => {
	'type'          => '=s',			# As per Getopt::Long.
	'env'           => '-',				# Help text.
	'default'       => '',				# In case $USER is undef.
	'verbose'       => 'Specify the username to log into your gallery',
	'order'         => 7,				# Help text sort order.
    },
    'password' => {
	'type'          => '=s',
	'env'           => '-',
	'default'       => '',
	'verbose'       => 'Specify the password to log into your gallery',
	'order'         => 8,
    },
    'version' => {
	'type'          => '!',
	'env'           => '-',
	'default'       => '0',
	'verbose'       => 'Display version information and exit',
	'order'         => 10,
    },    
};

my($option) = new Getopt::Simple;
if (! $option->getOptions($options, "Version: $Version\nUsage: galleryadd.pl -l url -a album -u username -p password filenames [-c] [-q]") ) {
    exit(-1);       # Failure.
}

$gallery_setcaption = $option->{'switch'}{'captions'};
$gallery_runquiet = $option->{'switch'}{'quiet'};
$gallery_versiononly = $option->{'switch'}{'version'};
$gallery_noverify = $option->{'switch'}{'noverify'};
$gallery_location = $option->{'switch'}{'location'};
$gallery_album = $option->{'switch'}{'album'};
$gallery_username = $option->{'switch'}{'username'};
$gallery_password = $option->{'switch'}{'password'};

if ($gallery_versiononly) {
    print "galleryadd.pl version $Version\n";
    exit;
};
if (!$gallery_location) {
    print "Please specify the url of your gallery\n";
    $correct_arguments = -1;
};
if (!$gallery_album) {
    print "Please specify the album in which to put the image\n";
    $correct_arguments = -1;
};
if (!$gallery_username) {
    print "Please specify the username to log into your gallery\n";
    $correct_arguments = -1;
};
if (!$gallery_password) {
    print "Please specify the password to log into your gallery\n";
    $correct_arguments = -1;
};
for my $filename (@ARGV) {
    # ignore . and .. :
    next if ($filename eq '.' || $filename eq '..' || $filename eq '');
    $filename =~ s|\\|/|;
    if(substr($filename,-1) eq '/'){
	$filename=substr($filename,0,-1);
    }
    push (@gallery_files,$filename);
}
$gallery_file_count = @gallery_files;
if ($gallery_file_count==0) {
    print "Please specify more than $gallery_file_count files to add to your gallery\n";
    $correct_arguments = -1;
}
if ($correct_arguments) {
    print "\nUsage: galleryadd.pl -l url -a album -u username -p password [-c] [-q] [-n]\nFor help: galleryadd.pl -h\n";
    exit(-1);
}

# check the url
if (substr($gallery_location,0,7) ne 'http://') {
    $gallery_url = 'http://' . $gallery_location . $gallery_file;
} else {
    $gallery_url = $gallery_location . $gallery_file;
}

# set up the user agent
$ua = LWP::UserAgent->new;
$ua->cookie_jar(HTTP::Cookies->new(file => 'cookie_jar', autosave => 1));

# log in
if (!$gallery_runquiet) {
    print "Logging In\n";
}
$response = $ua->request(POST $gallery_url,
			 Content_Type => 'form-data',
			 Content      => [ protocol_version => $gallery_remote_protocol_version,
					   cmd => "login",
					   uname => $gallery_username,
					   password => $gallery_password
                                           ] );
if ($gallery_log_open) {
    print LOG "POST $gallery_url\n";
    print LOG "Content_Type => 'form-data'\n";
    print LOG "Content      => \n";
    print LOG "\tprotocol_version => $gallery_remote_protocol_version\n";
    print LOG "\tcmd => 'login'\n";
    print LOG "\tuname => $gallery_username\n";
    print LOG "\tpassword => password not logged\n";
    print LOG "\n";
}
if ($response->is_error) {
    $gallery_response_text = $response->error_as_HTML;
} else {
    $gallery_response_text = $response->content;
}
$gallery_response_code = $response->code;
if ($gallery_response_code != 200) {
    if ($gallery_response_code == 404) {
	print "Could not find gallery_remote2.php on server\n";
	print "Is gallery v1.3.3 or higher installed at this url?\n";
    	die "Could not log in:\tHTTP error\n$gallery_url\n"
	    . $gallery_response_code . "\n"
	    . $gallery_response_text . "\n";
    } else {
	die "Could not log in:\tHTTP error\n$gallery_url\n"
	    . $gallery_response_code . "\n"
	    . $gallery_response_text . "\n";
    }
} else {
  SWITCH: {
      if ($gallery_response_text =~ /Login successful/) {
	  if (!$gallery_runquiet) {
	      print "Logged In successfully\n";
	      if ($gallery_log_open) {
		  print LOG $gallery_response_text . "\n";
	      }
	  }
	  last SWITCH;
      }
      if ($gallery_response_text =~ /Login Incorrect/) {
	  die "Could not log in:\t'$gallery_username' $gallery_response_text\n";
	  last SWITCH;
      }
      die "Could not log in:\tUnknown error " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
  } 
}
if ($gallery_log_open) {
    print LOG $gallery_response_text . "\n";
}
if (!$gallery_noverify) {
    if (!$gallery_runquiet) {
	print "Fetching list of albums (may be slow)\n";
    }
    #Fetch list of albums
    $response = $ua->request(POST $gallery_url,
			     Content_Type => 'form-data',
			     Content      => [ protocol_version => $gallery_remote_protocol_version,
					       cmd => "fetch-albums"
					       ] );
    if ($response->is_error) {
	$gallery_response_text = $response->error_as_HTML;
    } else {
	$gallery_response_text = $response->content;
    }
    if ($gallery_log_open) {
	print LOG $gallery_response_text . "\n";
    }
    if ($gallery_response_code != 200) {
	die "Could not log in:\tHTTP error\n$gallery_url\n" . $gallery_response_code . "\n" . $gallery_response_text . "\n";
    } else {
      SWITCH: {
	  if ($gallery_response_text =~ /Fetch albums successful./) {
	      if (!$gallery_runquiet) {
		  print "Fetched list of albums.\n";
	      }
	      last SWITCH;
	  }
	  die "Could not fetch list of albums:\tUnknown error " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
      } 
    }
    @gallery_response_array = split(/\n/, $gallery_response_text);
    $gallery_response_text = pop(@gallery_response_array);
    $gallery_response_throwaway = pop(@gallery_response_array);
    $gallery_response_code = $response->code;
    $gallery_album_exists = 0;
    foreach my $item (sort (@gallery_response_array))  {
	chomp($item);
#		print $item . "\n";
	my ($field,@value) = split(/=/, $item);
	my @foo = split(/\./, $field);
	my $bar = shift(@foo);
	if ($bar eq 'album_count') {
	    next;
	}
	my $fieldname = shift(@foo);
	if ($fieldname eq 'perms') {
	    my $fieldname .= '.' . shift(@foo);
	}
	my $number = shift(@foo);
	if ($fieldname eq 'name') {
	    $albums[$number]['name'] = join('=',@value);
	    push (@albumnames,join('=',@value));
	    if ($gallery_album eq $albums[$number]['name']) {
		$gallery_album_exists = 1;
		if (!$gallery_runquiet) {
		    print "Found album '$gallery_album'\n";
		}
	    }
	}
	if ($fieldname eq 'title') {
	    $albums[$number]['title'] = join('=',@value);
	}
	if ($fieldname eq 'perms.add') {
	    $albums[$number]['add'] = join('=',@value);
	}
	if ($fieldname eq 'perms.create_sub') {
	    $albums[$number]['create_sub'] = join('=',@value);
	}
	if ($fieldname eq 'perms.del_alb') {
	    $albums[$number]['del_alb'] = join('=',@value);
	}
	if ($fieldname eq 'perms.del_item') {
	    $albums[$number]['del_item'] = join('=',@value);
	}
	if ($fieldname eq 'perms.write') {
	    $albums[$number]['write'] = join('=',@value);
	}
    }
    if (!$gallery_album_exists) {
	die "Album does not exist: $gallery_album\n"; # crazy
    }
}

for my $filename (@ARGV) {
    # ignore . and .. :
    next if ($filename eq '.' || $filename eq '..'); 
    if (-d $filename) {
	if (!-e "$filename") {
	    die "Could not find file: $filename\n"; # nuts!
	}
	if (!-r "$filename") {
	    die "This file exists, but I can't read it: $filename\n"; # looney toons!
	}
	if (!-x $filename) {
	    die "This directory exists, but I can't read it: $filename\nPlease verify the ownership and permissions"; # looney toons!
	} else {
	    add_dir($gallery_album,$filename);
	}	
    } else {
	if (isAcceptable($filename)) {
	    if (!-e "$filename") {
		die "Could not find file: $filename\n"; # nuts!
	    }
	    if (!-r "$filename") {
		die "This file exists, but I can't read it: $filename\n"; # looney toons!
	    }
	    add_image($gallery_album,"$filename");
	} else {
	    if (!$gallery_runquiet) {
		print "Ignoring $filename\n";
	    }
	}
    }
}

if ($gallery_log_open) {
    close(LOG);
}

########################################################
# SUBROUTINES

sub albumexists($) {
    my $name = shift(@_);
    for my $album (@albumnames) {
	if ($album eq $name) {
	    return -1;
	}
    }
    return 0;
}

sub add_dir ($$) {
    my $album = shift(@_);
    my $dir = shift(@_);
    my @dirname = split(/\//, $dir);
    my $wantedAlbumName = $dirname[$#dirname];
    my $newAlbumName = $wantedAlbumName;
    $i = 0;
    while (albumexists($newAlbumName)) {
	$newAlbumName = $wantedAlbumName . '_' . $i;
	$i++;
    }
    opendir(DIR, $dir) || die "I can't read this directory: $dir $!";
    my @filename = readdir(DIR);
    closedir DIR;
    
    if (!$gallery_runquiet) {
	print "Creating Album '$dir'\n";
    }
    $response = $ua->request(POST $gallery_url,
			     Content_Type => 'form-data',
			     Content      => [ protocol_version => $gallery_remote_protocol_version,
					       cmd => "new-album",
					       set_albumName => $album,
					       newAlbumName => $newAlbumName,
					       newAlbumTitle => $dirname[$#dirname],
					       newAlbumDesc => ''
					       ] );
    if ($response->is_error) {
	$gallery_response_text = $response->error_as_HTML;
    } else {
	$gallery_response_text = $response->content;
    }
    $gallery_response_code = $response->code;
    
    if ($gallery_response_code != 200) {
	die "Could not create album:\tHTTP error " .$gallery_response_code . "\t" . $gallery_response_text . "\n";
    } else {
      SWITCH: {
	  if ($gallery_response_text =~ /New album created successfully./) {
	      if (!$gallery_runquiet) {
		  print "Album '$newAlbumName' created successfully\n";
	      }
	      push (@albumnames,$newAlbumName);
	      last SWITCH;
	  }
	  if ($gallery_response_text =~ /A new album could not be created because the user does not have permission to do so./) {
	      if (!$gallery_runquiet) {
		  die "Could not create album '$newAlbumName':\tThe user does not have permission to do so. " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
	      }
	      last SWITCH;
	  }
	  die "Could not create album '$newAlbumName':\tUnknown error " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
      } 
    }
    
    foreach my $filename (sort (@filename))  {
	# ignore . and .. :
	if ($filename ne '.' && $filename ne '..') {
	    if (-d "$dir/$filename") {
		if (!-e "$dir/$filename") {
		    die "Could not find file: $dir/$filename\n"; # nuts!
		}
		if (!-r "$dir/$filename") {
		    die "This file exists, but I can't read it: $dir/$filename\n"; # looney toons!
		}
		if (!-x "$dir/$filename") {
		    die "This directory exists, but I can't read it: $dir/$filename\nPlease verify the ownership and permissions"; # looney toons!
		} else {
		    add_dir($newAlbumName,"$dir/$filename");
		}	
	    } else {
		if (isAcceptable($filename)) {
		    if (!-e "$dir/$filename") {
			die "Could not find file: $dir/$filename\n"; # nuts!
		    }
		    if (!-r "$dir/$filename") {
			die "This file exists, but I can't read it: $dir/$filename\n"; # looney toons!
		    }
		    add_image($newAlbumName,"$dir/$filename");
		} else {
		    if (!$gallery_runquiet) {
			print "Ignoring $filename\n";
		    }
		}
	    }
	}
    }
}

sub isAcceptable($) {
    my @pieces = split(/\./, shift(@_));
    my $extension = $pieces[$#pieces];
    for my $format (@formats) {
	if ($format eq $extension) {
	    return -1;
	}
    }
    return 0;
}

sub stripPathAndExtension($) {
    my $fullpath = shift(@_);
    my @path = split(/\//, $fullpath);
    my $filename = pop(@path);
    my @pieces = split(/\./, $filename);
    pop @pieces;
    return join('.',@pieces);
}

sub add_image($$) {
    my $album = shift(@_);
    my $filename = shift(@_);
    
    if (!$gallery_runquiet) {
	print "Uploading image '$filename'\n";
    }
    if ($gallery_setcaption) {
	$response = $ua->request(POST $gallery_url,
				 Content_Type => 'form-data',
				 Content      => [ protocol_version => $gallery_remote_protocol_version,
						   cmd => "add-item",
						   set_albumName => $album,
						   caption => stripPathAndExtension($filename),
						   userfile => ["$filename"]
						   ] );
	if ($gallery_log_open) {
	    print LOG "POST $gallery_url\n";
	    print LOG "Content_Type => 'form-data'\n";
	    print LOG "Content      => \n";
	    print LOG "\tprotocol_version => $gallery_remote_protocol_version\n";
	    print LOG "\tcmd => 'add-item'\n";
	    print LOG "\tset_albumName => $album\n";
	    print LOG "\tcaption => " . stripPathAndExtension($filename) . "\n";
	    print LOG "\tuserfile => \"$filename\"\n";
	    print LOG "\n";
	}
    } else {
	$response = $ua->request(POST $gallery_url,
				 Content_Type => 'form-data',
				 Content      => [ protocol_version => $gallery_remote_protocol_version,
						   cmd => "add-item",
						   set_albumName => $album,
						   setCaption => '',
						   userfile => ["$filename"]
						   ] );
	if ($gallery_log_open) {
	    print LOG "POST $gallery_url\n";
	    print LOG "Content_Type => 'form-data'\n";
	    print LOG "Content      => \n";
	    print LOG "\tprotocol_version => $gallery_remote_protocol_version\n";
	    print LOG "\tcmd => 'add-item'\n";
	    print LOG "\tset_albumName => $album\n";
	    print LOG "\tsetcaption => ''\n";
	    print LOG "\tuserfile => \"$filename\"\n";
	    print LOG "\n";
	}
    }
    if ($response->is_error) {
	$gallery_response_text = $response->error_as_HTML;
    } else {
	$gallery_response_text = $response->content;
    }
    if ($gallery_log_open) {
	print LOG $gallery_response_text . "\n";
    }
    $gallery_response_code = $response->code;
    
    if ($gallery_response_code != 200) {
	die "Could not upload image:\tHTTP error " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
    } else {
      SWITCH: {
	  if ($gallery_response_text =~ /Add photo successful./) {
	      if (!$gallery_runquiet) {
		  print "Image '$filename' uploaded successfully\n";
	      }
	      last SWITCH;
	  }
	  die "Could not upload image '$filename':\tUnknown error " . $gallery_response_code . "\t" . $gallery_response_text . "\n";
      } 
    }
}



