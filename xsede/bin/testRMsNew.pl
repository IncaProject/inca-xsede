#!/usr/bin/perl 

use lib '/users/u3/inca/perllibs/lib';
use Data::Dumper;
use Date::Parse;
use strict;
use warnings;

my $EMAIL = 'ssmallen@sdsc.edu';
my $URL = "/inca/XML/rest";

sub notify {
  my ($subject, $content) = @_;

  `echo "$content" | mail -s "$subject" $EMAIL`;
#  print "$subject | $content\n";
}

die "Usage:  testManagers.pl <ID> <MAX TIME> consumerhost:consumerport" if scalar(@ARGV) != 5; 
my $ID = $ARGV[0];
my $MAX_TIME = $ARGV[1];
my $SUITE = $ARGV[3];
my $DOWNTIME_FILE = $ARGV[4];
my $wget = "wget -q -O - http://" . $ARGV[2] . $URL . "/" . $SUITE;;
if ( ! open( FD, "$wget |" ) ) {
  notify( "$ID: testManager.pl not able to query $!", scalar(localtime()) );
  exit 1;
}

my %latestTimes;
my $hostname;
while ( <FD> ) {
  if ( /<hostname/ ) {
    ( $hostname ) = />([^<]+)</;
    $latestTimes{$hostname} = 0 if ! exists $latestTimes{$hostname};
  }
  if ( /<gmt/ ) {
    my ( $gmt ) = />([^<]+)</;
    if ( defined $gmt ) {
      my $time = str2time($gmt);
      $latestTimes{$hostname} = $time if $time > $latestTimes{$hostname};
    }
  }
}
close FD;

my ( $host, $lastTS );
while( ($host, $lastTS) = each %latestTimes ) {
 `grep $host $DOWNTIME_FILE`;
 if ( $? != 0 ) {
    my $now = time();
    my $timeDiff = $now - $lastTS;
    if ( $timeDiff > $MAX_TIME ) {
      my $timeDiffMins = $timeDiff / 60.0;
      notify( "$ID:  $host is down and not in downtime", 
              "$host hasn't checked in for $timeDiffMins mins" );
    } else {
#      print "OK $host\n";
    }
  }
}
