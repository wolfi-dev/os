use strict;
use warnings;
no warnings 'once';
use Test::More;

use Sub::Quote qw(
  quote_sub
  unquote_sub
  quoted_from_sub
);

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  undef $foo;

  is quoted_from_sub($foo_string), undef,
    "quoted subs don't leak";

  Sub::Quote->CLONE;
  ok !exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE cleans out expired entries';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  Sub::Quote->CLONE;
  undef $foo;

  is quoted_from_sub($foo_string), undef,
    "CLONE doesn't strengthen refs";
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo_info = quoted_from_sub($foo_string);
  undef $foo;

  my $e;
  eval { Sub::Quote->CLONE; 1 } or $e = $@;
  is $e, undef,
    'CLONE works when quoted info saved externally';
  ok exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE keeps entries that had info saved';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo_info = $Sub::Quote::QUOTED{$foo_string};
  undef $foo;

  my $e;
  eval { Sub::Quote->CLONE; 1 } or $e = $@;
  is $e, undef,
    'CLONE works when quoted info kept alive externally';
  ok !exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE removes expired entries that were kept alive externally';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $sub = unquote_sub $foo;
  my $sub_string = "$sub";

  Sub::Quote->CLONE;

  ok quoted_from_sub($sub_string),
    'CLONE maintains entries referenced by unquoted sub';

  undef $sub;
  ok quoted_from_sub($foo_string)->[3],
    'unquoted sub still available if quoted sub exists';
}

done_testing;
