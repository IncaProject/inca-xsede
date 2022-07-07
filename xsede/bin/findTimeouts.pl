#!/usr/bin/perl

use Data::Dumper;

my $log = $ARGV[0];
$log = "var/depot.log.bak" if ( ! defined $log || $log eq "" );

my %lines;
open( FD, "<$log" );
while( <FD> ) {
  my $line = $_;
  if ( $line =~ /Servicing request/ ) {
    my ($thread) = $line =~ /(Thread\-\d+)/;
    $lines{$thread} = $line;
  } 
  if ( $line =~ /Unable to complete SSL handshake/ ) {
    my ($thread) = $line =~ /(Thread\-\d+)/;
    my ($ip) = $lines{$thread} =~ /(\d+\.\d+\.\d+\.\d+)/;
    my $host = `host $ip`;
    ($host) = $host =~ /([a-z]+\.[a-z]+\.[a-z]+\.[a-z]+)/;
    print "$host ", $lines{$thread};
  }
}
close FD;

for my $thread ( keys %lines ) {
  #print $thread, " ", $lines{$thread};
  #print $lines{$thread};
}
