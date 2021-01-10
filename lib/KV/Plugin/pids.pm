package KV::Plugin::pids;
use parent 'KV::Plugin';

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub run {
  my ($self, $kv, $conn, $buffer) = @_;
  if ($buffer =~ /^>(\d*)$/) {
    $kv->kill->remove($1) or $kv->kill->add($1) if $1;
    return $conn->send($kv->kill->pids(':'));
  }
  elsif ($buffer =~ /^<(\d*)$/) {
    $kv->die->remove($1) or $kv->die->add($1) if $1;
    return $conn->send($kv->die->pids(':'));
  }
  elsif ($buffer =~ /^<>(\d*)$/) {
    return if $1 && $1 == $$;
    $kv->killgroup->remove($1) or $kv->killgroup->add($1) if $1;
    return $conn->send($kv->killgroup->pids(':'));
  }
}

1;