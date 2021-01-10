package KV::Plugin::rand;
use parent 'KV::Plugin';

use 5.010;
use strict;
use warnings;

use constant DEBUG => $ENV{KV_PLUGIN_DEBUG} || 0;

sub run {
  my ($self, $kv, $conn, $buffer) = @_;
  $conn->send($self->_rand($buffer));
}

sub _rand {
  my $self = shift;
  my $i = shift || '';
  return $self->{rand} if $i eq '-';
  $i = $i ? int($i) : length($i);
  $self->{rand} = join "", int(rand(9)+1)*($i?1:0), map { int(rand(10)) } (0..($i||0)-2);
}

1;