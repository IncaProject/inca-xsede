#!/usr/bin/perl

use Data::Dumper;

my $log = $ARGV[0];
$log = "var/depot.log.bak" if ( ! defined $log || $log eq "" );

my %lines;
open( FD, "<$log" );
while( <FD> ) {
  my $line = $_;
  if ( $line =~ /Thread\-\d+/ ) {
    my ($thread) = $line =~ /(Thread\-\d+)/;
    $lines{$thread} = $line;
  } 
}
close FD;

for my $thread ( keys %lines ) {
  #print $thread, " ", $lines{$thread};
  print $lines{$thread};
}
