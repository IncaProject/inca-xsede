#!/usr/bin/perl

use strict;
use warnings;
use lib "/localdisk/inca/teragrid/lib/perl";
use LWP::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use Data::Dumper;
use Date::Manip;

my $config = `cat /localdisk/inca/teragrid/var/resources.xml`;
my $xp = XML::XPath->new( xml => $config );

# get current downtimes
# future is looked at too since there were some timezone parsing problems
my @urls = ( "http://info.teragrid.org/web-apps/csv/tg-outages-v1/future/", "http://info.teragrid.org/web-apps/csv/tg-outages-v1/current/");
my $pre = "/localdisk/inca/teragrid/webapps";
my $prop = "$pre/../etc/downtime.properties";
my $iis =  "$pre/inca/html/downtimes-iis.txt";
open PROP,">$prop";
open IIS,">$iis";
for my $url ( @urls ) {
  my $outfile = `wget -q -O - $url`;
  if ($? || ! defined $outfile ){
    print "could not get outage file\n";
  } else {
    my @outages = split(/\n/, $outfile);
    for my $i (1 .. $#outages){
      my @line = split(/,/, $outages[$i]);
      # 5/16/12 -- resource ids got reversed to <resource-name>-<site>
      my $iis_resource = $line[1];
      my @iis_resource_ids = split( /-/, $iis_resource );
      next if scalar(@iis_resource_ids) < 2; # not a resource-site pair
      my $site = $iis_resource_ids[$#iis_resource_ids];
      next if $site eq "news";
      my $resource = $iis_resource_ids[0];
      my $start= $line[$#line-1];
      $start =~ s/"//g;
      my $end= $line[$#line];
      $end =~ s/"//g;
      my $startDate = ParseDate($start);
      my $endDate = ParseDate($end);
      my $now = ParseDate("now");
      if ( Date_Cmp($now, $startDate) >= 0 &&
           (! defined $endDate || $endDate eq "" || Date_Cmp($now, $endDate)< 1) ) {
        my ($news_id) = $line[2] =~ /(\d+)"/;
        my $rnode = $xp->find("/res:resourceConfig/resources/resource[name='$resource-$site']/macros/macro[name='__regexp__']/value/text()");
        print PROP "$site-$resource=$news_id\n";
        foreach my $node ($rnode->get_nodelist) {
          my $resource = XML::XPath::XMLParser::as_string($node);
          my @resources = split(/ /, $resource);
          foreach my $r (@resources) {
            print IIS "$r=$news_id\n";
          }
        }
      }
    }
  }
}
close PROP;
close IIS;
`cp $prop $pre/inca/html/downtimes.txt`;
