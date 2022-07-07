#!/bin/perl

use lib '/misc/inca/incaws/lib/perl';
use SOAP::Lite;
use strict;
use warnings;

# check web services is up
my $index = undef; 
eval {
  local $SIG{ALRM} = sub { die "alarm clock restart" };
  alarm 20;
  $index = `/usr/bin/curl -s -o /dev/null "http://sapa.sdsc.edu:8001/webapp/webservice.asmx?wsdl"`;
  alarm 0;
};
if( $@ || !defined($index) || $?) {
  `echo | /bin/mail -s "incaws down on sapa" inca\@sdsc.edu`;
  exit 1;
}

#my $wsClient = SOAP::Lite->uri('urn:IncaWebService')->proxy("http://sapa.sdsc.edu:8001");
my $wsClient = SOAP::Lite->service("file:/misc/inca/incaws/etc/IncaWS.wsdl");
if ( ! defined $wsClient ) {
  `echo | /bin/mail -s "can't connect to sapa web services" inca\@sdsc.edu`;
  exit 1;
}

# check connection to depot
my $depot = undef; 
eval {
  local $SIG{ALRM} = sub { die "alarm clock restart" };
  alarm 60;
  $depot = $wsClient->pingDepot('hello depot');
  alarm 0;
};
if( $@ || ! defined($depot) || $depot !~ /hello depot/ ) {
  `date | /bin/mail -s "incaws depot err on sapa" inca\@sdsc.edu`;
  exit 1;
}

# check connection to agent
my $agent = undef;
eval {
  local $SIG{ALRM} = sub { die "alarm clock restart" };
  alarm 20;
  $agent = $wsClient->pingAgent('hello agent');
  alarm 0;
};
if( $@ || !defined($agent) || $agent !~ /hello agent/ ) {
  `date | /bin/mail -s "incaws agent err on sapa" inca\@sdsc.edu`;
  exit 1;
} 
  #`echo | /bin/mail -s "incaws UP on sapa" inca\@sdsc.edu`;
