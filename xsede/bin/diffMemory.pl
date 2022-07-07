#!/usr/bin/perl

use strict;
use warnings;

my @components = qw(Agent Consumer Depot);

open( FD, "<$ARGV[0]" );

my ( $pAgentMem, $pConsumerMem, $pDepotMem );
my ( $sAgentMem, $sConsumerMem, $sDepotMem );
my ( $startTime, $endTime );
my $throwOut = <FD>;
$throwOut = <FD>;
while( <FD> ) {
  # 1179418202 Depot=144.97265625 Consumer=96.25390625 Agent=133.85546875 
  my ( $timestamp ) = $_ =~ /^(\d+)/;
  my ( $agentMem ) = $_ =~ /Agent=([.\d]+)/;
  my ( $depotMem ) = $_ =~ /Depot=([.\d]+)/;
  my ( $consumerMem ) = $_ =~ /Consumer=([.\d]+)/;
  $startTime = $timestamp if ! defined $startTime;
  $sAgentMem = $agentMem if ! defined $sAgentMem;
  $sDepotMem = $depotMem if ! defined $sDepotMem;
  $sConsumerMem = $consumerMem if ! defined $sConsumerMem;
  if ( defined $pAgentMem ) {
#    print "Agent=", sprintf("%.2f", $pAgentMem - $agentMem), " ",
#          "Consumer=", sprintf("%.2f", $pConsumerMem - $consumerMem), " ",
#          "Depot=", sprintf("%.2f", $pDepotMem - $depotMem), "\n";
  }
  $pAgentMem = $agentMem;
  $pConsumerMem = $consumerMem;
  $pDepotMem = $depotMem;
  $endTime = $timestamp;
}
close FD;
print "Totals ( ", sprintf("%.2f", ($endTime - $startTime) / 3600), " H ) \n";
print "  Agent: $sAgentMem to $pAgentMem yields " . sprintf("%.2f", $pAgentMem - $sAgentMem), " KB ) \n";
print "  Depot: $sDepotMem to $pDepotMem yields ", sprintf("%.2f", $pDepotMem - $sDepotMem) , " KB ) \n";
print "  Consumer: $sConsumerMem to $pConsumerMem yields ", sprintf("%.1f", $pConsumerMem - $sConsumerMem), " KB ) \n";

