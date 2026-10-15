BEGIN {
  if ("$]" <= 5.008005) {
    print "1..0 # SKIP threads too unstable until perl 5.8.5\n";
    exit 0;
  }
}
use lib 't/lib';
use ThreadsCheck;
use strict;
use warnings;
use threads;
BEGIN {
  # lie to Test2 to avoid thread handling, which will crash on early 5.8.
  delete $INC{'threads.pm'};
}
use Test::More;

use Sub::Defer;

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' };
};

ok(threads->create(sub {
  my $info = Sub::Defer::defer_info($one_defer);
  my $name = $info && $info->[0] || '[undef]';
  my $ok = $name eq 'Foo::one';
  if (!$ok) {
    print STDERR "#   Bad sub name when undeferring: $name\n";
  }
  return $ok ? 1234 : 0;
})->join == 1234, 'able to retrieve info in thread');

ok(threads->create(sub {
  undefer_sub($one_defer);
  my $ok = $made{'Foo::one'} && $made{'Foo::one'} == \&Foo::one;
  return $ok ? 1234 : 0;
})->join == 1234, 'able to undefer in thread');

done_testing;
