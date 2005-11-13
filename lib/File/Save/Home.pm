package File::Save::Home;
require 5.006_001;
use strict;
use warnings;
use Exporter ();
our $VERSION     = '0.02';
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status 
    conceal_target_file 
    reveal_target_file 
    make_subhome_temp_directory 
);
our %EXPORT_TAGS = (
    subhome_status => [ qw|
        get_subhome_directory_status
        restore_subhome_directory_status 
    | ],
    target => [ qw|
        conceal_target_file 
        reveal_target_file 
    | ],
);
use Carp;
use File::Path;
use File::Spec::Functions qw|
    catfile
    splitdir
|;
use File::Temp qw| tempdir |;
*ok = *Test::More::ok;

#################### DOCUMENTATION ###################

=head1 NAME

File::Save::Home - Place file safely under user home directory

=head1 VERSION

This document refers to version 0.02, released November 12, 2005.

=head1 SYNOPSIS

    use File::Save::Home qw(
        get_home_directory
        get_subhome_directory_status
        make_subhome_directory
        restore_subhome_directory_status 
        conceal_target_file 
        reveal_target_file 
        make_subhome_temp_directory 
    );

    $home_dir = get_home_directory();

    $desired_dir_ref = get_subhome_directory_status("desired/directory");

    $desired_dir = make_subhome_directory($desired_dir_ref);

    restore_subhome_directory_status($desired_dir_ref);

    $target_ref = conceal_target_file( {
        dir     => $desired_dir,
        file    => 'file_to_be_checked',
        test    => 0,
    } );

    reveal_target_file($target_ref);

    $tmpdir = make_subhome_temp_directory;

=head1 DESCRIPTION

In the course of deploying an application on another user's system, you
sometimes need to place a file in or underneath that user's home
directory.  Can you do so safely?

This Perl extension provides several functions which try to determine whether
you can, indeed, safely create directories and files underneath a user's home
directory.  Among other things, if you are placing a file in such a location 
only temporarily -- say, for testing purposes -- you can temporarily hide 
any already existing file with the same name and restore it to its original 
name and timestamps when you are done.

=head1 USAGE

=head2 C<get_home_directory()>

Analyzes environmental information to determine whether there exists on the
system a 'HOME' or 'home-equivalent' directory.  Takes no arguments.  Returns 
that directory if it exists; C<croak>s otherwise.

On Win32, this directory is the one returned by the following function from the F<Win32>module:

    Win32->import( qw(CSIDL_LOCAL_APPDATA) );
    $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );

... which translates to something like F<C:\Documents and Settings\localuser\Local Settings\Application Data>.  

On Unix-like systems, things are much simpler.  We simply check the value of
C<$ENV{HOME}>.  We cannot do that on Win32 because C<$ENV{HOME}> is not 
defined there.

=cut

sub get_home_directory {
    my $realhome;
    if ($^O eq 'MSWin32') {
        require Win32;
        Win32->import( qw(CSIDL_LOCAL_APPDATA) );  # 0x001c 
        $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );
        $realhome =~ s{ }{\ }g;
        return $realhome if (-d $realhome);
        $realhome =~ s|(.*?)\\Local Settings(.*)|$1$2|;
        return $realhome if (-d $realhome);
        croak "Unable to identify directory equivalent to 'HOME' on Win32: $!";
    } else { # Unix-like systems
        $realhome = $ENV{HOME};
        $realhome =~ s{ }{\ }g;
        return $realhome if (-d $realhome);
        croak "Unable to identify 'HOME' directory: $!";
    }
}

=head2 C<get_subhome_directory_status()>

Takes as argument a string holding the name of a directory, either
single-level (C<mydir>) or multi-level (C<path/to/mydir>).  Determines 
whether that  directory already exists underneath the user's
home or home-equivalent directory. Calls C<get_home_directory()> internally,
then tacks on the path passed as argument. Returns a reference to a
three-element hash whose keys are:

=over 4

=item abs

The absolute path of the specified directory.

=item flag

A Boolean value indicating whether that directory already exists (a true value) 
or not (C<undef>).

=item top

The uppermost subdirectory passed as the argument to this function.

=back

=cut

sub get_subhome_directory_status {
    my $subdir = shift;
    my $home = get_home_directory();
    my $dirname = "$home/$subdir"; 
    my $subdir_top = (splitdir($subdir))[0];
    
    if (-d $dirname) {
        return {
            top     => $subdir_top,
            abs     => $dirname,
            flag    => 1,
       };
    } else {
        return {
            top     => $subdir_top,
            abs     => $dirname,
            flag    => undef,
       };
    }
}

=head2 C<make_subhome_directory()>

Takes as argument the hash reference returned by
C<get_subhome_directory_status()>. Examines the first element in that array --
the directory name -- and creates the directory if it doesn't already exist.
The function C<croak>s if the directory cannot be created.

=cut

sub make_subhome_directory {
    my $desired_dir_ref = shift;
    my $dirname = $desired_dir_ref->{abs};
    if (! -d $dirname) {
        mkpath $dirname
            or croak "Unable to create desired directory $dirname: $!";
    }
    return $dirname;
}

=head2 C<restore_subhome_directory_status()>

Undoes C<make_subhome_directory()>, I<i.e.,> if there was no specified 
directory under the user's home directory on the user's system before 
testing, any such directory created during testing is removed.  On the 
other hand, if there I<was> such a directory present before testing, 
it is left unchanged.

