#!/usr/bin/perl

use Data::Dumper;

my $INSTALL_DIR = "/misc/inca/install-2r5";
my @ALL_RESOURCES = qw(tg-grid1.uc.teragrid.org anl-ia64 tg-viz-login1.uc.teragrid.org indiana-bigred ncar-frost ncsa-abe co-login1.ncsa.uiuc.edu tg-login1.ncsa.teragrid.org tund.ncsa.uiuc.edu tg-login1.ornl.teragrid.org psc-bigben rachel.psc.edu tg-login64.rcac.purdue.edu sdsc-bg sdsc-datastar sdsc-ia64 tacc-lonestar maverick.tacc.utexas.edu repo);
my %pings;
open( FD, "<$INSTALL_DIR/var/agent.log" ) or die "Can't open agent.log";
while( <FD> ) {
  if ( /Sending ping/ ) {
    my ($resource) = $_ =~ /\[(.+)\]/;
    my ($time) = $_ =~ /^(\d\d:\d\d:\d\d)/;
    $pings{$resource} = $time;
  }
}
close FD;

my ($nowSS, $nowMM, $nowHH, @junk) = localtime();
my $nowTimestamp = $nowSS + ($nowMM*60) + ($nowHH*60*60);
my $downResources = 0;
for my $resource ( @ALL_RESOURCES ) {
  if ( ! exists $pings{$resource} ) {
    printf "%-30s %s\n", $resource, "DOWN";
    $downResources++;
    next;
  }
  my $timeString = "";
  my ($pingHH, $pingMM, $pingSS) = $pings{$resource} =~ /(\d\d):(\d\d):(\d\d)/;
  my $pingTimestamp = $pingSS + ($pingMM*60) + ($pingHH*60*60);
  my $secsDiff = $nowTimestamp - $pingTimestamp;
  if ( $secsDiff < 10 * 60 ) {
    printf "%-30s %s\n", $resource, "OK";
    next;
  }
  $secsDiff =- 10 * 60;
  my $hours = int($secsDiff/3600);
  $hours = $hours > 0 ? (sprintf "%02s", $hours) : "00";
  my $mins = int( ($secsDiff - ($hours*3600)) / 60 );
  $mins = $mins > 0 ? (sprintf "%02s", $mins) : "00";
  my $secs = ($secsDiff - ($hours*3600) - ($mins*60));
  $secs = $secs > 0 ? (sprintf "%02s", $secs) : "00";
  $timeString = "$hours:$mins:$secs";
  printf "%-30s %s\n", $resource, $timeString;
}
print "===========================================\n";
if ( $downResources < 1 ) {
  print "ALL RESOURCES OK\n";
} else {
  print "$downResources out of " . scalar(@ALL_RESOURCES) . " resources down\n";
}
