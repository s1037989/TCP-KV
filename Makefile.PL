use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
    'Time::HiRes' => '0',
    'IO::Socket::INET' => '0',
    'File::Path' => '0',
  },
  test => {TESTS => 't/*.t'}
);
