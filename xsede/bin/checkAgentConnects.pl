#!/usr/bin/perl

# check how restarts are working in agent

use strict;
use warnings;
use Date::Manip;

my $INCA_DIR = "/misc/inca/install-2r5";
my $THRESHOLD = 15 + 2;

open( FD, "<$INCA_DIR/var/consumer.log" ) || die "Can't open consumer  log";
my $diffMins = 0;
while ( <FD> ) {
  if ( /query agent time/ ) {
    my $line = $_;
    my ( $timestamp, $resource ) = $line =~ /^(\d\d:\d\d:\d\d).*query agent time/;
    my $date = ParseDate( "today $timestamp" );
    my $diff = DateCalc( ParseDate( "now" ), $date );
    $diffMins = Delta_Format( $diff, 2, "%mt" );
  }
}
close FD;
if ( $diffMins < -1 * $THRESHOLD ) { # haven't already been notified
  print "Consumer cannot connect to agent for $diffMins mins\n"; 
 # `echo 'Consumer cannot connect to agent for $diffMins mins' | mail -s "ERROR:  Consumer cannot connect to agent" inca\@sdsc.edu`;
}

__END__
