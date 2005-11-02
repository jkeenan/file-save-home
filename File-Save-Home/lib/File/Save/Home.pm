package File::Save::Home;
require 5.006_001;
use strict;
use warnings;
use Exporter ();
our $VERSION     = '0.01';
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status 
);
use Carp;
use File::Path;

#################### DOCUMENTATION ###################

=head1 NAME

File::Save::Home - Place file safely under user home directory

=head1 SYNOPSIS

    use File::Save::Home qw(
        get_home_directory
        get_subhome_directory_status
        make_subhome_directory
        restore_subhome_directory_status 
   );

    $home_dir = get_home_directory();

    $desired_dir_ref = get_subhome_directory_status("desired/directory");

    $desired_dir = make_subhome_directory($desired_dir_ref);

    restore_subhome_directory_status($desired_dir_ref);

=head1 DESCRIPTION


=head1 USAGE

=head2 C<get_home_directory()>

Analyzes environmental information to determine whether there exists on the
system a 'HOME' or 'home-equivalent' directory.  Returns that directory if it
exists; C<croak>s otherwise.

On Win32, this directory is the one returned by the following function from the F<Win32>module:

    Win32->import( qw(CSIDL_LOCAL_APPDATA) );
    $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );

... which translates to something like F<C:\Documents and Settings\localuser\Local Settings\Application Data>.  

On Unix-like systems, things are much simpler.  We simply check the value of
C<$ENV{HOME}>.  We cannot do that on Win32 (at least not on ActivePerl),
because C<$ENV{HOME}> is not defined there.

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

Determines whether a specified directory already exists underneath the user's
home or home-equivalent directory. Calls C<get_home_directory()> internally,
then tacks on the path passed as argument. Returns a reference to an array 
holding a two-element list.  The first element is the complete directory name.  The second is a flag indicating whether that directory already exists (a 
true value) or not  (C<undef>).

=cut

sub get_subhome_directory_status {
    my $partial = shift;
    my $home = get_home_directory();
    my $dirname = "$home/$partial"; 
    if (-d $dirname) {
        return [$dirname, 1];
    } else {
        return [$dirname, undef];
    }
}

=head2 C<make_subhome_directory()>

Takes as argument the array reference returned by
C<get_subhome_directory_status()>. Examines the first element in that array --
the directory name -- and creates the directory if it doesn't already exist.
The function C<croak>s if the directory cannot be created.

=cut

sub make_subhome_directory {
    my $desired_dir_ref = shift;
    my $dirname = $desired_dir_ref->[0];
    if (! -d $dirname) {
        mkpath $dirname
            or croak "Unable to make directory $dirname for placement of personal defaults file or subclass: $!";
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
    my $desired_dir = $desired_dir_ref->[0];
    if (! defined $desired_dir_ref->[1]) {
        rmtree($desired_dir, 0, 1);
        if(! -d $desired_dir) {
            return 1;
        } else {
            croak "Unable to restore .modulemaker directory created during test: $!";
        }
    } else {
        return 1;
    }
}

=head1 BUGS



=head1 SUPPORT



=head1 HISTORY

0.01 Mon Oct 31 09:55:38 2005
    - original version; created by ExtUtils::ModuleMaker 0.43


=head1 AUTHOR

	James E Keenan
	CPAN ID: JKEENAN
	jkeenan@cpan.org
	http://search.cpan.org/~jkeenan

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;



