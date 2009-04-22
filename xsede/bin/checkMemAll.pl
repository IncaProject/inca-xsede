#!/usr/bin/perl

use strict;
use warnings;

my $maxMem = 700;

my $parts;
my @psout = `ps x -o rss,command | grep 'edu.sdsc.inca'`;
for my $cmd ( @psout ) {
  if ( $cmd =~ /java/ ) {
    my ($mem,$junk,$part) = $cmd =~ /^(\d+)(.*)edu.sdsc.inca.(.[^\n]*)/;
    $mem /= 1024.0;
    if ( $mem >= $maxMem ) {
      `echo "$cmd" | mail -s "sapa $part exceeding $maxMem MB" inca\@sdsc.edu`;
    }
    #print "$part at $mem MB\n";
    $parts .= "$part at $mem MB\n";
    
  }
}
