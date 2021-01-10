package KV::Pipes;
use parent 'KV::Connection';

use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);
use File::Basename qw(basename);
use File::Path qw(make_path);
use IO::Select;
use POSIX ();
 
use constant DEBUG => $ENV{KV_PIPES_DEBUG} || 0;

sub new {
  my $class = shift;
  my $kv = shift;
  my $self = bless {kv => $kv, @_}, $class;
  $self->{pipes} = {};
  $self->{select} = IO::Select->new;
  $self->{root} ||= '/dev/shm/tcp-kv';
  $self->{root} =~ s/\/$//;
  $self->{root} or CORE::die "root not defined";
  $self->{path} ||= '';
  $self->{path} =~ s/^\/|\/$//g;
  $self->{path} = join '/', $self->{root}, $self->{path};
  $self->{path} =~ s/\/$//g;
  $self->{path} .= "/pipes";
  make_path($self->{path});
  $kv->ioloop->recurring(0.10 => \&_watch_pipes);
  return $self;
}

sub fh {
  my $self = shift;
  if (@_) {
    $self->{active_fh} = shift;
    return $self;
  }
  else {
    my $fh = delete $self->{active_fh};
  }
}

sub mkfifo {
  my ($self, $pid) = (shift, shift);
  my $pipe = join '/', $self->{path}, $pid;
  -p "$pipe.1" or POSIX::mkfifo("$pipe.1", 0660);
  -p "$pipe.2" or POSIX::mkfifo("$pipe.2", 0660);
  return $pipe if -p "$pipe.1" && -p "$pipe.2";
  unlink("$pipe.1", "$pipe.2");
  return undef;
}

sub recv {
  my $self = shift;
  my $s = $self->{select};
  my @ready = $s->can_read(0.1);
  my $buffer;
  my $in;
  for (@ready) {
    sysread($_, $buffer, 1024) or next;
    $in = $_;
    last if $buffer;
  }
  return unless $buffer;
  print "received from $in: $buffer\n" if DEBUG > 1;
  return $buffer, $in;
}

sub send {
  my $self = shift;
  my $fh = $self->{pipes}->{$self->fh} or return;
  my $out = $fh->{out};
  print "sending to $out: @_\n" if DEBUG > 1;
  my $buffer = join "\n", @_;
  syswrite($out, length($buffer)."\n");
  syswrite($out, $buffer);
  return $self;
}

sub _watch_pipes {
  my $kv = shift;
  my $pipes = $kv->pipes;
  my $path = $pipes->{path};
  opendir(my $dh, $path) || die "Can't opendir $path: $!";
  foreach my $pipe ( map { s/\.[12]$//; "$path/$_" } readdir($dh) ) {
    if ($pipes->{pipes}->{$pipe}) {
      print "Checking status of pipe: $pipe\n" if DEBUG > 1;
      if (!kill 0, $pipes->{pipes}->{$pipe}->{pid}) {
        print "no $pipes->{pipes}->{$pipe}->{pid}, removing $pipe\n" if DEBUG;
        unlink("$pipe.1", "$pipe.2");
      }
      if (! -p "$pipe.1" || ! -p "$pipe.2") {
        print "no $pipe, killing $pipes->{pipes}->{$pipe}->{pid}\n" if DEBUG;
        unlink("$pipe.1", "$pipe.2");
        kill 0, $pipes->{pipes}->{$pipe}->{pid} and kill 15, $pipes->{pipes}->{$pipe}->{pid};
        $pipes->{select}->remove($pipes->{pipes}->{$pipe}->{in});
        delete $pipes->{pipes}->{$pipes->{pipes}->{$pipe}->{in}};
        delete $pipes->{pipes}->{$pipe};
      }
    }
    elsif (-p "$pipe.1" && -p "$pipe.2") {
      print "Adding new named pipe: $pipe\n" if DEBUG;
      sysopen my $in, "$pipe.1", O_RDONLY|O_NDELAY or die "can't read $pipe.1: $!";
      sysopen my $out, "$pipe.2", O_RDWR|O_NDELAY or die "can't write $pipe.2: $!";
      $pipes->{select}->add($in);
      $pipes->{pipes}->{$in} = $pipes->{pipes}->{$pipe} = {
        in => $in,
        out => $out,
        file => $pipe,
        pid => basename($pipe),
      };
      print "added\n" if DEBUG;
    }
  }
  closedir $dh;
  for (map { $pipes->{pipes}->{$_} } keys %{$pipes->{pipes}}) {
    my $pipe = $_->{file};
    if (!kill 0, $_->{pid}) {
      print "no $_->{pid}, removing $_->{file}\n" if DEBUG;
      unlink("$pipe.1", "$pipe.2");
    }
    if (! -p "$pipe.1" || ! -p "$pipe.2") {
      print "no $pipe, killing $_->{pid}\n" if DEBUG;
      unlink("$pipe.1", "$pipe.2");
      kill 0, $_->{pid} and kill 15, $_->{pid};
      $pipes->{select}->remove($_->{in});
      delete $pipes->{pipes}->{$_->{in}};
      delete $pipes->{pipes}->{$pipe};
    }
  }
}

1;