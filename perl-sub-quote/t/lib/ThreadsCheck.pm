package ThreadsCheck;
use strict;
use warnings;
no warnings 'once';

sub _skip {
  print "1..0 # SKIP $_[0]\n";
  exit 0;
}

sub import {
  my ($class, $op) = @_;
  require Config;
  if (! $Config::Config{useithreads}) {
    _skip "your perl does not support ithreads";
  }
  elsif (system "$^X", __FILE__, 'installed') {
    _skip "threads.pm not installed";
  }
  elsif (system "$^X", __FILE__, 'create') {
    _skip "threads are broken on this machine";
  }
}

if (!caller && @ARGV) {
  my ($op) = @ARGV;
  require POSIX;
  if ($op eq 'installed') {
    eval { require threads } or POSIX::_exit(1);
  }
  elsif ($op eq 'create') {
    require threads;
    require File::Spec;
    open my $olderr, '>&', \*STDERR
      or die "can't dup filehandle: $!";
    open STDERR, '>', File::Spec->devnull
      or die "can't open null: $!";
    my $out = threads->create(sub { 1 })->join;
    open STDERR, '>&', $olderr;
    POSIX::_exit((defined $out && $out eq '1') ? 0 : 1);
  }
  else {
    die "Invalid option $op!\n";
  }
  POSIX::_exit(0);
}

1;
