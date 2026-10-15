use strict;
use warnings;
use Test::More;
use Sub::Defer qw(defer_sub undefer_sub undefer_all undefer_package defer_info);
use Scalar::Util qw(refaddr weaken);

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' }
};

my $two_defer = defer_sub 'Foo::two' => sub {
  die "remade - wtf" if $made{'Foo::two'};
  $made{'Foo::two'} = sub { 'two' }
};

is($one_defer, \&Foo::one, 'one defer installed');
is($two_defer, \&Foo::two, 'two defer installed');

is($one_defer->(), 'one', 'one defer runs');

is($made{'Foo::one'}, \&Foo::one, 'one made');

is($made{'Foo::two'}, undef, 'two not made');

is($one_defer->(), 'one', 'one (deferred) still runs');

is(Foo->one, 'one', 'one (undeferred) runs');

my $e;
eval { defer_sub 'welp' => sub { sub { 1 } }; 1 } or $e = $@;
like $e,
  qr/^welp is not a fully qualified sub name!/,
  'correct error for defer_sub with unqualified name';

is(my $two_made = undefer_sub($two_defer), $made{'Foo::two'}, 'make two');

undef $e;
eval { undefer_sub($two_defer); 1 } or $e = $@;
is $e, undef,
  "repeated undefer doesn't regenerate";

is($two_made, \&Foo::two, 'two installed');

is($two_defer->(), 'two', 'two (deferred) still runs');

is($two_made->(), 'two', 'two (undeferred) runs');

my $three = sub { 'three' };

is(undefer_sub($three), $three, 'undefer non-deferred is a no-op');

my $four_defer = defer_sub 'Foo::four' => sub {
  sub { 'four' }
};
is($four_defer, \&Foo::four, 'four defer installed');

my $unnamed_defer = defer_sub undef ,=> sub {
  die 'remade - wtf' if $made{'unnamed'};
  $made{'unnamed'} = sub { 'dwarg' };
};
my $unnamed_result = $unnamed_defer->();
ok $made{'unnamed'}, 'unnamed deferred subs generate subs';
is $unnamed_result, 'dwarg', 'unnamed deferred subs call generated sub properly';

# somebody somewhere wraps up around the deferred installer
no warnings qw/redefine/;
my $orig = Foo->can('four');
*Foo::four = sub {
  $orig->() . ' with a twist';
};

is(Foo->four, 'four with a twist', 'around works');
is(Foo->four, 'four with a twist', 'around has not been destroyed by first invocation');

my $one_all_defer = defer_sub 'Foo::one_all' => sub {
  $made{'Foo::one_all'} = sub { 'one_all' }
};

my $two_all_defer = defer_sub 'Foo::two_all' => sub {
  $made{'Foo::two_all'} = sub { 'two_all' }
};

is( $made{'Foo::one_all'}, undef, 'one_all not made' );
is( $made{'Foo::two_all'}, undef, 'two_all not made' );

undefer_all();

is( $made{'Foo::one_all'}, \&Foo::one_all, 'one_all made by undefer_all' );
is( $made{'Foo::two_all'}, \&Foo::two_all, 'two_all made by undefer_all' );

defer_sub 'Bar::one' => sub {
  $made{'Bar::one'} = sub { 'one' }
};
defer_sub 'Bar::two' => sub {
  $made{'Bar::two'} = sub { 'two' }
};
defer_sub 'Bar::Baz::one' => sub {
  $made{'Bar::Baz::one'} = sub { 'one' }
};

undefer_package('Bar');

is( $made{'Bar::one'}, \&Bar::one, 'one made by undefer_package' );
is( $made{'Bar::two'}, \&Bar::two, 'two made by undefer_package' );

is( $made{'Bar::Baz::one'}, undef, 'sub-package not undefered by undefer_package' );

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  undef $foo;

  is defer_info($foo_string), undef,
    "deferred subs don't leak";

  Sub::Defer->CLONE;
  ok !exists $Sub::Defer::DEFERRED{$foo_string},
    'CLONE cleans out expired entries';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  Sub::Defer->CLONE;
  undef $foo;

  is defer_info($foo_string), undef,
    "CLONE doesn't strengthen refs";
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  my $foo_info = defer_info($foo_string);
  undef $foo;

  my $e;
  eval { Sub::Defer->CLONE; 1 } or $e = $@;
  is $e, undef,
    'CLONE works when quoted info saved externally';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  my $foo_info = $Sub::Defer::DEFERRED{$foo_string};
  undef $foo;

  my $e;
  eval { Sub::Defer->CLONE; 1 } or $e = $@;
  is $e, undef,
    'CLONE works when quoted info kept alive externally';
  ok !exists $Sub::Defer::DEFERRED{$foo_string},
    'CLONE removes expired entries that were kept alive externally';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  undef $foo;
  Sub::Defer::undefer_package 'Unused';
  my $e;
  eval { undefer_sub $foo_string; 1 } or $e = $@;
  is $e, undef,
    "undeferring expired sub (or reused refaddr) after undefer_package lives";
}

{
  my $foo;
  my $sub = defer_sub undef, sub { +sub :lvalue { $foo } }, { attributes => [ 'lvalue' ]};
  $sub->() = 'foo';
  is $foo, 'foo', 'attributes are applied to deferred subs';
}

{
  my $error;
  eval {
    my $sub = defer_sub undef, sub { sub { "gorf" } }, { attributes => [ 'oh boy' ] };
    1;
  } or $error = $@;
  like $error, qr/invalid attribute/,
    'invalid attributes are rejected';
}

