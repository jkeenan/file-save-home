

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'File::Save::Home',
    VERSION_FROM => 'lib/File/Save/Home.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Place a file safely under user\'s home directory',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
