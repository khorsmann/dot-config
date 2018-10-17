#!/usr/bin/env perl

use strict;
use warnings;
# use v5.10.0;
# no warnings 'experimental::smartmatch';

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

my $SOURCEDIR  = dirname(abs_path(__FILE__));
my $SCRIPTNAME = basename(__FILE__);
my $CSV_FILE   = join('/', ($SOURCEDIR, 'install.csv'));
my @CSV_ENTRIES;
my @FOUND;
my @FTYPES;
$FTYPES[S_IFDIR] = "d";
$FTYPES[S_IFCHR] = "c";
$FTYPES[S_IFBLK] = "b";
$FTYPES[S_IFREG] = "f";
$FTYPES[S_IFIFO] = "f";
$FTYPES[S_IFLNK] = "l";
$FTYPES[S_IFSOCK] = "s";

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
    return 1;
}

my @KEYNAMES = ('name', 'uid_name', 'gid_name', 'uid', 'gid', 'octperm', 'mode', 'ftype');

sub getPermission {
    my $fh = $_[0];
    stat($fh) or die "Can't stat <$fh> : <$!>";
    my $relname = abs2rel($fh, $SOURCEDIR);
    my $octperm  = sprintf '%04o', $st_mode & 07777;
    my $uid_name = getpwuid($st_uid);
    my $gid_name = getgrgid($st_gid);
    my $filetype = $FTYPES[S_IFMT($st_mode)];
    # Folder or File relative to source is .
    if ($relname eq '.') { return }

    my %permissions = (
        'name'     => $relname,
        'uid_name' => $uid_name,
        'gid_name' => $gid_name,
        'uid'      => $st_uid,
        'gid'      => $st_gid,
        'octperm'  => $octperm,
        'mode'     => $st_mode,
        'ftype'    => $filetype,
    );
    return \%permissions;
}

sub compareHashValues {
    # return FALSE if HashValues are NOT SAME
    # return TRUE  if HashValues are THE SAME
    my ($a, $b) = (@_);
    my @aValues = '';
    my @bValues = '';

    foreach my $key (sort keys %{$a}) {
        push @aValues, "$a->{$key}";
        if (exists $b->{$key}) {
            push @bValues, "$b->{$key}";
        }
    }

    # todo - smartmatch is deprecated
    if (@{aValues} ~~ @{bValues}) {
        # true
        return 1;
    }
    else {
        # false
        return 0;
    }
}

sub setPermission {
    my ($a) = (@_);
    if (   (exists $a->{name})
        && (exists $a->{octperm})
        && (exists $a->{uid_name})
        && (exists $a->{gid_name})) {

        my $uid = getpwnam($a->{uid_name});
        my $gid = getgrnam($a->{gid_name});
        my $fh  = join('/', ($SOURCEDIR, $a->{name}));

        print "\tchmod $a->{octperm} $fh\n";
        print "\tchown $a->{uid_name}:$a->{gid_name} $fh\n";
        print "\tchown $uid:$gid $fh\n";

        chmod oct($a->{octperm}), "$fh";
        chown $uid, $gid, "$fh";
    }
    else {
        return 0;
    }
    return 1;
}

sub findDirFile {
    find({preprocess => \&preprocess, wanted => \&wanted}, $SOURCEDIR);

    # remove empty folders
    for my $idx (@FOUND) {
        if (-d $idx && dirEmpty($idx)) { pop @FOUND }
        push @CSV_ENTRIES, getPermission($idx);
    }
    return 1;
}

sub createCSV {
    open(my $filehandle, '>:encoding(UTF-8)', $CSV_FILE)
      or die("Could not open file '$CSV_FILE' $!");
    for my $line (@CSV_ENTRIES) {
        #print Dumper($line) . "\n";
        #if (!keys $line) { print "skip!\n $line"; next; }
        print $filehandle join(';', @{$line}{@KEYNAMES}) . "\n";
    }
    close($filehandle);
    return 1;
}