{
  my $guff;
  my $deferred = defer_sub "Foo::flub", sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  my $undeferred_addr = refaddr($undeferred);
  my $deferred_str = "$deferred";
  weaken($deferred);

  is $deferred, undef,
    'no strong external refs kept for deferred named subs';

  is defer_info($deferred_str), undef,
    'defer_info on expired deferred named sub gives undef';

  isnt refaddr(undefer_sub($deferred_str)), $undeferred_addr,
    'undefer_sub on expired deferred named sub does not give undeferred sub';

  is refaddr(undefer_sub($undeferred)), $undeferred_addr,
    'undefer_sub on undeferred named sub after deferred expiry gives undeferred';
}

{
  my $guff;
  my $deferred = defer_sub undef, sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  my $undeferred_addr = refaddr($undeferred);
  my $deferred_str = "$deferred";
  my $undeferred_str = "$undeferred";
  weaken($deferred);

  is $deferred, undef,
    'no strong external refs kept for deferred unnamed subs';

  is defer_info($deferred_str), undef,
    'defer_info on expired deferred unnamed sub gives undef';

  isnt refaddr(undefer_sub($deferred_str)), $undeferred_addr,
    'undefer_sub on expired deferred unnamed sub does not give undeferred sub';

  is refaddr(undefer_sub($undeferred)), $undeferred_addr,
    'undefer_sub on undeferred unnamed sub after deferred expiry gives undeferred';
}

{
  my $guff;
  my $deferred = defer_sub "Foo::gwarf", sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  my $undeferred_addr = refaddr($undeferred);
  my $deferred_str = "$deferred";
  my $undeferred_str = "$undeferred";
  delete $Foo::{gwarf};

  weaken($deferred);
  weaken($undeferred);

  is $undeferred, undef,
    'no strong external refs kept for undeferred named subs';

  is defer_info($undeferred_str), undef,
    'defer_info on expired undeferred named sub gives undef';

  isnt refaddr(undefer_sub($undeferred_str)), $undeferred_addr,
    'undefer_sub on expired undeferred named sub does not give undeferred sub';
}

{
  my $guff;
  my $deferred = defer_sub undef, sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  my $undeferred_addr = refaddr($undeferred);
  my $deferred_str = "$deferred";
  my $undeferred_str = "$undeferred";

  weaken($deferred);
  weaken($undeferred);

  is $undeferred, undef,
    'no strong external refs kept for undeferred unnamed subs';

  is defer_info($undeferred_str), undef,
    'defer_info on expired undeferred unnamed sub gives undef';

  isnt refaddr(undefer_sub($undeferred_str)), $undeferred_addr,
    'undefer_sub on expired undeferred unnamed sub does not give undeferred sub';
}

{
  my $guff;
  my $deferred = defer_sub undef, sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  weaken($deferred);

  ok defer_info($undeferred),
    'defer_info still returns info for undeferred unnamed subs after deferred sub expires';
}

{
  my $guff;
  my $deferred = defer_sub undef, sub { sub { $guff } };
  my $undeferred = undefer_sub($deferred);
  weaken($deferred);

  Sub::Defer->CLONE;

  ok defer_info($undeferred),
    'defer_info still returns info for undeferred unnamed subs after deferred sub expires and CLONE';
}

{
  my $guff;
  my $gen = sub { +sub :lvalue { $guff } };
  my $deferred = defer_sub 'Foo::blorp', $gen,
    { attributes => [ 'lvalue' ] };

  is_deeply defer_info($deferred),
    [ 'Foo::blorp', $gen, { attributes => [ 'lvalue' ] } ],
    'defer_info gives name, generator, options before undefer';

  my $undeferred = undefer_sub $deferred;

  is_deeply defer_info($deferred),
    [ 'Foo::blorp', $gen, { attributes => [ 'lvalue' ] }, $undeferred ],
    'defer_info on deferred gives name, generator, options after undefer';

  is_deeply defer_info($undeferred),
    [ 'Foo::blorp', $gen, { attributes => [ 'lvalue' ] }, $undeferred ],
    'defer_info on undeferred gives name, generator, options after undefer';
}

is defer_info(undef), undef, 'defer_info on undef gives undef';

{
  my $x;
  my $sub = sub {
    $x++;
    (caller(0))[3];
  };
  Sub::Defer::_install_coderef('Blorp::foo', 'Farg::foo', $sub);
  is \&Blorp::foo, $sub,
    '_install_coderef properly installs subs';

  SKIP: {
    skip 'no sub naming module available', 1
      unless Sub::Defer::_CAN_SUBNAME;

    is Blorp::foo(), 'Farg::foo',
      '_install_coderef properly names subs';
  }
  my $sub2 = sub {
    $x++;
    (caller(0))[3];
  };
  Sub::Defer::_install_coderef('Blorp::foo', 'Farg::foo', $sub2);
  is \&Blorp::foo, $sub2,
    '_install_coderef properly replaces subs';
}

{
  my $x;
  my $sub = sub { $x = 1; sub { $x } };
  my $deferred = defer_sub undef, $sub;
  my $info = $Sub::Defer::DEFERRED{$deferred};
  undef $deferred;
  # simulate reused memory address
  @{$Sub::Defer::DEFERRED{$sub}} = @$info;
  undefer_sub($sub);
  is $x, undef,
    'undefer_sub does not operate on non-deferred sub with reused memory address';
}

done_testing;
