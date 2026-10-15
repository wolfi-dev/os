use strict;
use warnings;
no warnings 'once';
my %opts;
BEGIN {
  for my $arg (@ARGV) {
    if ($arg =~ /\A--(perfect|5_10_0|5_6|no-hex|b-perlstring|no-xstring)\z/) {
      $opts{$1} = 1;
    }
    else {
      die "Invalid option: $arg\n";
    }
  }

  $ENV{SUB_QUOTE_NO_HEX_FLOAT} = 0+!!$opts{'no-hex'};

  {
    my $v;

    $opts{'5_6'} || $opts{'5_10_0'} || $opts{'no-xstring'} and
      (eval { require XString }),
      (local $XString::VERSION = '0.001'),
    ;

    $opts{'5_6'} and
      (require B),
      (local $B::{perlstring}),
      (local $utf8::{is_utf8}),
      ($v = 5.006),
    ;

    $opts{'5_10_0'} and
      ($v = 5.010000),
    ;

    $opts{'b-perlstring'} and
      (require B),
    ;

    $v and
      # Scalar::Util breaks on 5.42 if its Perl/XS parts see inconsistent perl
      # versions, so load it now before it gets pulled in by Test::More below
      (require Scalar::Util),
      ($v = sprintf "%.6f", $v),
      (my $t = $v + 0),
      (Internals::SvREADONLY($], 0)),
      (local $] = $v),
      (Internals::SvREADONLY($], 1)),
    ;

    require Sub::Quote;
  }

  Internals::SvREADONLY($], 1);
}

use Sub::Quote qw(
  quotify
);

use Test::More;
use Data::Dumper;
use B;

use constant HAVE_UTF8       => Sub::Quote::_HAVE_IS_UTF8;
use constant FLOAT_PRECISION => Sub::Quote::_FLOAT_PRECISION;
use constant HAVE_HEX_FLOAT  => Sub::Quote::_HAVE_HEX_FLOAT;
use constant CAN_TRACK_BOOLEANS => Sub::Quote::_CAN_TRACK_BOOLEANS;
use constant INF => 9**9**9**9;
use constant NAN => INF * 0;
use constant MAXUINT => ~0;
use constant MAXINT  => ~0 >> 1;
use constant MININT  => -(~0 >> 1) - 1;
use constant INF_NAN_SUPPORT => (
  INF == 10 * INF
  and !(NAN == 0 || NAN == 0.1 || NAN + 0 == 0)
);

sub _dump {
  my $value = shift;
  if (!defined $value) {
    return 'undef';
  }
  elsif (is_strict_numeric($value)) {
    return "$value";
  }
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;
  my $d = Data::Dumper::Dumper("$value");
  $d =~ s/\s+$//;
  $d;
}

sub _is_diag {
  my ($got, $expect) = map _dump($_), @_;
  diag sprintf <<'END_DIAG', $got, $expect;
         got: %s
    expected: %s
END_DIAG
}

sub is_numeric {
  my $flags = B::svref_2object(\($_[0]))->FLAGS;
  !!( $flags & ( B::SVp_IOK | B::SVp_NOK ) )
}
die "ASSERT: is_numeric broken for numbers"
  if !is_numeric(1);
die "ASSERT: is_numeric broken for strings"
  if is_numeric("1");

sub is_float {
  my $num = shift;
    $num != int($num)
  || $num > ~0
  || $num < -(~0>>1)-1;
}
die "ASSERT: is_float broken for integers"
  if is_float(1);
die "ASSERT: is_float broken for floats"
  if !is_float(1.1);

sub is_bool {
  my $bool = shift;
  if (CAN_TRACK_BOOLEANS) {
    BEGIN { CAN_TRACK_BOOLEANS && warnings->unimport(qw(experimental::builtin)) }
    return builtin::is_bool($bool);
  }
  else {
    if (is_numeric($bool) && $bool == 0 && $bool eq '') {
      return !!1;
    }
    else {
      # can't detect true
      return !!0;
    }
  }
}
die "ASSERT: is_bool broken for integers"
  if is_bool(1) || is_bool(0);
die "ASSERT: is_bool broken for floats"
  if is_bool(1.0);
die "ASSERT: is_bool broken for strings"
  if is_bool("1") || is_bool("0");
die "ASSERT: is_bool broken for booleans"
  if !is_bool(!!0) || (CAN_TRACK_BOOLEANS && !is_bool(!!1));


sub is_strict_numeric {
  my $flags = B::svref_2object(\($_[0]))->FLAGS;

  !!( $flags & ( B::SVp_IOK | B::SVp_NOK ) && !( $flags & B::SVp_POK ) )
}

my %flags;
BEGIN {
  no strict 'refs';
  for my $flag (qw(
    SVs_TEMP
    SVs_OBJECT
    SVs_GMG
    SVs_SMG
    SVs_RMG
    SVf_IOK
    SVf_NOK
    SVf_POK
    SVf_OOK
    SVf_FAKE
    SVf_READONLY
    SVf_PROTECT
    SVf_BREAK
    SVp_IOK
    SVp_NOK
    SVp_POK
  )) {
    if (defined &{'B::'.$flag}) {
      $flags{$flag} = &{'B::'.$flag};
    }
  }
}
sub flags {
  my $flags = B::svref_2object(\($_[0]))->FLAGS;
  join ' ', sort grep $flags & $flags{$_}, keys %flags;
}

