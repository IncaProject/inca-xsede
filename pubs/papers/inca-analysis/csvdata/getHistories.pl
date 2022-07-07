#!/usr/bin/perl

use strict; 
use warnings;
use Data::Dumper;

# gather all test names of interest
my @RESOURCES = qw(iu-india iu-bravo iu-delta iu-india iu-xray tacc-alamo uc-hotel ucsd-sierra ufl-foxtrot);
my %SUITES = (
  HPC_Tests => [ qw(batch-testjob batch-testjob_to_bravo batch-testjob_to_delta cuda-test myHadoop hpcc8) ],
  Basic => [ qw(ssh) ],
  Cloud => []
);
for my $cloud ( qw(nimbus eucalyptus openstack) ) {
  for my $test ( qw(clientStatus create-publicvm storage) ) {
    push( @{$SUITES{Cloud}}, "$cloud-$test" );
  }
} 

# `wget http://inca.futuregrid.org:8080/inca/CSV/rest/Cloud/ucsd-sierra/eucalyptus-clientStatus/120112/123112`;
my @series;
for my $suite ( keys %SUITES ) {
  for my $nickname ( @{$SUITES{$suite}} ) {
    for my $resource ( @RESOURCES ) {
      my $wgetcmd = "wget -O - http://inca.futuregrid.org:8080/inca/XML/rest/$suite/$resource/$nickname";
      my $wget = `$wgetcmd 2>&1`;
      if ( $wget !~ /not found/ ) {
        print "$wgetcmd\n";
        my $frequency = 2160; # 3 months
        my ($min) = $wget =~ /<min>([^<]+)<\/min>/;
        my ($hour) = $wget =~ /<hour>([^<]+)<\/hour>/;
        if ( ! defined $min || ! defined $hour ) {
          print "min $min and hour $hour not defined\n";
          print $wget;
          exit;
        } elsif ( $min =~ /\/\d+/ ) {
          $frequency = 168;
        } elsif ( $hour =~ /\/\d+/ ) {
          $frequency = 720;
        } 
        print "Fetching history\n";
        my $cmd = "./getHistory.pl data/$suite+$nickname+$resource.csv $frequency";
        print "$cmd\n";
        print `$cmd`;
      }
    }
  } 
}
