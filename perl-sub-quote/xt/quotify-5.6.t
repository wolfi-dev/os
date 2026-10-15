use strict;
use warnings;
no warnings 'once';
unshift @ARGV, '--5_6';
do './t/quotify.t' or die $@ || $!;
