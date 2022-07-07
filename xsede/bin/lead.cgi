#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Data::Dumper;
use Date::Manip;

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

opendir(DIR, $LEAD_DIR);
  my @files = grep(/\d{4}-\d{4}/,readdir(DIR));
closedir(DIR);

my $dates;
foreach my $file (@files) {
  my ($beginDate, $endDate) = split(/-/, $file);
  my ($bmonth, $bday, $byear) = $beginDate =~ m/(\d{2})(\d{2})(\d{2})/;
  my ($emonth, $eday, $eyear) = $endDate =~ m/(\d{2})(\d{2})(\d{2})/;
  my $sortDate = $byear . $bmonth . $bday;
  $dates->{$sortDate} = {'file'=>$file, 'begin'=>"$bmonth-$bday-$byear",'end'=>"$emonth-$eday-$eyear"};
}
print "<br/>";
my $i = 0;
foreach my $date (sort {$b<=>$a} keys %$dates) {
  my $printDate = $dates->{$date}->{'begin'}." to ".$dates->{$date}->{'end'};  
  my $url = $LEAD_URL."/".$dates->{$date}->{'file'}."/index.html";
  if ($i==0){
    print "<h1>Current report: <a href=\"$url\">$printDate</a></h1><br/><h1>Past reports:</h1>";
  }else{
    print "<p><a href=\"$url\">$printDate</a></p>";
  }
  $i++;
}
print $q->end_html; 
