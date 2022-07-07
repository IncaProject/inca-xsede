#!/usr/bin/perl

use strict;
use warnings;

my $print = time();
my $duOut = `du -ks /misc/inca/backups`;
my ($du) = $duOut =~ /(\d*).*/m;
$du /= 1048576;
$print .= "\t$du GB\n";
open(FD,">>/users/u3/inca/logs/backup_disk.log") || die("can't open file");
  print FD $print;
close FD;
