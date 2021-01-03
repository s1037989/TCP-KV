#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Getopt::Long;

use KV;

$| = 1;

my $kv = KV->new(minimal => 0.14);

GetOptions(
  'F|flushall' => sub { $kv->flushall },
  'f|flush' => sub { $kv->flush },
  'd|die=i' => sub { $kv->die->add(pop) },
  'k|kill=i' => sub { $kv->kill->add(pop) },
);

$kv->ioloop->recurring(0.17 => sub { print '.' });
$kv->ioloop->start;
