package KV::Pids;

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PIDS_DEBUG} || 0;

sub add {
  my ($self, @pids) = @_;
  my $kv = $self->{kv};
  my $type = $self->{type};
  $kv->ioloop->{pids} = $kv->ioloop->recurring(0.25 => sub { $_->kill->ping or $_->killgroup->kill; $_->die->ping or $_->ioloop->emit('exit') })
    unless $kv->ioloop->{ping};
  my %pids = map { $_ => 1 } @pids, $self->pids;
  if (keys %pids != $self->pids ) {
    $kv->store->hidden->set($type => join ':', keys %pids);
    return 1;
  }
  else {
    return 0;
  }
}

sub kill {
  my $self = shift;
  $self->remove($_) and CORE::kill 15, $_ for $self->pids;
}

sub new {
  my $class = shift;
  my $self = {kv => shift, type => shift, pids => []};
  bless $self, $class;
}

sub pids {
  my ($self, $delim) = @_;
  my $kv = $self->{kv};
  my $type = $self->{type};
  my @pids = split /:/, ($kv->store->hidden->get($type) || '');
  $delim ? join($delim, @pids) : @pids;
}

sub ping {
  my $self = shift;
  my @pids = $self->pids;
  CORE::kill 0, $_ or $self->remove($_) for $self->pids;
  return $self->pids == @pids ? 1 : 0;
}

sub remove {
  my ($self, @pids) = @_;
  my $kv = $self->{kv};
  my $type = $self->{type};
  my %pids = map { $_ => 1 } $self->pids;
  delete $pids{$_} for @pids;
  if (keys %pids != $self->pids ) {
    $kv->store->hidden->set($type => join ':', keys %pids);
    return 1;
  }
  else {
    return 0;
  }
}

1;