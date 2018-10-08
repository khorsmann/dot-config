#!/usr/bin/env perl

use v5.10.0;
use strict;
use warnings;

# no warnings 'uninitialized';

use Cwd 'abs_path';
use Data::Dumper;
use File::Find;
use File::Basename;
use IO::Dir;

my $sourcedir  = dirname( abs_path(__FILE__) );
my $scriptname = basename(__FILE__);
my @files;
my @folders;

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
    } @_;
}

sub wanted {
    push @files,   $File::Find::name if -f;
    push @folders, $File::Find::name if -d;
    return;
}

find( { preprocess => \&preprocess, wanted => \&wanted }, $sourcedir );

# remove empty folders
for my $folder (@folders) {
    if ( dirEmpty($folder) ) { pop @folders }
}

say $sourcedir . ' files:';
print Dumper(@files);
say $sourcedir . ' folders:';
print Dumper(@folders);

exit;
