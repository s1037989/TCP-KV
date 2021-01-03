package KV::Store;

use strict;
use warnings;
use File::Path qw(make_path);

use constant DEBUG => sub { $ENV{KV_STORE_DEBUG} || 0 };

sub def_get {
  my ($self, $k) = @_;
  $k = "_$k" if $self->{hidden};
  open A, $self->file("$k.def") or return;
  my $v = <A>;
  CORE::close A;
  return $v;
}

sub def_set {
  my ($self, $k, $v) = @_;
  $k = "_$k" if $self->{hidden};
  open A, '>'.$self->file("$k.def") or return;
  print A $v if $v;
  CORE::close A;
  return $v;
}

sub file { sprintf '%s/%s', shift->{path}, shift }

sub file_get {
  my ($self, $k) = @_;
  $k = "_$k" if $self->{hidden};
  open A, $self->file($k) or return;
  my $v = <A>;
  CORE::close A;
  return $v;
}

sub file_set {
  my ($self, $k, $v) = @_;
  $k = "_$k" if $self->{hidden};
  open A, '>'.$self->file($k) or return;
  print A $v if $v;
  CORE::close A;
  return $v;
}

sub flush {
  my $self = shift;
  my $k = shift || '*';
  unlink $_ or return for grep { !/\b_/ } glob($self->file($k));
  return $k;
}

sub flushall {
  my $self = shift;
  my $k = '*';
  unlink $_ or return for glob($self->file($k));
  return $k;
}

sub get {
  my ($self, $k) = @_;
  my $v = $self->file_get($k) || $self->def_get($k);
  $self->{hidden} = 0;
  return $v;
}

sub hidden {
  my $self = shift;
  $self->{hidden} = shift // 1;
  return $self;
}

sub list {
  join pop, grep { !/\b_/ } glob(shift->file('*'));
}

sub new {
  my $class = shift;
  my $self = {kv => @_};
  $self->{root} ||= '/dev/shm/tcp-kv';
  $self->{root} =~ s/\/$//;
  $self->{root} or CORE::die "root not defined";
  $self->{path} ||= '';
  $self->{path} =~ s/^\/|\/$//g;
  $self->{path} = join '/', $self->{root}, $self->{path};
  make_path($self->{path});
  return bless $self, $class;
}

sub set {
  my ($self, $k, $v) = @_;
  $self->def_set($k => $v) unless -e $self->file("$k.def");
  $self->file_set($k => $v);
  $self->{hidden} = 0;
  return $v;
}

1;