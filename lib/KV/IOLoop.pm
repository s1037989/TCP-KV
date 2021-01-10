package KV::IOLoop;

use strict;
use warnings;
use Time::HiRes;

use constant DEBUG => $ENV{KV_IOLOOP_DEBUG} || 0;

sub emit {
  my ($self, $event) = (shift, shift);
  my $cb = $self->{on}->{$event};
  $cb = $_->$cb($self, @_) for $self->{kv};
  return $cb;
}

sub new {
  my $class = shift;
  my $self = {kv => @_};
  $self = bless $self, $class;
  $self->on(exit => sub {
    my ($kv, $sig) = @_;
    my %sig = (EXIT => 0, HUP => 1, INT => 2, QUIT => 3, ABRT => 6, KILL => 9, TERM => 15);
    $kv->kill->kill;
    exit 0 unless $sig;
    my $exit = $sig =~ /^\d+$/ ? $sig : $sig{$sig} || 255;
    exit $exit;
  });
  return $self;
}

sub on {
  my ($self, $event, $cb) = @_;
  $self->{on}->{$event} = $cb;
}

sub recurring {
  my $self = shift;
  my $id = ++$self->{_timer_id};
  $self->{timers}->{$id}->{timer} = shift;
  $self->{timers}->{$id}->{cb} = shift;
  return $id;
}

sub sleep {
  my $self = shift;
  return unless $self->{_running};
  my ($min) = pop() || sort { $a <=> $b } map { $self->{timers}->{$_}->{timer} } keys %{$self->{timers}};
  $min *= 0.9 if $min;
  $min ||= 0.1;
  Time::HiRes::usleep($min * 1_000_000);
}

sub start {
  my $self = shift;
  return if $self->{_running};
  $self->{_running} = 1;
  while ($self->sleep) {
    $self->_recurring($_) for sort { $a <=> $b } keys $self->{timers}->%*;
  }
  delete $self->{_running};
}

sub stop { delete shift->{_running} }

sub _recurring {
  my ($self, $id) = @_;
  my $steady_time = KV::Util::steady_time();
  my ($timer, $cb) = ($self->{timers}->{$id}->{timer}, $self->{timers}->{$id}->{cb});
  $self->{timers}->{$id}->{last} ||= $steady_time;
  return undef unless $steady_time - $self->{timers}->{$id}->{last} >= $timer;
  $self->{timers}->{$id}->{last} = $steady_time;
  $cb = $_->$cb($self) for $self->{kv};
  return $cb;
}

1;