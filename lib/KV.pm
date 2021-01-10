package KV;

use 5.010;
use strict;
use warnings;

use KV::IOLoop;
use KV::Pids;
use KV::Pipes;
use KV::Server;
use KV::Store;
use KV::Util;

use sigtrap 'handler' => \&sig_exit, qw(INT TERM KILL QUIT ABRT HUP);

use constant DEBUG => $ENV{KV_DEBUG} || 0;

# my $kv = KV->new(0.01 => ['eval']);
sub new {
  my ($class, $timer, $funcs) = (shift, shift, shift);
  my $self = bless {@_}, $class;
  $self->pipes;
  $self->server;
  $self->store(path => $self->{path});
  return $self;
}

sub die { state $die = KV::Pids->new(shift, die => @_) }

sub ioloop { state $ioloop = KV::IOLoop->new(@_) }

sub kill { state $kill = KV::Pids->new(shift, kill => @_) }

sub killgroup { state $killgroup = KV::Pids->new(shift, killgroup => @_) }

sub plugin {
  my ($self, $name, $cb) = @_;
  return $self if $self->{plugins}->{$name} && !$cb;
  my $class = "KV::Plugin::$name";
  if ($cb) {
    eval "package $class; use parent 'KV::Plugin'; *run = \$cb; 1;";
  }
  else {
    $class->can('new') || eval "require $class; 1";
  }
  my $plugin = $class->new or return $self;
  $self->{plugins}->{$name} = $plugin;
  return $self;
}

sub pipes { state $pipes = KV::Pipes->new(@_) }

sub server { state $server = KV::Server->new(@_) }

sub sig_exit { __PACKAGE__->ioloop->emit(exit => pop) }

sub start {
  my ($self, $timer, $plugins) = @_;
  $self->plugin($_) for @$plugins;
  $self->ioloop->recurring($timer => sub { shift->_plugin(@$plugins) });
  $self->ioloop->start;
}

sub store { state $store = KV::Store->new(@_) }

sub _plugin {
  my ($self, @plugins) = @_;
  my ($buffer, $h) = $self->server->recv || $self->pipes->recv or return;
  chomp($buffer);
  my $conn = $h ? $self->pipes->fh($h) : $self->server;
  printf "%s BUFFER: %s\n", ref $conn, substr($buffer, 0, 40) if DEBUG > 1;
  return unless $conn && $buffer;
  my $plugins_re = join '|', @plugins;
  $buffer =~ s/^($plugins_re)\s+// or return $conn->send('');
  local $_ = $1;
  printf ("%s %s BUFFER: %s\n", $_, ref $conn, substr($buffer, 0, 40)) if DEBUG;
  $self->{plugins}->{$_}->run($self, $conn, $buffer)->isa('KV::Connection') or $conn->send('');
}

1;