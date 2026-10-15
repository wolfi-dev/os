package ErrorLocation;
use strict;
use warnings;
use Test::Builder;
use Carp qw(croak);
use Exporter 'import';

our @EXPORT = qw(location_ok);

my $builder = Test::Builder->new;

my $gen = 'A000';
sub location_ok ($$) {
  my ($code, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($pre) = $code =~ /\A(.*?)(?:## fail\n.*)?\n?\z/s;
  my $fail_line = 1 + $pre =~ tr/\n//;
  my $PACKAGE = "LocationTest::_".++$gen;
  my $sub = eval qq{ sub {
package $PACKAGE;
#line 1 LocationTestFile
$code
  } };
  my $full_trace;
  my $last_location;
  my $immediate;
  my $trace_capture = sub {
    my @c = caller;
    my ($location) = $_[0] =~ /^.* at (.*? line \d+)\.?$/;
    $location ||= sprintf "%s line %s", (caller(0))[1,2];
    if (!$last_location || $last_location ne $location) {
      $last_location = $location;
      $immediate = $c[1] eq 'LocationTestFile';
      {
        local %Carp::Internal;
        local %Carp::CarpInternal;
        $full_trace = Carp::longmess('');
      }
      $full_trace =~ s/\A.*\n//;
      $full_trace =~ s/^\t//mg;
      $full_trace =~ s/^[^\n]+ called at ${\__FILE__} line [0-9]+\n.*//ms;
      if ($c[0] eq 'Carp') {
        $full_trace =~ s/.*?(^Carp::)/$1/ms;
      }
      else {
        my ($arg) = @_;
        $arg =~ s/\Q at $c[1] line $c[2]\E\.\n\z//;
        my $caller = 'CORE::die(' . Carp::format_arg($arg) . ") called at $location\n";
        $full_trace =~ s/\A.*\n/$caller/;
      }
      $full_trace =~ s{^(.* called at )(\(eval [0-9]+\)(?:\[[^\]]*\])?) line ([0-9]+)\n}{
        my ($prefix, $file, $line) = ($1, $2, $3);
        my $i = 0;
        while (my @c = caller($i++)) {
          if ($c[1] eq $file && $c[2] eq $line) {
            $file .= "[$c[0]]";
            last;
          }
        }
        "$prefix$file line $line\n";
      }meg;
      $full_trace =~ s/^/    /mg;
    }
  };
  croak "$name - compile error: $@"
    if !$sub;
  local $@;
  eval {
    local $Carp::Verbose = 0;
    local $SIG{__WARN__};
    local $SIG{__DIE__} = $trace_capture;
    $sub->();
    1;
  } and croak "$name - code did not fail!";
  croak "died directly in test code: $@"
    if $immediate;
  delete $LocationTest::{"_$gen"};
  my ($location) = $@ =~ /.* at (.*? line \d+)\.?$/;
  $builder->is_eq($location, "LocationTestFile line $fail_line", $name)
    or $builder->diag("  error:\n    $@\n  full trace:\n$full_trace"), return !1;
}

1;
