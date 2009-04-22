#!/usr/bin/perl 

use lib '/users/u3/inca/perllibs/lib';
use Data::Dumper;
use Date::Parse;
use strict;
use warnings;

my $EMAIL = 'inca@sdsc.edu';
my $URL = "/inca/jsp/query.jsp?action=View&qname=incaQueryLatest%2Bincas:__sapa.sdsc.edu:6323_check-reporter-managers&escapeXml=false";

sub notify {
  my ($subject, $content) = @_;

  `echo "$content" | mail -s "$subject" $EMAIL`;
#  print "$subject | $content\n";
}

die "Usage:  testRMs.pl <ID> <MAX TIME> <downtimeFile> http://consumerhost:consumerport" if scalar(@ARGV) != 4; 
my $ID = $ARGV[0];
my $MAX_TIME = $ARGV[1];
my $DOWNTIME_FILE = $ARGV[2];
my $url = $ARGV[3] . $URL;
if ( ! open( FD, "wget --no-check-certificate -q -O - '$url'|" ) || ! <FD> ) {
  notify( "$ID: testManager.pl not able to query", scalar(localtime()) );
  exit 1;
}

my %latestTimes;
my $hostname;
while ( <FD> ) {
  if ( /hostname/ ) {
    ( $hostname ) = />([^<]+)</;
    $latestTimes{$hostname} = 0 if ! exists $latestTimes{$hostname};
  }
  if ( /gmt/ ) {
    my ( $gmt ) = />([^<]+)</;
    my $time = str2time($gmt);
    $latestTimes{$hostname} = $time if $time > $latestTimes{$hostname};
  }
}
close FD;

my ( $host, $lastTS );
while( ($host, $lastTS) = each %latestTimes ) {
  my $now = time();
  my $timeDiff = $now - $lastTS;
  #print "$host $now $lastTS $timeDiff\n";
  if ( $timeDiff > $MAX_TIME ) {
    `grep $host $DOWNTIME_FILE`;
    #if ( $? != 0 && $host !~ /psc-pople/ ) {
    if ( $? != 0 ) {
      my $timeDiffMins = $timeDiff / 60.0;
      notify( "$ID:  $host is down and not in downtime", 
              "$host hasn't checked in for $timeDiffMins mins" );
    } 
  } else {
    #print "OK $host\n";
  }
}
