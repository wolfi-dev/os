BEGIN {
  %^H = ();
  my %clear_hints = sub { %{(caller(0))[10]||{}} }->();
  $INC{'ClearHintsHash.pm'} = __FILE__;
  package ClearHintsHash;
  sub hints { %clear_hints }
  sub import {
    $^H |= 0x020000;
    %^H = hints;
  }
}

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
  use strict;
  no strict 'subs';
  local $TODO = "hints from caller not available on perl < 5.8"
    if "$]" < 5.008_000;

  my $e;
  eval { quote_sub(q{ my $f = SomeBareword; ${"string_ref"} })->(); 1 } or $e = $@;
  like $e,
    qr/strict refs/,
    'hints preserved from context';
}

{
  my $hints;
  {
    use strict;
    no strict 'subs';
    BEGIN { $hints = $^H }
  }
  my $e;
  eval { quote_sub(q{ my $f = SomeBareword; ${"string_ref"} }, {}, { hints => $hints })->(); 1 } or $e = $@;
  like $e,
    qr/strict refs/,
    'hints used from options';
}

{
  my $sub = do {
    no warnings;
    unquote_sub quote_sub(q{ 0 + undef });
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $sub->();
  is scalar @warnings, 0,
    '"no warnings" preserved from context';
}

{
  my $sub = do {
    no warnings;
    use warnings;
    unquote_sub quote_sub(q{ 0 + undef });
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $sub->();
  like $warnings[0],
    qr/uninitialized/,
    '"use warnings" preserved from context';
}

{
  my $warn_bits;
  eval q{
    use warnings FATAL => 'uninitialized';
    BEGIN { $warn_bits = ${^WARNING_BITS} }
    1;
  } or die $@;
  no warnings 'uninitialized';
  my $e;
  eval { quote_sub(q{ 0 + undef }, {}, { warning_bits => $warn_bits })->(); 1 } or $e = $@;
  like $e,
    qr/uninitialized/,
    'warnings used from options';
}

BEGIN {
  package UseHintHash;
  $INC{'UseHintHash.pm'} = 1;

  sub import {
    $^H |= 0x020000;
    $^H{__PACKAGE__.'/enabled'} = 1;
  }
}

{
  my %hints;
  {
    use ClearHintsHash;
    use UseHintHash;
    BEGIN { %hints = %^H }
  }

  {
    local $TODO = 'hints hash from context not available on perl 5.8'
      if "$]" < 5.010_000;

    use ClearHintsHash;
    use UseHintHash;
    is_deeply quote_sub(q{
      our %temp_hints_hash;
      BEGIN { %temp_hints_hash = %^H }
      \%temp_hints_hash;
    })->(), \%hints,
      'hints hash preserved from context';
  }

  is_deeply quote_sub(q{
    our %temp_hints_hash;
    BEGIN { %temp_hints_hash = %^H }
    \%temp_hints_hash;
  }, {}, { hintshash => \%hints })->(), \%hints,
    'hints hash used from options';
}

{
  use ClearHintsHash;
  my $sub = quote_sub(q{
    our %temp_hints_hash;
    BEGIN { %temp_hints_hash = %^H }
    \%temp_hints_hash;
  });
  my $wrap_sub = do {
    use UseHintHash;
    my (undef, $code, $cap) = @{quoted_from_sub($sub)};
    quote_sub $code, $cap||();
  };
  is_deeply $wrap_sub->(), { ClearHintsHash::hints },
    'empty hints maintained when inlined';
}

BEGIN {
  package BetterNumbers;
  $INC{'BetterNumbers.pm'} = 1;
  use overload ();

  sub import {
    my ($class, $add) = @_;
    # closure vs not
    if (defined $add) {
      overload::constant 'integer', sub { $_[0] + $add };
    }
    else {
      overload::constant 'integer', sub { $_[0] + 1 };
    }
  }
}

TODO: {
  my ($options, $context_sub, $direct_val);
  {
    use BetterNumbers;
    BEGIN { $options = { hints => $^H, hintshash => { %^H } } }
    $direct_val = 10;
    $context_sub = quote_sub(q{ 10 });
  }
  my $options_sub = quote_sub(q{ 10 }, {}, $options);

  is $direct_val, 11,
    'integer overload is working';

  todo_skip "refs in hints hash not yet implemented", 4;
  {
    my $context_val;
    my $e;
    eval { $context_val = $context_sub->(); 1 } or $e = $@;
    is $e, undef,
      'hints hash refs from context not broken';
    local $TODO = 'hints hash from context not available on perl 5.8'
      if !$TODO && "$]" < 5.010_000;
    is $context_val, 11,
      'hints hash refs preserved from context';
  }

  {
    my $options_val;
    my $e;
    eval { $options_val = $options_sub->(); 1 } or $e = $@;
    is $e, undef,
      'hints hash refs from options not broken';
    is $options_val, 11,
      'hints hash refs used from options';
  }
}

TODO: {
  my ($options, $context_sub, $direct_val);
  {
    use BetterNumbers +2;
    BEGIN { $options = { hints => $^H, hintshash => { %^H } } }
    $direct_val = 10;
    $context_sub = quote_sub(q{ 10 });
  }
  my $options_sub = quote_sub(q{ 10 }, {}, $options);

  is $direct_val, 12,
    'closure integer overload is working';

  todo_skip "refs in hints hash not yet implemented", 4;

  {
    my $context_val;
    my $e;
    eval { $context_val = $context_sub->(); 1 } or $e = $@;
    is $e, undef,
      'hints hash closure refs from context not broken';
    local $TODO = 'hints hash from context not available on perl 5.8'
      if !$TODO && "$]" < 5.010_000;
    is $context_val, 12,
      'hints hash closure refs preserved from context';
  }

  {
    my $options_val;
    my $e;
    eval { $options_val = $options_sub->(); 1 } or $e = $@;
    is $e, undef,
      'hints hash closure refs from options not broken';
    is $options_val, 12,
      'hints hash closure refs used from options';
  }
}

done_testing;
