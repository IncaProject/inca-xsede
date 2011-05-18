#!/usr/bin/perl

use strict;
use warnings;
use lib "/misc/inca/install-2r5/lib/perl";
use Inca::AgentClient;
use LWP::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use Data::Dumper;

# get the Inca agent configuration
my $dir = "$ENV{'HOME'}/inca2install";
my $pw = `cat $ENV{'HOME'}/bin/install.conf`;
$pw =~ s/\n//g;
my $agentclient = new Inca::AgentClient(
  host => "localhost",
  port => 6323,
  auth => 1,
  cert => "$dir/etc/rmcert.pem",
  key => "$dir/etc/rmkey.pem",
  password => $pw,
  trusted => "$dir/etc/trusted/b0b9a408.0"
);
if ( defined $agentclient->getError() ) {
  die "Unable to connect:" . $agentclient->getError();
}
my $config = $agentclient->getConfig();
my $xp = XML::XPath->new( xml => $config );

# get current downtimes
my $outfile = get("http://info.teragrid.org/web-apps/csv/tg-outages-v1/current/");
my @outages = split(/\n/, $outfile);
my $pre = "/misc/inca/install-2r5/webapps";
my $prop = "$pre/../etc/downtime.properties";
my $iis =  "$pre/inca/html/downtimes-iis.txt";
open PROP,">$prop";
open IIS,">$iis";
for my $i (1 .. $#outages){
  my @line = split(/,/, $outages[$i]);
  my $iis_resource = $line[1];
  my ($news_id) = $line[2] =~ /(\d+)"/;
  print IIS "$iis_resource=$news_id\n";
  my $rnode = $xp->find("/inca:inca/resourceConfig/resources/resource[name='$iis_resource']/macros/macro[name='__regexp__']/value/text()");
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

