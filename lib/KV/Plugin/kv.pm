package KV::Plugin::kv;
use parent 'KV::Plugin';

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub run {
  my ($self, $kv, $conn, $buffer) = @_;
  if ($buffer =~ /^!(\w*)$/) {
    print "flush $1\n" if DEBUG;
    return $conn->send($kv->store->flush($1));
  }
  elsif ($buffer =~ /^!!$/ ) {
    print "flushall\n" if DEBUG;
    return $conn->send($kv->store->flushall);
  }
  elsif ($buffer eq '#') {
    print "list\n" if DEBUG;
    return $conn->send($kv->store->list(':'));
  }
  elsif ($buffer =~ /^(\w+)=(.*?)$/) {
    print "assignment $1 => $2\n" if DEBUG;
    return $conn->send($kv->store->set($1 => $2));
  }
  elsif ($buffer =~ /^(\w+)$/) {
    my $f = $kv->store->get($1);
    print "fetch $1 => $f\n" if DEBUG;
    return $conn->send($kv->store->get($1));
  }
}

1;