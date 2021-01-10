package KV::Plugin::pipes;
use parent 'KV::Plugin';

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use File::Basename;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub run {
  my ($self, $kv, $conn, $buffer) = @_;
  if ($buffer =~ /^\|(\d+)$/) {
    return $conn->send($kv->pipes->mkfifo($1));
  }
  elsif ($buffer eq '$$') {
    return $conn->send($kv->pipes->{pipes}->{$kv->pipes->{active_fh}}->{pid});
  }
}

1;