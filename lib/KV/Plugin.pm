package KV::Plugin;

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub new { my $class = shift; bless {@_}, $class }

1;