=cut

sub restore_subhome_directory_status {
    my $desired_dir_ref = shift;
    my $desired_dir = $desired_dir_ref->{abs};
    my $subdir_top = $desired_dir_ref->{top};
    if (! defined $desired_dir_ref->{flag}) {
        rmtree((splitdir($subdir_top))[0], 0, 1);
        (! -d $desired_dir) 
            ? return 1
            : croak "Unable to restore directory created during test: $!";
    } else {
        return 1;
    }
}

=head2 C<make_subhome_temp_directory()>

Creates a randomly named temporary directory underneath the home or
home-equivalent directory returned by C<get_home_directory()>.  This is
accomplished by use of C<File::Temp::tempdir (DIR => $home, CLEANUP => 1)>.  
Returns the directory path if succesful; C<croak>s otherwise.

B<Note:>  Any temporary directory so created remains in existence for 
the duration of the program, but is deleted (along with all its contents) 
when the program exits.

=cut

sub make_subhome_temp_directory {
    my $tdir = tempdir(DIR => get_home_directory(), CLEANUP => 1);
    return $tdir ? $tdir : croak "Unable to create temp dir under home: $!";
}

=head2 C<conceal_target_file()>

Determines whether file with specified name already exists in specified
directory and, if so, temporarily hides it by renaming it with a F<.hidden>
suffix and storing away its last access and modification times.  Takes as
argument a reference to a hash with these keys:

=over 4

=item dir

The directory in which the file is presumed to exist.

=item file

The targeted file, I<i.e.,> the file to be temporarily hidden if it already
exists.

=item test

Boolean value which, if turned on (C<1>), will cause the function, when 
called, to run two C<Test::More::ok()> tests.  Defaults to off (C<0>).

=back

Returns a reference to a hash with these keys:

=over 4

=item full

The absolute path to the target file.

=item hidden

The absolute path to the now-hidden file.

=item atime

The last access time to the target file (C<(stat($file{full}))[8]>).

=item modtime

The last modification time to the target file (C<(stat($file{full}))[9]>).

=item test

The value of the key C<test> in the hash passed by reference as an argument to
this function.

=back

=cut

sub conceal_target_file {
    my $arg_ref = shift;
    my $desired_dir = $arg_ref->{dir};
    my $target_file = $arg_ref->{file};
    my $test_flag   = $arg_ref->{test};
    my $target_file_hidden = $target_file . '.hidden';
    my %targ;
    $targ{full} = catfile( $desired_dir, $target_file );
    $targ{hidden} = catfile( $desired_dir, $target_file_hidden );
    if (-f $targ{full}) {
        $targ{atime}   = (stat($targ{full}))[8];
        $targ{modtime} = (stat($targ{full}))[9];
        rename $targ{full}, $targ{hidden}
            or croak "Unable to rename $targ{full}: $!";
        if ($test_flag) {
            ok(! -f $targ{full}, "target file temporarily suppressed");
            ok(-f $targ{hidden}, "target file now hidden");
        }
    } else {
        if ($test_flag) {
            ok(! -f $targ{full}, "target file not found");
            ok(1, "target file not found");
        }
    }
    $targ{test} = $test_flag;
    return { %targ };
}

=head2 C<reveal_target_file()>

Used in conjunction with C<conceal_target_file()> to restore the original
status of the file targeted by C<conceal_target_file()>, I<i.e.,> renames the
hidden file to its original name by removing the F<.hidden> suffix, thereby
deleting any other file with the original name created between the calls tothe
two functions.  C<croak>s if the hidden file cannot be renamed.  Takes as 
argument the hash reference returned by C<conceal_target_file()>.  If the 
value for the C<test> key in the hash passed as an argument to 
C<conceal_target_file()> was true, then a call to C<reveal_target_file> 
will run three C<Test::More::ok()> tests.

=cut

sub reveal_target_file {
    my $target_ref = shift;;
    if(-f $target_ref->{hidden} ) {
        rename $target_ref->{hidden}, $target_ref->{full},
            or croak "Unable to rename $target_ref->{hidden}: $!";
        if ($target_ref->{test}) {
            ok(-f $target_ref->{full}, 
                "target file re-established");
            ok(! -f $target_ref->{hidden}, 
                "hidden target now gone");
            ok( (utime $target_ref->{atime}, 
                       $target_ref->{modtime}, 
                      ($target_ref->{full})
                ), "atime and modtime of target file restored");
        }
    } else {
        if ($target_ref->{test}) {
            ok(1, "test not relevant");
            ok(1, "test not relevant");
            ok(1, "test not relevant");
        }
    }
}


=head1 BUGS AND TODO

So far tested only on Unix-like systems and Win32.

=head1 AUTHOR

	James E Keenan
	CPAN ID: JKEENAN
	jkeenan@cpan.org
	http://search.cpan.org/~jkeenan

=head1 ACKNOWLEDGMENTS

The subroutines in this module draw upon subroutines in
ExtUtils::ModuleMaker::Auxiliary and ExtUtils::ModuleMaker::Utility.  
After I made a presentation to the Toronto Perlmongers on October 27, 2005, 
Michael Graham suggested that these functions could be extracted to a 
separate Perl extention for more general applicability.  This module is the
implementation of Michael's suggestion.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).  ExtUtils::ModuleMaker::Auxiliary.  ExtUtils::ModuleMaker::Utility.

=cut

1;

