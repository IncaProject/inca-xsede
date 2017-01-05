#!/usr/bin/perl


use strict;
use warnings;
use JSON;

my $INCA_INSTALL;
BEGIN { # force variable to be set during compile
  $INCA_INSTALL="$ENV{HOME}/xsede";
}
use lib "$INCA_INSTALL/lib/perl";
use LWP::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use Data::Dumper;
use Date::Manip;

my $config = `cat $INCA_INSTALL/var/resources.xml`;
my $xp = XML::XPath->new( xml => $config );

# get current downtimes
# future is looked at too since there were some timezone parsing problems
my @urls = ( "https://info1.dyn.xsede.org:443/wh1/outages/v1/outages/Current", "https://info1.dyn.xsede.org:443/wh1/outages/v1/outages/Future/");
my $pre = "$INCA_INSTALL/webapps";
my $prop = "$INCA_INSTALL/etc/downtime.properties";
my $iis =  "$pre/inca/html/downtimes-iis.txt";
open PROP,">$prop";
open IIS,">$iis";
for my $url ( @urls ) {
  my $outfile = `wget --no-check-certificate -q -O - $url`;
  if ($? || ! defined $outfile ){
    print "could not get outage file\n";
  } else {
    my $json = decode_json($outfile);
    my @outages = @{$json};
    for my $i (1 .. $#outages){
      my $iis_resource = $outages[$i]->{"ResourceID"};
      next if $iis_resource =~ /general-user-news/;
      my $start = $outages[$i]->{"OutageStart"};
      my $end= $outages[$i]->{"OutageEnd"};
      my $startDate = ParseDate($start);
      my $endDate = ParseDate($end);
      my $now = ParseDate("now");
      if ( Date_Cmp($now, $startDate) >= 0 &&
           (! defined $endDate || $endDate eq "" || Date_Cmp($now, $endDate)< 1) ) {
        my $news_id = $outages[$i]->{"OutageID"};
        # 10/9/12 -- lonestar has 2 registrations in IIS lonestar and lonestar4
        my $search_resource = $iis_resource =~ /lonestar/ ? "lonestar4.tacc.teragrid.org" : $iis_resource;
        $search_resource = $search_resource =~ /ranch/ ? "ranch.tacc.xsede.org" : $search_resource;
        $search_resource = $search_resource =~ /stampede/ ? "stampede.tacc.xsede.org" : $search_resource;
        $search_resource =~ s/teragrid/xsede/ if $search_resource =~ /darter|gatech/;
        my $rnode = $xp->find("/res:resourceConfig/resources/resource[name='$search_resource']/macros/macro[name='__regexp__']/value/text()");
        print IIS "$iis_resource=$news_id\n";
        foreach my $node ($rnode->get_nodelist) {
          my $resource = XML::XPath::XMLParser::as_string($node);
          my @resources = split(/ /, $resource);
          foreach my $r (@resources) {
            print PROP "$r=$news_id\n";
          }
        }
      } else {
         ##print "$iis_resource $start $end\n";
      }
    }
  }
}
close PROP;
close IIS;
`cp $prop $pre/inca/html/downtimes.txt`;
