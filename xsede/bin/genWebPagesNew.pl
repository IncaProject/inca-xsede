#!/usr/bin/perl

use strict;
use warnings;

my $err = "";
my $date = `date`;
my $webdir = "/misc/inca/2.4testss/webapps/inca/html";
my $hostport = "sapa.sdsc.edu:6080";
my $log = "$ENV{HOME}/logs/genWebPagesNew.log";
my $timeLog = "$ENV{HOME}/logs/genWebPagesNewTimes.log";

my $c3jsp = "http://$hostport/inca/jsp/status.jsp?resourceIds=teragrid-login&suiteNames=ctss";
my $c4jsp = "http://$hostport/inca/jsp/status.jsp?suiteNames=core.teragrid.org-4.0.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-3.0.0,remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0,vtss.teragrid.org-3.0.0&resourceIds=core.teragrid.org-4.0.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-3.0.0,remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0,vtss.teragrid.org-3.0.0";
my $c4xml = "&xml=core.teragrid.org-4.0.0.xml,data-management.teragrid.org-4.0.0.xml,data-movement.teragrid.org-4.1.0.xml,remote-compute.teragrid.org-3.0.0.xml,remote-compute.teragrid.org-4.0.0.xml,login.teragrid.org-4.0.0.xml,app-support.teragrid.org-4.0.0.xml,parallel-app.teragrid.org-4.0.0.xml,workflow.teragrid.org-4.0.0.xml,vtss.teragrid.org-3.0.0.xml";
my %pages = (
  'inst.html' => "http://$hostport/inca/jsp/instance.jsp?instanceId=2135390&configId=1150026&resourceId=indiana-bigred",
  'summary.html' => "http://$hostport/inca/jsp/status.jsp?xml=ctssv3.xml&xsl=summary.xsl&resourceIds=teragrid-login&suiteNames=ctss",
  'ctssv3-expanded.html' => "$c3jsp&xml=ctssv3.xml&xsl=swStack.xsl",
  'ctssv3-graph.html' => "$c3jsp&xml=ctssv3.xml&xsl=graph.xsl",
  'ctssv3-map.html' => "$c3jsp&xml=google.xml&xsl=google.xsl",
  'ctssv4.html' => "$c4jsp$c4xml&xsl=swStack.xsl&noCategoryHeaders",
  'ctssv4-test.html' => "http://$hostport/inca/jsp/status.jsp?supportLevel=testing&suiteNames=core.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0&resourceIds=core.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0&xml=core.teragrid.org-4.0.0.xml,data-movement.teragrid.org-4.1.0.xml,remote-compute.teragrid.org-4.0.0.xml,app-support.teragrid.org-4.0.0.xml,parallel-app.teragrid.org-4.0.0.xml,workflow.teragrid.org-4.0.0.xml&xsl=swStack.xsl&noCategoryHeaders",
  'ctssv4-graph.html' => "$c4jsp$c4xml&xsl=graph.xsl",
  'ctssv4-map.html' => "$c4jsp&xml=google.xml&xsl=google.xsl"
);

#c4map=$webdir/ctssv4-map.html
#c4maptmp=$webdir/ctssv4-map.html.tmp
#c4url=$c4jsp$c4xml
#
# get instance

my $errors = "";
for my $page ( keys %pages ) {
  my $startTime = time();
  my $tmpPage = "/tmp/" . $page . ".tmp";
  my $command = "wget -o /dev/null -O $tmpPage --header='Accept-Language: en-us,en' \"$pages{$page}\"";
  print "$command\n";
  `$command`;
  my $endTime = time();
  my $loadTime = $endTime - $startTime; 
  if ( $? != 0 || ! -f $tmpPage ) { 
    $errors .= " $page"; 
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
print "$errors\n";
#
#countPostgres=`ps awwx | grep postgres | wc -l`
#echo $countPostgres >> ${HOME}/logs/postgresCount.log
#maxPostgres=60
#if ( test $countPostgres -gt $maxPostgres ); then
#  date | mail -s "postgres count is $countPostgres (over $maxPostgres processes)" inca@sdsc.edu
#fi
#
