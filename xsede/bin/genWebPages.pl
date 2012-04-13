#!/usr/bin/perl

use strict;
use warnings;

my $webdir = "/localdisk/inca/teragrid/webapps/inca/html";
my $hostport = "capac.sdsc.edu:8080";
my $timeLog = "$ENV{HOME}/logs/genWebPagesTimes.log";

my $c3jsp = "http://$hostport/inca/jsp/status.jsp?suiteNames=ctss";
my $c3map = "http://$hostport/inca/jsp/status.jsp?suiteNames=ctss";
my $c4jsp = "http://$hostport/inca/jsp/status.jsp?suiteNames=core.teragrid.org-5.0.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.2,data-movement-clients.teragrid.org-4.2.0,data-movement-servers.teragrid.org-4.2.0,local-compute.teragrid.org-4.2.2,remote-compute.teragrid.org-4.2.0,remote-compute.teragrid.org-5.0.1,login.teragrid.org-4.0.0,app-support.teragrid.org-4.2.0,parallel-app.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.1,workflow.teragrid.org-4.2.0,vtss.teragrid.org-3.0.0,wan-gpfs.teragrid.org-4.0.0,wan-lustre.teragrid.org-4.0.0,science-gateway.teragrid.org-5.0.1,metascheduling.teragrid.org-4.2.1&resourceIds=core-5.0.0-production,data-management-4.0.0-production,data-movement-4.1.2-production,data-movement-clients-4.2.0-production,data-movement-servers-4.2.0-production,local-compute-4.2.2-production,remote-compute-4.2.0-production,remote-compute-5.0.1-production,login-4.0.0-production,app-support-4.2.0-production,parallel-app-4.0.0-production,parallel-app-4.0.1-production,workflow-4.2.0-production,vtss-3.0.0-production,wan-gpfs-4.0.0-production,wan-lustre-4.0.0-production,science-gateway-5.0.1-production,metascheduling-4.2.1-production";
my $c4xml = "&xml=core.teragrid.org-5.0.0.xml,data-management.teragrid.org-4.0.0.xml,data-movement.teragrid.org-4.1.2.xml,data-movement-clients.teragrid.org-4.2.0.xml,data-movement-servers.teragrid.org-4.2.0.xml,local-compute.teragrid.org-4.2.2.xml,remote-compute.teragrid.org-4.2.0.xml,remote-compute.teragrid.org-5.0.1.xml,login.teragrid.org-4.0.0.xml,app-support.teragrid.org-4.2.0.xml,parallel-app.teragrid.org-4.0.0.xml,parallel-app.teragrid.org-4.0.1.xml,workflow.teragrid.org-4.2.0.xml,vtss.teragrid.org-3.0.0.xml,wan-gpfs.teragrid.org-4.0.0.xml,wan-lustre.teragrid.org-4.0.0.xml,science-gateway.teragrid.org-5.0.1.xml,metascheduling.teragrid.org-4.2.1.xml";
my %pages = (
  'inst.html' => "http://$hostport/inca/jsp/instance.jsp?nickname=server-vacuumdb&resource=capac&collected=2011-10-03T21:31:49.000-07:00",
  'summary.html' => "http://$hostport/inca/jsp/status.jsp?xml=ctssv3.xml&xsl=summary.xsl&resourceIds=xsede&suiteNames=ctss",
  'ctssv3-graph.html' => "$c3jsp&xml=ctssv3.xml&xsl=graph.xsl",
  'ctssv3-query.html' => "$c3jsp&xml=ctssv3.xml&xsl=create-query.xsl",
  'ctssv3-map.html' => "$c3map&xml=google.xml&xsl=google.xsl",
  'ctssv4.html' => "$c4jsp$c4xml&xsl=swStack.xsl&noCategoryHeaders",
  'ctssv4-graph.html' => "$c4jsp$c4xml&xsl=graph.xsl",
  'ctssv4-query.html' => "$c4jsp$c4xml&xsl=create-query.xsl",
  'ctssv4-map.html' => "$c4jsp&xml=google.xml&xsl=google.xsl",
  'ctssv4-test.html' => "http://$hostport/inca/jsp/status.jsp?suiteNames=nimbus.teragrid.org-4.2.0,karnak,core.teragrid.org-5.0.0,remote-compute.teragrid.org-5.0.1,science-gateway.teragrid.org-4.2.0,wan-lustre.teragrid.org-5.0.0&resourceIds=nimbus-4.2.0-testing,quarry,core-5.0.0-testing,remote-compute-5.0.1-testing,science-gateway-4.2.0-testing,wan-lustre-5.0.0-testing&xml=nimbus.teragrid.org-4.2.0.xml,karnak.xml,core.teragrid.org-5.0.0.xml,remote-compute.teragrid.org-5.0.1.xml,science-gateway.teragrid.org-4.2.0.xml,wan-lustre.teragrid.org-5.0.0.xml&xsl=swStack.xsl&noCategoryHeaders"
);
my $errors = "";
for my $page ( keys %pages ) {
  my $startTime = time();
  my $tmpPage = "/tmp/" . $page . ".tmp";
  my $command = "wget -o /dev/null -O $tmpPage --header='Accept-Language: en-us,en' \"$pages{$page}\"";
  #print "$command\n";
  `$command`;
  my $endTime = time();
  my $loadTime = $endTime - $startTime; 
  if ( $? != 0 || ! -f $tmpPage ) { 
    $errors .= "\n $page=$pages{$page}"; 
  } else {
    open( FD, "<$tmpPage" );
    local $/; 
    my $content = <FD>;
    close FD;
    if ( $content =~ /inca-powered-by\.jpg/ &&
         $content !~ /Inca Error Page/ ) {
      `mv $tmpPage $webdir/$page`;
      `echo "$page,$endTime: $loadTime" >> $timeLog`;
    } else {
      $errors .= " $page-logo"
    }
  }
}
if ($errors ne ""){
  print "$errors\n";
}
