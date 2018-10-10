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
use File::stat ":FIELDS";
use IO::Dir;


my $sourcedir  = dirname( abs_path(__FILE__) );
my $scriptname = basename(__FILE__);
my @files;
my @folders;

sub dirEmpty { ! grep !/^\.{1,2}\z/, IO::Dir->new(@_)->read }

sub preprocess {
    # print Dumper(grep { -f or (-d and /^[^.]/) } @_);
    # ignore unwanted files
    return grep {
             $_ !~ /^.git/
          && $_ !~ /^.gitignore/
          && $_ !~ /^$scriptname/
          && $_ !~ /^setup.py/
          && $_ !~ /^README.md/
    } @_;
}

sub wanted {
    push @files,   $File::Find::name if -f;
    push @folders, $File::Find::name if -d;
    return;
}

find( { preprocess => \&preprocess, wanted => \&wanted }, $sourcedir );

sub getPermissions {
    my $fh = $_[0];
    stat($fh) or die "Can't stat $fh : $!";
    my $perms = $st_mode & 07777;
    my $octperms = sprintf("%lo",$perms);
    my $uid = getpwuid($st_uid);
    my $gid = getgrgid($st_gid);
    print "<$fh> uid: $uid is perms: $perms $octperms uid: $st_uid gid: $st_gid nlink: $st_nlink mode: $st_mode atime: $st_atime mtime: $st_mtime ctime: $st_ctime\n";
}

# remove empty folders
for my $folder (@folders) {
    if ( dirEmpty($folder) ) { pop @folders }
    getPermissions($folder);
}

for my $file (@files) {
    stat($file) or die "Can't stat $file: $!";
    print "$file is uid: $st_uid gid: $st_gid nlink: $st_nlink mode: $st_mode atime: $st_atime mtime: $st_mtime ctime: $st_ctime\n";
}
say $sourcedir . ' files:';
print Dumper(@files);
say $sourcedir . ' folders:';
print Dumper(@folders);

exit;
