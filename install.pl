#!/usr/bin/env perl

use v5.10.0;
use strict;
use warnings;

use Cwd 'abs_path';
use Data::Dumper;
use File::Find;
use File::Basename;

my $sourcedir = dirname(abs_path(__FILE__));
my @folders;
my @files;

sub wanted {
    push @files, $File::Find::name if -f;
    push @folders, $File::Find::name if -d;
    return;
}


find( \&wanted, $sourcedir );

say $sourcedir . ' files:';
print Dumper(@files);
say $sourcedir . ' folders:';
print Dumper(@folders);

exit;

