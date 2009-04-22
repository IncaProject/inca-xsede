#!/usr/bin/perl

# check how restarts are working in agent

use strict;
use warnings;
use Date::Manip;

my $INCA_DIR = "/misc/inca/install-2r5";

open( FD, "<$INCA_DIR/var/agent.log" ) || die "Can't open agent log";
while ( <FD> ) {
  if ( /Timing out/ ) {
    my $line = $_;
    my ( $timestamp, $resource ) = $line =~ /^(\d\d:\d\d:\d\d).*Timing out (\S+) starter thread/;
    my $date = ParseDate( "today $timestamp" );
    my $diff = DateCalc( ParseDate( "now" ), $date );
    my $diffMins = Delta_Format( $diff, 2, "%mt" );
    if ( $diffMins > -10 ) { # haven't already been notified
      `echo '$line $diffMins' | mail -s "CHECK ME: $resource thread timed out" ssmallen\@sdsc.edu`;
    }
  }
}
close FD;
