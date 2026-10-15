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

use Sub::Quote;

my $one = quote_sub q{
    BEGIN { $::EVALED{'one'} = 1 }
    42
};
my $one_code = quoted_from_sub($one)->[1];

my $two = quote_sub q{
    BEGIN { $::EVALED{'two'} = 1 }
    3 + $x++
} => { '$x' => \do { my $x = 0 } };

is(threads->create(sub {
  my $quoted = quoted_from_sub($one);
  $quoted && $quoted->[1];
})->join, $one_code, 'able to retrieve quoted sub in thread');

my $u_one = unquote_sub $one;

is(threads->create(sub { $one->() })->join, 42, 'One (quoted version)');

is(threads->create(sub { $u_one->() })->join, 42, 'One (unquoted version)');

my $r = threads->create(sub {
  my @r;
  push @r, $two->();
  push @r, unquote_sub($two)->();
  push @r, $two->();
  \@r;
})->join;

is($r->[0], 3, 'Two in thread (quoted version)');
is($r->[1], 4, 'Two in thread (unquoted version)');
is($r->[2], 5, 'Two in thread (quoted version again)');

done_testing;
