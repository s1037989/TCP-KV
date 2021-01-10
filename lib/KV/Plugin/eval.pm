package KV::Plugin::eval;
use parent 'KV::Plugin';

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub run {
  my ($self, $kv, $conn, $buffer) = @_;
  return if ref $conn eq 'KV::Server';
  if ($buffer =~ /^#(\w+)(\s+(.*?))$/) {
    return $conn->send($kv->store->get($1)) unless $3;
    local $_ = $kv->store->get($1);
    my $eval = CORE::eval "$3";
    print "EVAL $eval\n" if DEBUG;
    return $conn->send($kv->store->set($1 => $eval));
  }
  else {
    local $_ = $self->{eval};
    my $eval = CORE::eval "$buffer";
    $self->{eval} = $eval;
    print "EVAL $eval\n" if DEBUG;
    return $conn->send($eval);
  }
}

1;