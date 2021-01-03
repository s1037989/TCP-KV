package KV;

use 5.010;
use strict;
use warnings;

use KV::IOLoop;
use KV::Pids;
use KV::Server;
use KV::Store;
use KV::Util;

use sigtrap 'handler' => \&sig_exit, qw(INT TERM KILL QUIT ABRT HUP);

use constant DEBUG => sub { $ENV{KV_DEBUG} || 0 };

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->server;
  $self->ioloop->recurring($self->{minimal} => \&_minimal)
    if $self->{minimal};
  return $self;
}

sub die { state $die = KV::Pids->new(shift, die => @_) }

sub ioloop { state $ioloop = KV::IOLoop->new(@_) }

sub kill { state $kill = KV::Pids->new(shift, kill => @_) }

sub server { state $server = KV::Server->new(@_) }

sub sig_exit { __PACKAGE__->ioloop->emit(exit => pop) }

sub store { state $store = KV::Store->new(@_) }

sub _minimal {
  my $kv = shift;
  my $die = $kv->die;
  my $kill = $kv->kill;
  my $server = $kv->server;
  my $store = $kv->store;
  my $buffer = $server->recv or return;
  if ($buffer =~ /^!(\w*)$/) {
    $server->send($store->flush($1));
  }
  elsif ($buffer =~ /^!!$/ ) {
    $server->send($store->flushall);
  }
  elsif ($buffer eq '#') {
    $server->send($store->list(':'));
  }
  elsif ($buffer =~ /^>(\d*)$/) {
    $kill->remove($1) or $kill->add($1) if $1;
    $server->send($kill->pids(':'));
  }
  elsif ($buffer =~ /^<(\d*)$/) {
    $die->remove($1) or $die->add($1) if $1;
    $server->send($die->pids(':'));
  }
  elsif ($buffer =~ /^(\w+)=(.*?)$/) {
    $server->send($store->set($1 => $2));
  }
  elsif ($buffer =~ /^(\w+)$/) {
    $server->send($store->get($1));
  }
  $server->shutdown(1);
}

1;