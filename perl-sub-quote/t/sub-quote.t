use strict;
use warnings;
no warnings 'once';
use Test::More;

use Sub::Quote qw(
  quote_sub
  quoted_from_sub
  unquote_sub
  qsub
  capture_unroll
  inlinify
  sanitize_identifier
  quotify
);

use B;

our %EVALED;

my $one = quote_sub q{
    BEGIN { $::EVALED{'one'} = 1 }
    42
};

my $two = quote_sub q{
    BEGIN { $::EVALED{'two'} = 1 }
    3 + $x++
} => { '$x' => \do { my $x = 0 } };

ok(!keys %EVALED, 'Nothing evaled yet');

is unquote_sub(sub {}), undef,
  'unquote_sub returns undef for unknown subs';

my $u_one = unquote_sub $one;

is_deeply(
  [ sort keys %EVALED ], [ qw(one) ],
  'subs one evaled'
);

is($one->(), 42, 'One (quoted version)');

is($u_one->(), 42, 'One (unquoted version)');

is($two->(), 3, 'Two (quoted version)');
is(unquote_sub($two)->(), 4, 'Two (unquoted version)');
is($two->(), 5, 'Two (quoted version again)');

my $three = quote_sub 'Foo::three' => q{
    $x = $_[1] if $_[1];
    die +(caller(0))[3] if @_ > 2;
    return $x;
} => { '$x' => \do { my $x = 'spoon' } };

is(Foo->three, 'spoon', 'get ok (named method)');
is(Foo->three('fork'), 'fork', 'set ok (named method)');
is(Foo->three, 'fork', 're-get ok (named method)');
my $e;
eval { Foo->three(qw(full cutlery set)); 1 } or $e = $@;
like $e,
  qr/Foo::three/,
  'exception contains correct name';

quote_sub 'Foo::four' => q{
  return 5;
};

my $quoted = quoted_from_sub(\&Foo::four);
like $quoted->[1], qr/return 5;/,
  'can get quoted from installed sub';
Foo::four();
my $quoted2 = quoted_from_sub(\&Foo::four);
like $quoted2->[1], qr/return 5;/,
  "can still get quoted from installed sub after undefer";
undef $quoted;

{
  package Bar;
  ::quote_sub blorp => q{ 1; };
}
ok defined &Bar::blorp,
  'bare sub name installed in current package';

my $long = "a" x 251;
undef $e;
eval {
  (quote_sub "${long}a::${long}", q{ return 1; })->();
  1;
} or $e = $@;
is $e, undef,
  'long names work if package and sub are short enough';

