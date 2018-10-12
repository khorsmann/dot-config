#!/usr/bin/env perl

use strict;
use warnings;
use v5.10.0;

# no warnings 'uninitialized';

use Cwd 'abs_path';
use Data::Dumper;
use File::Basename;
use File::Find;
use File::stat;
use File::stat ':FIELDS';
use File::Spec::Functions qw(abs2rel);
use Getopt::Long;
##  use Fcntl ':mode';
use IO::Dir;

my $SOURCEDIR  = dirname( abs_path(__FILE__) );
my $SCRIPTNAME = basename(__FILE__);
my $CSV_FILE   = join( '/', ( $SOURCEDIR, 'install.csv' ) );
my @CSV_ENTRIES;
my @FOUND;


sub dirEmpty { !grep !/^\.{1,2}\z/, IO::Dir->new(@_)->read }

sub preprocess {
    # print Dumper(grep { -f or (-d and /^[^.]/) } @_);
    # ignore unwanted files
    return grep {
             $_ !~ /^.git/
          && $_ !~ /^.gitignore/
          && $_ !~ /^$SCRIPTNAME/
          && $_ !~ /^setup.py/
          && $_ !~ /^README.md/
          && $_ !~ /^install.csv/
    } @_;
}

sub wanted {
    push @FOUND, $File::Find::name if -f;
    push @FOUND, $File::Find::name if -d;
    return;
}

sub getPermissions {
    my $fh = $_[0];
    stat($fh) or die "Can't stat $fh : $!";
    my $relname = abs2rel( $fh, $SOURCEDIR );
    my $octperm  = sprintf '%04o', $st_mode & 07777;
    my $uid_name = getpwuid($st_uid);
    my $gid_name = getgrgid($st_gid);

    # Folder or File relative to source is .
    if ( $relname eq '.' ) { return }

    my %permissions = (
        'name'     => $relname,
        'uid_name' => $uid_name,
        'gid_name' => $gid_name,
        'uid'      => $st_uid,
        'gid'      => $st_gid,
        'octperm'  => $octperm,
        'mode'     => $st_mode,
        'atime'    => $st_atime,
        'mtime'    => $st_mtime,
        'ctime'    => $st_ctime,
    );
    return \%permissions;
}

my @KEYNAMES =
  ( 'name', 'uid_name', 'gid_name', 'uid', 'gid', 'octperm', 'mode' );

sub createCSV {
    find( { preprocess => \&preprocess, wanted => \&wanted }, $SOURCEDIR );

    # remove empty folders
    for my $idx (@FOUND) {
        if ( -d $idx && dirEmpty($idx) ) { pop @FOUND }
        push @CSV_ENTRIES, getPermissions($idx);
    }

    open( my $filehandle, '>:encoding(UTF-8)', $CSV_FILE )
      or die("Could not open file '$CSV_FILE' $!");
    for my $line (@CSV_ENTRIES) {
        print $filehandle join( ';', @{$line}{@KEYNAMES} ) . "\n";
    }
    close($filehandle);
}


sub readCSV {
    open( my $filehandle, '<:encoding(UTF-8)', $CSV_FILE )
      or die("Could not open file '$CSV_FILE' $!");
    while ( my $line = <$filehandle> ) {
        chomp($line);
        my @values = split ";", $line;
        push @CSV_ENTRIES,
          { map { $KEYNAMES[$_] => $values[$_] } ( 0 .. $#KEYNAMES ) };
    }
    close($filehandle);
}

sub showusage {
    my $msg = <<"EOF";
Usage $SCRIPTNAME [OPTIONS]:
Optional Arguments:
    --help, -h, -?         for help
    --debug, -d            for debug and exit without doing
    --filename=Filename    CSV_FILE for READING/WRITING (Default=$CSV_FILE)
    --basefolder=Folder    ROOT_DIRECTORY for GET/SET Permissions (Default=$SOURCEDIR)
Needed Arguments:
    --setperm              SET FILE and DIRECTORY Permissions of <basefolder> from <filename>
    --getperm              GET FILE and DIRECTORY Permissions of <basefolder> to <filename>
EOF
    return print $msg
}

sub yesno {
    print "$_[0]";
    print "Enter *Y*es|*N*o: ";
    chomp(my $input = <STDIN>);
    if ($input =~ /^[Y|J]?$/i) {
        return 1;
    } elsif ($input =~ /^[Q|N]$/i) {
        return;
    }
}

sub main {
    my $debug = 0;
    my $setperm = ''; # option variable with default value (false)
    my $getperm = ''; # option variable with default value (false)

    my %h = (
        'help'       => \&showusage,
        'debug'      => $debug,
        'setperm'    => $setperm,
        'getperm'    => $getperm,
        'filename'   => $CSV_FILE,
        'basefolder' => $SOURCEDIR,
    );

    GetOptions(\%h, 'help|?', 'debug', 'setperm', 'getperm', 'basefolder=s', 'filename=s')
        or die("Error in command line Arguments. Use -h for help.\n");

    if ( $h{debug} ) { print Dumper(\%h) ; return}
    if (! -d $h{basefolder} ) { die("basefolder is not a directory! $!\n")}

    if ( $h{setperm} ) {
        # set permissions
        print "setperm\n";
        return;
    } elsif ($h{getperm}) {
        # get permissions
        if (yesno("Get Permissions of $h{basefolder} and write it to $h{filename}?\n")) {
            if (&createCSV) {
                print "...done\n";
            };
        };
        return;
    };

    &showusage;


}

&main;
# my $mode = 0644;   chmod $mode, "foo";      # this is best
#&readCSV;
#print Dumper(\@CSV_ENTRIES);
