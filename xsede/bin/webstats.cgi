#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $log = "access.log";
my $out = "webstats";

open (LOG,"$log");
my @log = <LOG>;
close (LOG);

#example line from log
#198.202.115.33 - - [05/Jan/2007:10:20:01 -0800] "GET /config.jsp?xsl=config.xsl HTTP/1.0" 200 22733 "-" "Wget/1.10.2 (Red Hat modified)" 

#remove sapa hits and hits on icons and robots.txt
my @filterlog;
foreach my $line (@log) {
  my($ip, $date, $url) = $line =~ m/([\d|\.]*) - - \[(.[^:]*).*GET \/(.[^\s]*).*$/;
  if ((defined $ip)&&(defined $date)&&(defined $url)){
    if (( $ip ne "198.202.115.33" )&&($url ne "favicon.ico")&&($url ne "robots.txt")) {
      my $add = $ip . " " . $date . " " . $url. "\n";
      push (@filterlog, $add);
    }
  }
}
#get unique dates in log
my @dates;
my @months;
foreach my $line (@filterlog){
  my @stats = split/ /,$line;
  my $date = $stats[1];
  my($day, $month) = $date =~ m/(.[^\/]*)\/(.*)$/;
  if(!grep (/$date/, @dates)) {
    push (@dates, $date);
  }
  if(!grep (/$month/, @months)) {
    push (@months, $month);
  }
}
#find unique hits by date
my @bydate;
my $datetotal = 0;
foreach my $date (@dates){
  my @hits;
  foreach my $line (@filterlog){
    my @stats = split/ /,$line;
    my $iplog = $stats[0];
    my $datelog = $stats[1];
    if(($datelog eq $date)&&(!grep (/$iplog/, @hits))) {
      push (@hits, $line);
    }
  }
  push (@bydate, $date . ": " . scalar(@hits));
  $datetotal += scalar(@hits);
}
foreach my $month (@months){
  print "\nTotal Unique Hits in " . $month . ": ";
  my $monthtotal = 0;
  foreach my $day(@bydate){
    my @stats = split/: /,$day;
    if ($stats[0] =~ $month){
      $monthtotal += $stats[1];
    }
  }
  print $monthtotal;
}

  print "\nTotal Unique Hits since 10-28-06: " . $datetotal ."\n";
  print join("\n", @bydate);

#put array into hash
#my %hashlog;
#foreach my $line (@filterlog){
#  my @stats = split/ /,$line;
#  $hashlog{$stats[1]} = {'ip' => $stats[0], 'url' => $stats[2] };
#}
#print Dumper %hashlog;
