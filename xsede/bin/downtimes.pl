#!/usr/bin/perl

use strict;
use warnings;
use lib "/localdisk/inca/teragrid/lib/perl";
use LWP::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use Data::Dumper;

my $config = `cat /localdisk/inca/teragrid/var/resources.xml`;
my $xp = XML::XPath->new( xml => $config );

# get current downtimes
my $outfile = get("http://info.teragrid.org/web-apps/csv/tg-outages-v1/current/");
if ($?){
  print "could not get outage file\n$!";
} else {
  my @outages = split(/\n/, $outfile);
  my $pre = "/localdisk/inca/teragrid/webapps";
  my $prop = "$pre/../etc/downtime.properties";
  my $iis =  "$pre/inca/html/downtimes-iis.txt";
  open PROP,">$prop";
  open IIS,">$iis";
  for my $i (1 .. $#outages){
    my @line = split(/,/, $outages[$i]);
    my $iis_resource = $line[1];
    my ($news_id) = $line[2] =~ /(\d+)"/;
    print IIS "$iis_resource=$news_id\n";
    my $rnode = $xp->find("/res:resourceConfig/resources/resource[name='$iis_resource']/macros/macro[name='__regexp__']/value/text()");
    foreach my $node ($rnode->get_nodelist) {
      my $resource = XML::XPath::XMLParser::as_string($node);
      my @resources = split(/ /, $resource);
      foreach my $r (@resources) {
        print PROP "$r=$news_id\n";
      }
    }
  }
  close PROP;
  close IIS;
  `cp $prop $pre/inca/html/downtimes.txt`;
}
