package File::Save::Home;
use strict;

use Exporter ();
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(
    get_home_directory
    preexists_directory
);
#        _get_mmkr_directory
#        _preexists_mmkr_directory
#        _make_mmkr_directory
#        _restore_mmkr_dir_status
%EXPORT_TAGS = ();
use Carp;
use File::Path;

#################### DOCUMENTATION ###################

=head1 NAME

File::Save::Home - Place file safely under user home directory

=head1 SYNOPSIS

    use File::Save::Home qw(
        get_home_directory
        preexists_directory
   );

    $home_dir = get_home_directory();

    $dir_ref = preexists_directory("desired/directory");

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

=head2 C<preexists_directory()>

Determines whether a specified directory already exists underneath the user's
home or home-equivalent directory. Calls C<get_home_directory()> internally,
then tacks on the path passed as argument. Returns a reference to an array 
holding a two-element list.  The first element is the complete directory name.  The second is a flag indicating whether that directory already exists (a 
true value) or not  (C<undef>).

=cut

sub preexists_directory {
    my $partial = shift;
    my $home = get_home_directory();
    my $dirname = "$home/$partial"; 
    if (-d $dirname) {
        return [$dirname, 1];
    } else {
        return [$dirname, undef];
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



