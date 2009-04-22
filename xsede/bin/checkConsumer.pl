#!/usr/bin/perl

use strict;
use warnings;
use Date::Manip;
use Data::Dumper;

my $FILE = "/misc/inca/install-2r5/var/jetty1/webapp/ctssv3-expanded.html";

open( FD, "<$FILE" );
my $line;
while ( ($line = <FD>) ) {
  my ($date) = $line =~ /Page loaded: ([^<>]+)/;
  if ( defined $date ) {
    $date =~ s/-/\//g; # replace MM-DD-YY with MM/DD/YY
    $date =~ s/[()]//g;
    my $parsedDate = ParseDateString( $date );
    if ( $parsedDate ) {
      my $tooOld = DateCalc("today","- 30minutes");
      if ( Date_Cmp( $parsedDate, $tooOld ) < 0 ) { # $parsedDate is newer than $tooOld 
        `echo | mail -s "status pages not generating" inca\@sdsc.edu`;
      }
    }
  }
}
