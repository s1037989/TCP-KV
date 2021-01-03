use 5.010;
use strict;
use warnings;

use Test::More;

use KV;
use Time::HiRes qw(time);

$| = 1;

my $kv = KV->new;

my $c = 0;
$kv->ioloop->recurring(0.10 => sub { $c = 1; shift->ioloop->stop });
my $timer_a = time;
$kv->ioloop->start;
my $timer_b = time;

is $c, 1;
ok (($timer_b - $timer_a) > 0.10);

done_testing;