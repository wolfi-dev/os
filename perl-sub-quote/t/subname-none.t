use strict;
use warnings;
no warnings 'once';
use lib 't/lib';

use Test::More;
use List::Util;
BEGIN {
  delete $Sub::Util::{'set_subname'};
  delete $INC{'Sub/Util.pm'};
}

use InlineModule
  'Sub::Name' => undef,
  'Sub::Util' => undef,
;

use Sub::Defer;

ok !Sub::Defer::_CAN_SUBNAME;
my $sub = sub { 'foo' };
is Sub::Defer::_subname('foo', $sub), $sub;

done_testing;
