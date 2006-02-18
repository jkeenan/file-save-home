# t/06_Win32.t
use strict;
use warnings;
use Test::More;
if( $^O !~ /Win32/ ) {
    plan skip_all => 'Test irrelevant except on Win32';
} else {
    plan tests => 1;
}

ok(1, "1 is always true");
