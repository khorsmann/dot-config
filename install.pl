#!/usr/bin/env perl

use strict;
use warnings;
use v5.10.0;

# no warnings 'uninitialized';

use Cwd 'abs_path';
use Data::Dumper;
use Fcntl ':mode';
use File::Basename;
use File::Find;
use File::stat;
use File::stat ':FIELDS';
use File::Spec::Functions qw(abs2rel);
use Getopt::Long;
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

my @KEYNAMES =
  ( 'name', 'uid_name', 'gid_name', 'uid', 'gid', 'octperm', 'mode' );

sub getPermission {
    my $fh = $_[0];
    stat($fh) or die "Can't stat <$fh> : <$!>";
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
    );
    return \%permissions;
}

sub compareHashValues {
    my ($a, $b) = (@_);
    my @aValues = '';
    my @bValues = '';

    foreach my $key (sort keys %{$a}) {
        push @aValues, "$a->{$key}";
        if (exists $b->{$key} ) {
            push @bValues, "$b->{$key}";
        }
    }

    if (@{aValues} ~~ @{bValues}) {
        return;
    } else {
        return 1;
    };
}

sub setPermission {
    my ($a) = (@_);
    if (   (exists $a->{name})
        && (exists $a->{octperm})
        && (exists $a->{uid_name})
        && (exists $a->{gid_name})) {

        my $uid = getpwnam($a->{uid_name});
        my $gid = getgrnam($a->{gid_name});
        my $fh = join ('/', ( $SOURCEDIR, $a->{name} ) );
        print "\tchmod $a->{octperm} $fh\n";
        chmod oct($a->{octperm}), "$fh";
        print "\tchown $a->{uid_name}:$a->{gid_name} $fh\n";
        print "\tchown $uid:$gid $fh\n";
        chown $uid, $gid, "$fh";
    } else {
        return 1;
    };
    # print Dumper $a->{octperm};
}

sub createCSV {
    find( { preprocess => \&preprocess, wanted => \&wanted }, $SOURCEDIR );

    # remove empty folders
    for my $idx (@FOUND) {
        if ( -d $idx && dirEmpty($idx) ) { pop @FOUND }
        push @CSV_ENTRIES, getPermission($idx);
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
    return print $msg;
}

sub yesno {
    print "$_[0]";
    print "Enter *Y*es|*N*o: ";
    chomp( my $input = <STDIN> );
    if ( $input =~ /^[Y|J]?$/i ) {
        return 1;
    }
    elsif ( $input =~ /^[Q|N]$/i ) {
        return;
    }
}


sub main {
    my $debug   = 0;
    my $setperm = '';    # option variable with default value (false)
    my $getperm = '';    # option variable with default value (false)

    my %h = (
        'help'       => \&showusage,
        'debug'      => $debug,
        'setperm'    => $setperm,
        'getperm'    => $getperm,
        'filename'   => \$CSV_FILE,     # Ref to $CSV_FILE, so its global writable
        'basefolder' => \$SOURCEDIR,    # Same here
    );

    GetOptions( \%h, 'help|?', 'debug', 'setperm', 'getperm', 'basefolder=s', 'filename=s' )
      or die("Error in command line Arguments. Use -h for help.\n");

    if ( $h{debug} ) { print Dumper( \%h ); return }
    if ( !-d ${$h{basefolder}} ) {
        die("basefolder is not a directory! $!\n");
    }

    if ( $h{setperm} ) {

        # set permissions
        my $question = "Set Permissions from <${$h{filename}}> and write it to <${$h{basefolder}}>?\n";
        if ( yesno($question) ) {
            print "Try to read permissions from file to RAM\n";
            if (&readCSV) {
                print "...done\n";
            }

            foreach my $target (@CSV_ENTRIES) {
                print "Processing <$target->{name}> \n";
                my $status = getPermission($target->{name});

                if (compareHashValues($status, $target)) {
                    print "<$target->{name}> not the same permissions! Try to fix it \n";
                    if (setPermission($target)) {
                        print "...done\n";
                    } else {
                        print "...failed!\n";
                    }
                }
            }

        }
        return;

    }
    elsif ( $h{getperm} ) {

        # get permissions
        my $question = "Get Permissions of <${$h{basefolder}}> and write it to <${$h{filename}}>?\n";
        if ( yesno($question) ) {
            if (&createCSV) {
                print "...done\n";
            }
        }
        return;
    }

    &showusage;
    return;
}

&main;

# my $mode = 0644;   chmod $mode, "foo";      # this is best
#&readCSV;
#print Dumper(\@CSV_ENTRIES);
