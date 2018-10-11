#!/usr/bin/env perl

use v5.10.0;
use strict;
use warnings;

# no warnings 'uninitialized';

use Cwd 'abs_path';
use Data::Dumper;
use File::Basename;
use File::Find;
use File::stat;
use File::stat ':FIELDS';
use File::Spec::Functions qw(abs2rel);
##  use Fcntl ':mode';
use IO::Dir;

my $sourcedir  = dirname( abs_path(__FILE__) );
my $scriptname = basename(__FILE__);
my $csv_file   = join('/', ($sourcedir, 'install.csv'));
my @found;

sub dirEmpty { !grep !/^\.{1,2}\z/, IO::Dir->new(@_)->read }

sub preprocess {
    # print Dumper(grep { -f or (-d and /^[^.]/) } @_);
    # ignore unwanted files
    return grep {
             $_ !~ /^.git/
          && $_ !~ /^.gitignore/
          && $_ !~ /^$scriptname/
          && $_ !~ /^setup.py/
          && $_ !~ /^README.md/
          && $_ !~ /^install.csv/
    } @_;
}

sub wanted {
    push @found, $File::Find::name if -f;
    push @found, $File::Find::name if -d;
    return;
}

sub getPermissions {
    my $fh = $_[0];
    stat($fh) or die "Can't stat $fh : $!";
    my $relname = abs2rel( $fh, $sourcedir );
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

find( { preprocess => \&preprocess, wanted => \&wanted }, $sourcedir );

my @CSV_ENTRIES;

# remove empty folders
for my $idx (@found) {
    if ( -d $idx  && dirEmpty($idx)) { pop @found }
    push @CSV_ENTRIES, getPermissions($idx);
}

my @keynames = ('name', 'uid_name', 'gid_name', 'uid', 'gid', 'octperm', 'mode');
# my $mode = 0644;   chmod $mode, "foo";      # this is best
open(my $filehandle, '>:encoding(UTF-8)', $csv_file) or
    die("Could not open file '$csv_file' $!");

    for my $line (@CSV_ENTRIES) {
        print $filehandle join( ';', @{$line}{@keynames} ) ."\n";
    }
close($filehandle);

exit;
