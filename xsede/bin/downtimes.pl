#!/usr/bin/perl


use strict;
use warnings;

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
my @urls = ( "http://info.teragrid.org/web-apps/csv/tg-outages-v1/future/", "http://info.teragrid.org/web-apps/csv/tg-outages-v1/current/");
my $pre = "$INCA_INSTALL/webapps";
my $prop = "$INCA_INSTALL/etc/downtime.properties";
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
      # 10/9/12:  expecting iis id on second field
      my $iis_resource = $line[1];
      next if $iis_resource =~ /general-user-news/;
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
        # 10/9/12 -- lonestar has 2 registrations in IIS lonestar and lonestar4
        my $search_resource = $iis_resource =~ /lonestar/ ? "lonestar4.tacc.teragrid.org" : $iis_resource;
        $search_resource = $search_resource =~ /ranch/ ? "ranch.tacc.xsede.org" : $search_resource;
        $search_resource = $search_resource =~ /condor/ ? "condor.purdue.teragrid.org" : $search_resource;
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
