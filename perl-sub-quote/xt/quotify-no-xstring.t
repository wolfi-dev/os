use strict;
use warnings;
no warnings 'once';
unshift @ARGV, '--no-xstring';
do './t/quotify.t' or die $@ || $!;
