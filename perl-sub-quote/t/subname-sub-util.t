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
  'Sub::Util' => <<'END_SU',
package Sub::Util;
sub set_subname {
  $::sub_named = $_[0];
  return $_[1];
}
1;
END_SU
;

use Sub::Defer;

ok Sub::Defer::_CAN_SUBNAME;
my $sub = sub { 'foo' };
is Sub::Defer::_subname('foo', $sub), $sub;
is $::sub_named, 'foo';

done_testing;
