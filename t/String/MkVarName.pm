package String::MkVarName;
use 5.006001;
use strict;
use base qw(Exporter);
our @EXPORT_OK = qw{ make_varname };
our $VERSION = "0.01";

sub make_varname {
    my $length = shift;
    my @lower =  qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
    my @upper = map { uc($_) } @lower;
    my @eligibles = (@upper, @lower, q{_});
    my @chars = (@eligibles, 0..9);
    my $varname = $eligibles[int(rand(@eligibles))];
    $varname .= $chars[int(rand(@chars))] for (1 .. ($length - 1));
    return $varname;
}

1;

