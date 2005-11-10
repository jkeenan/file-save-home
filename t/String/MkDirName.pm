package String::MkDirName;

=pod

This is a hack on Chris Grau's CPAN module String::MkPasswd (L<http://search.cpan.org/~cgrau/String-MkPasswd-0.02/>).  I'm using
it temporarily while testing  File::Save::Home, but will eventually suggest
patches to Chris.

The current title is misleading, because the strings I am creating herewith
are more constrained than Unix or Windows file or directory names.  Currently,
I'm creating something like legal Perl variables -- only numerals, English
upper- and lower-case letters and the underscore character are permitted --
but not quite (because I'm not yet prohibiting numerals in the first
position).

=cut

use 5.006001;
use strict;
use base qw(Exporter);

use Carp qw(croak);

# Defaults.
use constant LENGTH		=> 9;
use constant MINNUM		=> 2;
use constant MINLOWER	=> 2;
use constant MINUPPER	=> 2;
use constant MINSPECIAL	=> 1;
use constant DISTRIBUTE	=> "";
use constant FATAL		=> "";

our %EXPORT_TAGS = (
	all	=> [ qw(mkdirname) ],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };
our $VERSION = "0.02";
our $FATAL = "";

my %keys = (
	dist	=> {
		lkeys	=> [ qw(q w e r t a s d f g z x c v b) ],
		rkeys	=> [ qw(y u i o p h j k l n m) ],
		lnums	=> [ qw(1 2 3 4 5 6) ],
		rnums	=> [ qw(7 8 9 0) ],
#		lspec	=> [ qw(! @ $ %), "#" ],
#		rspec	=> [
#			qw(^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /), ","
#		],
		lspec	=> [ qw( _ ) ],
		rspec	=> [ qw( _ ) ],
	},

	undist	=> {
		lkeys	=> [
			qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)
		],
		rkeys	=> [
			qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)
		],
		lnums	=> [ qw(0 1 2 3 4 5 6 7 8 9) ],
		rnums	=> [ qw(0 1 2 3 4 5 6 7 8 9) ],
#		lspec	=> [
#			qw(! @ $ % ~ ^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /),
#			"#", ","
#		],
#		rspec	=> [
#			qw(! @ $ % ~ ^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /),
#			"#", ","
#		],
		lspec	=> [ qw( _ ) ],
		rspec	=> [ qw( _ ) ],
	},
);

sub mkdirname {
	my $class	= shift if UNIVERSAL::isa $_[0], __PACKAGE__;
	my %args	= @_;

	# Configuration.
	my $length		= $args{"-length"}     || LENGTH;
	my $minnum		= defined $args{"-minnum"}
		? $args{"-minnum"}
		: MINNUM;
	my $minlower	= defined $args{"-minlower"}
		? $args{"-minlower"}
		: MINLOWER;
	my $minupper	= defined $args{"-minupper"}
		? $args{"-minupper"}
		: MINUPPER;
	my $minspecial	= defined $args{"-minspecial"}
		? $args{"-minspecial"}
		: MINSPECIAL;
	my $distribute	= defined $args{"-distribute"}
		? $args{"-distribute"}
		: DISTRIBUTE;
	my $fatal		= defined $args{"-fatal"}
		? $args{"-fatal"}
		: FATAL;

	if ( $minnum + $minlower + $minupper + $minspecial > $length ) {
		if ( $fatal || $FATAL ) {
			croak "Impossible to generate $length-character password with "
					. "$minnum numbers, $minlower lowercase letters, "
					. "$minupper uppercase letters and $minspecial special "
					. "characters";
		} else {
			return;
		}
	}

	# If there is any underspecification, use additional lowercase letters.
	$minlower = $length - ($minnum + $minupper + $minspecial);

	# Choose left or right starting hand.
	my $initially_left = my $isleft = int rand 2;

	# Select distribution of keys.
	my $lkeys = $distribute ? $keys{dist}{lkeys} : $keys{undist}{lkeys};
	my $rkeys = $distribute ? $keys{dist}{rkeys} : $keys{undist}{rkeys};
	my $lnums = $distribute ? $keys{dist}{lnums} : $keys{undist}{lnums};
	my $rnums = $distribute ? $keys{dist}{rnums} : $keys{undist}{rnums};
	my $lspec = $distribute ? $keys{dist}{lspec} : $keys{undist}{lspec};
	my $rspec = $distribute ? $keys{dist}{rspec} : $keys{undist}{rspec};

	# Generate password.

	my @lpass = (undef) x $length;	# password chars typed by left hand
	my @rpass = (undef) x $length;	# password chars typed by right hand
	my ($left, $right);

	($left, $right) = &_psplit($minnum, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lnums->[rand @$lnums]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rnums->[rand @$rnums]);
	}

	($left, $right) = &_psplit($minlower, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lkeys->[rand @$lkeys]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rkeys->[rand @$rkeys]);
	}

	($left, $right) = &_psplit($minupper, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, uc $lkeys->[rand @$lkeys]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, uc $rkeys->[rand @$rkeys]);
	}

	($left, $right) = &_psplit($minspecial, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lspec->[rand @$lspec]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rspec->[rand @$rspec]);
	}

	# Merge results together.
	my $lpass = join "", map { defined $_ ? $_ : () } @lpass;
	my $rpass = join "", map { defined $_ ? $_ : () } @rpass;

	return $initially_left ? "$lpass$rpass" : "$rpass$lpass";
}

# Insert $char into password at a random position, thereby spreading the
# different kinds of characters throughout the password.
sub _insert {
	my $pass	= shift;	# ref = ARRAY
	my $char	= shift;

	my $pos;
	do {
		$pos = int rand(1 + @$pass);
	} while ( defined $pass->[$pos] );

	$pass->[$pos] = $char;
}

# Given a size, distribute between left and right hands, taking into account
# where we left off.
sub _psplit {
	my $max		= shift;
	my $isleft	= shift;	# ref = SCALAR

	my ($left, $right);

	if ( $$isleft ) {
		$right = int($max / 2);
		$left = $max - $right;
		$$isleft = !($max % 2);
	} else {
		$left = int($max / 2);
		$right = $max - $left;
		$$isleft = !($max % 2);
	}

	return ($left, $right);
}

1;