undef $e;
eval {
  quote_sub "${long}${long}::${long}", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^package name "$long$long" too long/,
  'over long package names error';

undef $e;
eval {
  quote_sub "${long}::${long}${long}", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^sub name "$long$long" too long/,
  'over long sub names error';

undef $e;
eval {
  quote_sub "got a space::gorp", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^package name "got a space" is not valid!/,
  'packages with spaces are invalid';

undef $e;
eval {
  quote_sub "Gorp::got a space", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^sub name "got a space" is not valid!/,
  'sub names with spaces are invalid';

undef $e;
eval {
  quote_sub "0welp::gorp", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^package name "0welp" is not valid!/,
  'package names starting with numbers are not valid';

undef $e;
eval {
  quote_sub "Gorp::0welp", q{ return 1; };
  1;
} or $e = $@;
like $e,
  qr/^sub name "0welp" is not valid!/,
  'sub names starting with numbers are not valid';

my $broken_quoted = quote_sub q{
  return 5<;
  Guh
};

undef $e;
eval {
  $broken_quoted->();
  1;
} or $e = $@;
like(
  $e, qr/Eval went very, very wrong/,
  "quoted sub with syntax error dies when called"
);

my ($location) = $e =~ /syntax error at .+? line (\d+)/;
like(
  $e, qr/$location:\s*return 5<;/,
  "syntax errors include usable line numbers"
);

sub in_main { 1 }
undef $e;
eval {
  quote_sub(q{ in_main(); })->();
  1;
} or $e = $@;
is $e, undef,
  'package preserved from context';

{
  package Arf;
  sub in_arf { 1 }
}

undef $e;
eval {
  quote_sub(q{ in_arf(); }, {}, { package => 'Arf' })->();
  1;
} or $e = $@;
is $e, undef,
  'package used from options';


{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo2 = unquote_sub $foo;
  undef $foo;

  my $foo_info = Sub::Quote::quoted_from_sub($foo_string);
  is $foo_info, undef,
    'quoted data not maintained for quoted sub deleted after being unquoted';

  is quoted_from_sub($foo2)->[3], $foo2,
    'unquoted sub still included in quote info';
}

my @stuff = (qsub q{ print "hello"; }, 1, 2);
is scalar @stuff, 3, 'qsub only accepts a single parameter';

{
  my @warnings;
  local $ENV{SUB_QUOTE_DEBUG} = 1;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  quote_sub(q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/sub\s*{.*this is in the quoted sub/s,
    "SUB_QUOTE_DEBUG - package doesn't match anon other";
  is scalar @warnings, 1,
    'single debug warning';

  $ENV{SUB_QUOTE_DEBUG} = 'Some::Package::';

  @warnings = ();
  quote_sub(q{ "this is in the quoted sub" })->();
  is scalar @warnings, 0,
    "SUB_QUOTE_DEBUG - package doesn't match anon other";

  @warnings = ();
  quote_sub('Some::Package::etc', q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    "SUB_QUOTE_DEBUG - package matches";

  @warnings = ();
  quote_sub(q{ "this is in the quoted sub" }, {}, { package => 'Some::Package' })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    "SUB_QUOTE_DEBUG - package matches anon";

  $ENV{SUB_QUOTE_DEBUG} = 'etc';

  @warnings = ();
  quote_sub(q{ "this is in the quoted sub" })->();
  is scalar @warnings, 0,
    "SUB_QUOTE_DEBUG - sub name doesn't match anon";

  @warnings = ();
  quote_sub('Some::Package::woop', q{ "this is in the quoted sub" })->();
  is scalar @warnings, 0,
    "SUB_QUOTE_DEBUG - sub name doesn't match other";

  @warnings = ();
  quote_sub('Some::Package::etc', q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    'SUB_QUOTE_DEBUG - sub name matches';

  @warnings = ();
  quote_sub('Some::Other::Package::etc', q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    'SUB_QUOTE_DEBUG - sub name matches';

  $ENV{SUB_QUOTE_DEBUG} = 'Some::Package::foo';

  @warnings = ();
  quote_sub('Some::Package::foo', q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    'SUB_QUOTE_DEBUG - fully qualified matches';

  @warnings = ();
  quote_sub('Some::Other::Package::foo', q{ "this is in the quoted sub" })->();
  is scalar @warnings,
    0,
    "SUB_QUOTE_DEBUG - fully qualified doesn't match other";

  $ENV{SUB_QUOTE_DEBUG} = '/quoted/';

  @warnings = ();
  quote_sub('Some::Package::quoted', q{ "this sub should not match" })->();
  is scalar @warnings,
    0,
    "SUB_QUOTE_DEBUG - regex doesn't match name";

  quote_sub(q{ "this is in the quoted sub" })->();
  like $warnings[0],
    qr/this is in the quoted sub/s,
    "SUB_QUOTE_DEBUG - regex matches code";
}

{
  my $sub = quote_sub q{
    BEGIN { $::EVALED{'no_defer'} = 1 }
    1;
  }, {}, {no_defer => 1};
  is $::EVALED{no_defer}, 1,
    'evaled immediately with no_defer option';
}

{
  my $sub = quote_sub 'No::Defer::Test', q{
    BEGIN { $::EVALED{'no_defer'} = 1 }
    1;
  }, {}, {no_defer => 1};
  is $::EVALED{no_defer}, 1,
    'evaled immediately with no_defer option (named)';
  ok defined &No::Defer::Test,
    'sub installed with no_defer option';
  is No::Defer::Test(), 1,
    'sub callable with no_defer option';
}

{
  my $caller;
  sub No::Install::Tester {
    $caller = (caller(1))[3];
  }
  my $sub = quote_sub 'No::Install::Test', q{
    No::Install::Tester();
  }, {}, {no_install => 1};
  ok !defined &No::Install::Test,
    'sub not installed with no_install option';
  $sub->();
  is $caller, 'No::Install::Test',
    'sub named properly with no_install option';
}

{
  my $caller;
  sub No::Install::No::Defer::Tester {
    $caller = (caller(1))[3];
  }
  my $sub = quote_sub 'No::Install::No::Defer::Test', q{
    No::Install::No::Defer::Tester();
  }, {}, {no_install => 1, no_defer => 1};
  ok !defined &No::Install::No::Defer::Test,
    'sub not installed with no_install and no_defer options';
  $sub->();
  is $caller, 'No::Install::No::Defer::Test',
    'sub named properly with no_install and no_defer options';
}

my $var = sanitize_identifier('erk-qro yuf (fid)');
eval qq{ my \$$var = 5; \$var };
is $@, '', 'sanitize_identifier gives valid identifier';

{
  my $var;
  my $sub = quote_sub q{ $$var }, { '$var' => \\$var }, { attributes => [ 'lvalue' ] };
  $sub->() = 5;
  is $var, 5,
    'attributes applied to quoted sub';
}

{
  my $var;
  my $sub = quote_sub q{ $$var }, { '$var' => \\$var }, { attributes => [ 'lvalue' ], no_defer => 1 };
  $sub->() = 5;
  is $var, 5,
    'attributes applied to quoted sub with no_defer';
}

{
  my $error;
  eval {
    my $sub = quote_sub q{ "gorf" }, {}, { attributes => [ 'oh boy' ] };
    1;
  } or $error = $@;
  like $error, qr/invalid attribute/,
    'invalid attributes are rejected';
}

{
  my $sub = quote_sub q{ sub { join " line ", (caller(0))[1,2] }->() }, {}, { line => 42 };
  like $sub->(), qr/eval.* line 42\b/, "line provided";
}

{
  my $sub = quote_sub q{ sub { join " line ", (caller(0))[1,2] }->() }, {}, { file => "welp.pl", line => 42 };
  is $sub->(), "welp.pl line 42", "file and line provided";
}

done_testing;
