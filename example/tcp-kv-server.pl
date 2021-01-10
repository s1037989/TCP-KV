#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);

use KV;

$| = 1;

my $kv = KV->new;
$kv->plugin(test => sub { print '!' });

GetOptions(
  'F|flushall' => sub { $kv->store->flushall },
  'f|flush' => sub { $kv->store->flush },
  'd|die=i' => sub { $kv->die->add(pop) },
  'k|kill=i' => sub { $kv->kill->add(pop) },
);

$kv->ioloop->recurring(0.17 => sub { print '.' });
$kv->start(0.001 => [qw(test pids pipes rand kv eval)]);
