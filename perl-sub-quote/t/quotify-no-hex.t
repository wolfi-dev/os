use strict;
use warnings;
no warnings 'once';
unshift @ARGV, '--no-hex';
do './t/quotify.t' or die $@ || $!;
