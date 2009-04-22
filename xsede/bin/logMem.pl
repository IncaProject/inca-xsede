#!/usr/bin/perl

use strict;
use warnings;

my $print = time();
my @psout = `ps x -o rss,command | grep 'edu.sdsc.inca'`;
for my $cmd ( @psout ) {
  if ( $cmd =~ /java/ ) {
    my ($mem,$junk,$part) = $cmd =~ /^(\d+)(.*)edu.sdsc.inca.(.[^\n]*)/;
    $mem /= 1024.0;
      $print .= " ".$part."=".$mem." ";
  }
}
$print .= "\n";
open(FD,">>/users/u3/inca/logs/memory_usage.log") || die("can't open file");
  print FD $print;
close FD;
