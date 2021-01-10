package KV::Server;
use parent 'KV::Connection';

use strict;
use warnings;
use IO::Socket::INET;
use Data::Dumper;

use constant DEBUG => $ENV{KV_SERVER_DEBUG} || 0;

sub new {
  my $class = shift;
  my $self = {kv => @_};
  $self->{iosocket} = IO::Socket::INET->new(
    LocalHost => '127.0.0.1',
    LocalPort => '7777',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1,
    Blocking => 0,
  ) or die "cannot create socket $!\n";
  print "server waiting for client connections on port 7777\n" if DEBUG;
  return bless $self, $class;
}

sub recv {
  my $self = shift;
  my $io = $self->{iosocket};

  my $socket = $self->{socket} = $io->accept or return;
  $self->{address} = $socket->peerhost;
  $self->{port} = $socket->peerport;

  my $buffer;
  $socket->recv($buffer, 1024);
  chomp($buffer);
  print "\rreceive from $self->{address}:$self->{port}: $buffer\n" if DEBUG;
  return $buffer;
}

sub send {
  my $self = shift;
  my $socket = $self->{socket} or return;
  print "\rsend to $self->{address}:$self->{port}: @_\n" if DEBUG;
  $socket->send(@_);
  return $self;
}

sub shutdown {
  my $self = shift;
  my $socket = $self->{socket} or return;
  CORE::shutdown($socket, @_);
}

sub DESTROY { shift->{iosocket}->close }

1;