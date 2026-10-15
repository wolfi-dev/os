use strict;
use warnings;
no warnings 'once';
unshift @ARGV, '--b-perlstring';
do './t/quotify.t' or die $@ || $!;
