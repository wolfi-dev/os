use strict;
use warnings;
use lib 't/lib';
use InlineModule
  'Sub::Name' => undef,
  'Sub::Util' => undef,
;
use List::Util;
delete $Sub::Util::{set_subname};
do './t/sub-defer.t';
die $@
  if $@;
