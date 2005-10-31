# t/01_test.t - check module loading
use strict;
local $^W = 1;

use Test::More 
# tests => 2;
qw(no_plan);

use_ok('File::Save::Home', qw|
    get_home_directory
    preexists_directory
| );
#    _make_mmkr_directory
#    _restore_mmkr_dir_status
use lib ();
use_ok('String::MkPasswd', qw|mkpasswd|);

my ($homedir);
ok($homedir = get_home_directory(), 'home directory is defined');

# To test preexists_directory() fully, I have to test two cases:  
# (1) where a certain dir already exists under homedir
# (2) where a certain dir does not already exist under homedir

# I could approach (1) by reading homedir and noting any already existing dirs
# there, then using one of them, selected at random, as an argument to a test.
# I could approach (2) by generating a random dirname which would be
# overwhelmingly likely not to exist under homedir.

ok(chdir $homedir, "able to change to $homedir");
local *DH;
ok((opendir DH, $homedir), "able to open directory handle to $homedir");
my @subdirs = grep {-d $_ and !($_ eq '.' or $_ eq '..') } readdir DH;
# warn "$_\n" for @subdirs;
ok(closedir DH, "able to close directory handle to $homedir");
my $dirref;
if (@subdirs) {
    my $testdir = $subdirs[int(rand(@subdirs))];
    $dirref = preexists_directory($testdir);
    ok($dirref->[1], "confirm existence of $testdir under $homedir");
} else {
    $dirref = preexists_directory(mkpasswd());
    ok(! defined $dirref->[1], 
        "random directory name under $homedir is undefined");
}
$dirref = preexists_directory(mkpasswd());
ok(! defined $dirref->[1], 
    "random directory name $dirref->[0] under $homedir is undefined");

