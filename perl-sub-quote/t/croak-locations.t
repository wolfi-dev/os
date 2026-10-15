use strict;
use warnings;
use Test::More;
use lib 't/lib';
use ErrorLocation;

location_ok <<'END_CODE', 'Sub::Defer::defer_sub - unqualified name';
use Sub::Defer qw(defer_sub);
defer_sub 'welp' => sub { sub { 1 } };
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::quote_sub - long package';
use Sub::Quote qw(quote_sub);
quote_sub +("x" x 500).'::x', '1';
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::unquote_sub - bad captures';
use Sub::Quote qw(unquote_sub quote_sub);
unquote_sub quote_sub '1', { '&foo' => sub { 1 } };
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::unquote_sub - compile error';
use Sub::Quote qw(unquote_sub quote_sub);
unquote_sub quote_sub ' { ] } ';
END_CODE

done_testing;