sub readCSV {
    open(my $filehandle, '<:encoding(UTF-8)', $CSV_FILE)
      or die("Could not open file '$CSV_FILE' $!");
    while (my $line = <$filehandle>) {
        chomp($line);
        my @values = split ";", $line;

        # check if @values are there
        if (@values) {
            push @CSV_ENTRIES, {map { $KEYNAMES[$_] => $values[$_] } (0 .. $#KEYNAMES)};
        }
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
    --update               Updates CSV_FILE with FILES/DIRS that are in $CSV_FILE and $SOURCEDIR
                           needs --setperm or --getperm
Needed Arguments:
    --setperm              SET FILE and DIRECTORY Permissions of <basefolder> from <filename>
    --getperm              GET FILE and DIRECTORY Permissions of <basefolder> to <filename>
EOF
    return print $msg;
}

sub yesno {
    print "$_[0]";
    print "Enter *Y*es|*N*o: ";
    chomp(my $input = <STDIN>);
    if ($input =~ /^[Y|J]?$/i) {
        return 1;
    }
    elsif ($input =~ /^[Q|N]$/i) {
        return 0;
    }
}

sub main {
    my $debug   = 0;
    my $setperm = '';      # option variable with default value (false)
    my $getperm = '';      # option variable with default value (false)
    my $update  = undef;

    my %h = (
        'help'       => \&showusage,
        'debug'      => $debug,
        'setperm'    => $setperm,
        'getperm'    => $getperm,
        'filename'   => \$CSV_FILE,     # Ref to $CSV_FILE, so its global writable
        'basefolder' => \$SOURCEDIR,    # Same here
        'update'     => $update,
    );

    GetOptions(\%h, 'help|?', 'debug', 'setperm', 'getperm', 'basefolder=s', 'filename=s', 'update')
      or die("Error in command line Arguments. Use -h for help.\n");

    if ($h{debug}) { print Dumper(\%h); return }
    if (!-d ${$h{basefolder}}) {
        die("basefolder is not a directory! $!\n");
    }

    if (($h{setperm}) && ($h{update})) {

        # set permissions and update
        my $question = "Update Filelist from CSV <${$h{filename}}> with files
        that are there in <${$h{basefolder}}> and write it to <${$h{filename}}>?\n";

        if (yesno($question)) {
            print "Try to read permissions from file to RAM\n";
            if (&readCSV) {
                print "...done\n";
            }

            if (!@CSV_ENTRIES) {
                print "No entries in <${$h{filename}}>! - ABORT!\n";
                return 0;
            }

            my $index = 0;
            foreach my $target (@CSV_ENTRIES) {
                print "Processing <$target->{name}> \n";
                my $fh = join('/', ($SOURCEDIR, $target->{name}));

                # check if target is here or not
                if (!-f $fh) {
                    if (!-d $fh) {
                        print "<$fh> not here! - Delete it from Index \n";

                        # print Dumper(\$CSV_ENTRIES[$index]);
                        delete $CSV_ENTRIES[$index];
                        next;
                    }
                }
                $index++;
            }
            &createCSV;
        }
        return 1;
    }
    elsif ($h{setperm} || ($h{getperm} && $h{update})) {

        # set permissions
        my $question = '';
        if ($h{setperm}) {
            $question = "Get Permissions of <${$h{basefolder}}> and write it to <${$h{filename}}>?\n";
        }
        elsif ($h{getperm} && $h{update}) {
            $question =
              "Get Files from CSV <${$h{filename}}> and GET PERMISSIONS of <${$h{basefolder}}> and write it to <${$h{filename}}>?\n";
        }

        if (yesno($question)) {
            print "Try to read permissions from file to RAM\n";
            if (&readCSV) {
                print "...done\n";
            }

            if (!@CSV_ENTRIES) {
                print "No entries in <${$h{filename}}>! - ABORT!\n";
                return 0;
            }
            my $index   = 0;
            my $changes = 0;
            foreach my $target (@CSV_ENTRIES) {
                my $fh = join('/', ($SOURCEDIR, $target->{name}));
                print "Processing <$fh> ";
                my $status = getPermission($fh);
                if (!compareHashValues($status, $target)) {
                    if ($h{setperm}) {
                        print " not the same permissions! Try to fix it ";
                        if (setPermission($target)) {
                            print "...done\n";
                        }
                        else {
                            print "...failed!\n";
                        }
                    }
                    elsif (($h{getperm}) && ($h{update})) {
                        print " not the same permissions! Update CSV Entry \n";
                        $CSV_ENTRIES[$index] = $status;
                        $changes++;
                    }
                }
                else {
                    print "...okay\n";
                }
                $index++;
            }
            if ($changes) {
                print "They are $changes changes so we wrote the $CSV_FILE again ";
                if (&createCSV) {
                    print "...done\n";
                }
            }
        }
        return 1;

    }
    elsif ($h{getperm}) {

        # get permissions
        my $question = "Get Permissions of <${$h{basefolder}}> and write it to <${$h{filename}}>?\n";
        if (yesno($question)) {
            if (&findDirFile) {
                if (&createCSV) {
                    print "...done\n";
                }
            }
        }
        return 1;
    }

    &showusage;
    return 0;
}

&main;