# unique values taking flags into account
sub _uniq {
  my %s;
  grep {
    my $copy = $_;
    my $key = defined $_ ? flags($_).'|'.(HAVE_UTF8 && utf8::is_utf8($_) ? 1 : 0)."|$copy" : '';
    !$s{$key}++;
  } @_;
}

sub eval_utf8 {
  my $value = shift;
  my $output;
  eval "use utf8; \$output = $value; 1;" or die $@;
  $output;
}

my @numbers = (
  -20 .. 20,
  -0.0,
  qw(00 01 .0 .1 0.0 0.00 00.00 0.10 0.101),
  '0 but true',
  '0e0',
  (map +("1e$_", "-1e$_"), -50, -5, 0, 1, 5, 50),
  (map 1 / $_, -10 .. -2, 2 .. 10),
  (map +(1 / 9) * $_, -9 .. -1, 1 .. 9),
  (map $_ x 100, 1 .. 9),
  3.14159265358979323846264338327950288419716939937510,
  2.71828182845904523536028747135266249775724709369995,
  sqrt(2),
  1.4142135623730951,
  1.4142135623730954,
  sqrt(3),
  1.7320508075688772935274463415058722,
  1.73205080756887729352744634150587224,
  sqrt(5),
  2.2360679774997896963,
  2.23606797749978969634,
  MAXUINT,
  MAXUINT-1,
  MAXINT,
  MAXINT+1,
  MININT,
  (INF_NAN_SUPPORT ? (
    INF, -(INF),
    NAN, -(NAN),
  ) : ()),
);

my @strings = (
  "",
  (map +chr($_), 0 .. 0xff),
  "\\a\"",
  "\xC3\x84",
  "\x{ABCD}",
  "\x{1F4A9}",
);

if (HAVE_UTF8) {
  utf8::downgrade($_, 1)
    for @strings;
}

my @utf8_strings;
if (HAVE_UTF8) {
  @utf8_strings = @strings;
  utf8::upgrade($_)
    for @utf8_strings;
}

my @booleans = (!1, !0);

my @quotify = (
  undef,
  @booleans,
  (map {
    my $number = $_;
    $number += 0;
    my $string = $_;
    $string .= "";
    my $started_as_number = $number;
    my $void = $started_as_number . "";
    my $started_as_string = $string;
    $void = $started_as_string + 0;
    ($number, $started_as_number, $string, $started_as_string);
  } @numbers),
  @strings,
  @utf8_strings,
);

# HAVE_UTF8 will be artificially false under quotify-5.6.t.  skip utf8 strings
# in this case as they will produce warnings or errors in newer perls.
@quotify = grep !utf8::is_utf8($_), @quotify
  if !HAVE_UTF8 and "$]" >= 5.025;

my $eval_utf8;

for my $value (_uniq @quotify) {
  my $value_name
    = _dump($value)
    . (HAVE_UTF8 && utf8::is_utf8($value) ? ' utf8' : '')
    . (is_strict_numeric($value) ? ' pure' : '')
    . (is_numeric($value) ? ' num' : '')
    . (is_bool($value) ? ' bool' : '');

  my $quoted = quotify(my $copy = $value);
  utf8::downgrade($quoted, 1)
    if HAVE_UTF8;

  my $note = "quotified as $quoted";
  utf8::encode($note)
    if defined &utf8::encode;
  note $note;

  is flags($copy), flags($value),
    "$value_name: quotify doesn't modify input";

  my $evaled;
  eval "\$evaled = $quoted; 1" or die $@;

  for my $check (
    [ $evaled ],
    ( HAVE_UTF8 ? [ eval_utf8($quoted), ' under utf8' ] : ()),
  ) {
    my ($check_value, $suffix) = @$check;
    $suffix ||= '';

    if (is_strict_numeric($value)) {
      ok is_strict_numeric($check_value),
        "$value_name: numeric status maintained$suffix";
    }

    if (is_numeric($value)) {
      if ($value == $value) {
        my $todo;
        if (!$opts{perfect} && !HAVE_HEX_FLOAT && $check_value != $value && is_float($value)) {
          my $diff = abs($check_value - $value);
          my $accuracy = abs($value)/$diff;
          my $precision = FLOAT_PRECISION + 1;
          $todo = "not always accurate beyond $precision digits"
            if $accuracy <= 10**$precision;
        }

        local $TODO = $todo
          if $todo;
        cmp_ok $check_value, '==', $value,
          "$value_name: numeric value maintained$suffix"
          or do {
            diag "quotified as $quoted";
            diag "got float      : ".uc unpack("h*", pack("F", $check_value));
            diag "expected float : ".uc unpack("h*", pack("F", $value));
          };
      }
      else {
        cmp_ok $check_value, '!=', $check_value,
          "$value_name: numeric value maintained$suffix";
      }
    }

    if (defined $value) {
      ok $check_value eq $value,
        "$value_name: string value maintained$suffix"
        or _is_diag($check_value, $value);
    }
    else {
      is $check_value, undef,
        "$value_name: undef maintained$suffix"
        or _is_diag($check_value, $value);
    }
  }
}

done_testing;
