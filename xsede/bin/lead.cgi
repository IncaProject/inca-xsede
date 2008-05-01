#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Data::Dumper;
use Date::Manip;

my $THU_START_DATE = "29-Nov-2007"; 
my $DAY = "Thu";
my $LEAD_DIR = "/misc/inca/local/packages/apache/1.3.26/htdocs/lead";
my $LEAD_URL = "/lead";

my $TITLE = "Inca LEAD Weekly Status Report";
my $q = new CGI();
print $q->header;
print $q->start_html( 
  -title => $TITLE, 
  -style => { src => 'http://sapa.sdsc.edu:8080/inca/css/inca.css' }
);
print $q->h1( $TITLE );
my @thursdays = ParseRecur
  ( "0:0:1:0:0:0:0",$THU_START_DATE,$THU_START_DATE, "next friday" );
for ( my $i = 0; $i < $#thursdays; $i++ ) {
  my $endDate = DateCalc($thursdays[$i], "+8D" );
  my $displayEndDate = DateCalc($thursdays[$i], "+7D" );
  my $dir = UnixDate( $thursdays[$i], "%m%d%y" ) . "-" . 
            UnixDate($endDate, "%m%d%y");
  my $altDir = UnixDate( $thursdays[$i], "%m%d%y" ) . "-" . 
            UnixDate($displayEndDate, "%m%d%y");
  if ( -d "$LEAD_DIR/$altDir" ) {
    $dir = $altDir;
  }
  if ( -d "$LEAD_DIR/$dir" ) {
    my $desc = UnixDate( $thursdays[$i], "%m-%d-%y" ) . " to " . 
                UnixDate($displayEndDate, "%m-%d-%y");
    print $q->p( $q->a( 
      { -href => "$LEAD_URL/$dir/index.html" },
      $desc
    ) );
  }
}
print $q->end_html; 
