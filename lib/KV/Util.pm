package KV::Util;

use strict;
use warnings;
use Time::HiRes;

use constant MONOTONIC => eval { !!Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) };

my $NAME = sub { $_[1] };

sub monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
}

monkey_patch(__PACKAGE__, 'steady_time',
  MONOTONIC ? sub () { Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) } : \&Time::HiRes::time);

1;