use strict;
use warnings;
use Test::More;
BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
        unless $ENV{RELEASE_TESTING};
}

use CPAN::Meta;
use Test::Kwalitee 'kwalitee_ok';

my ($meta_file) = grep -e, qw(MYMETA.json MYMETA.yml META.json META.yml)
  or die "unable to find MYMETA or META file!";

my $meta = CPAN::Meta->load_file($meta_file)->as_struct;
my @ignore = keys %{$meta->{x_cpants}{ignore}};

kwalitee_ok(map "-$_", @ignore);
done_testing;
