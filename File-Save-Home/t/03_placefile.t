# t/03_placefile.t
use strict;
use warnings;

use Test::More 
tests => 15;
# qw(no_plan);

use_ok('File::Save::Home', qw|
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status 
    process_target_file 
    reprocess_target_file 
| );
use lib ("t/");
use_ok('String::MkDirName', qw|mkdirname|);
use_ok('Cwd');

my ($cwd, $homedir, @subdirs, $desired_dir_ref, $desired_dir, $target_ref );
ok($homedir = get_home_directory(), 'home directory is defined');

$cwd = cwd();

ok(chdir $homedir, "able to change to $homedir");

$desired_dir_ref = 
    get_subhome_directory_status(mkdirname() . "/" . mkdirname());
ok(! defined $desired_dir_ref->[1], 
    "random directory name $desired_dir_ref->[0] is undefined");

$desired_dir = make_subhome_directory($desired_dir_ref);
ok(-d $desired_dir,
    "randomly named directory $desired_dir_ref->[0] has been created");

$target_ref = process_target_file( {
    dir     => $desired_dir,
    file    => 'file_to_be_checked',
    test    => 1,
} );

reprocess_target_file($target_ref);

ok(restore_subhome_directory_status($desired_dir_ref),
    "directory status restored");

ok(! -d $desired_dir, 
    "randomly named directory $desired_dir_ref->[0] has been deleted");

ok(chdir $cwd, "able to change back to $cwd");



