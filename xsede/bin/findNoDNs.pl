#!/usr/bin/perl

use strict;
use warnings;

my %ips;
my %times;
open( FD, 'grep "Connection from" var/depot.log|' );
while ( <FD> ) {
  if ( $_ !~ /DN/ ) {
    my ($ip) = /(\d+\.\d+\.\d+\.\d+)/;
    my ($time) = /(\d+:\d+:\d+)/;
    $ips{$ip} = 0 if ! exists $ips{$ip};
    $ips{$ip}++; 
    $times{$ip} = "" if ! exists $times{$ip};
    $times{$ip} = $times{$ip} . " $time";
  }
}
close FD;
use Data::Dumper;
print Dumper \%ips;
print Dumper \%times;
