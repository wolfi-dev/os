use strict;
use warnings;
no warnings 'once';
unshift @ARGV, '--5_10_0';
do './t/quotify.t' or die $@ || $!;
