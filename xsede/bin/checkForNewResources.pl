#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use Date::Manip;
use strict;
use warnings;

my $ignoreHostsRE = qw(loni|ornl|nautilus|dash|keeneland|data\.psc|tape\.ncsa\.teragrid\.org|mason|info\.gig);
my $ignoreKitsRE = qw(local-hpc-software|parallel-app|execution-management|global-federated-file-system);

my @newHosts;
my $xml = XMLin( "/localdisk/inca/updateincatXSEDE/kit-regs.xml", ForceArray => [ "KitRegistration", "Kit" ] );
for my $resource ( @{$xml->{KitRegistration}} ) {
  my $resourceid = $resource->{ResourceID};
  my $knownResource = 0;
  for my $kit ( @{$resource->{Kit}} ) {
    if ( defined $kit->{Name} && $kit->{Name} eq "core.teragrid.org" && 
         $kit->{SupportLevel} =~ /production|testing/i ) {
      my $resourcetype = $kit->{Extensions}->{RDR_Resource}->{Resource}->{ResourceType};
      if ( defined $resourcetype && $resourcetype =~ "Compute|Storage" ) {
        for my $status ( @{$kit->{Extensions}->{RDR_Resource}->{Resource}->{ResourceStatus}} ) {
          if ( $status->{ResourceStatusType} eq "Decommissioned" && defined $status->{StartDate} && ref($status->{StartDate}) ne "HASH") {
            my $startdate = $status->{StartDate};
            my $today = ParseDateString("today");
            if ( Date_Cmp( ParseDateString($startdate), $today) >= 0 ) { 
              my $out = `grep $resourceid /localdisk/inca/updateincatXSEDE/config.xml`;
              $knownResource = 1 if $? == 0;
              if ( $? != 0 && $resourceid !~ $ignoreHostsRE ) {
                push( @newHosts, $resourceid );
              } elsif ( $? != 0 ) {
                open( FD, ">>$ENV{HOME}/logs/newhosts.log" );
                print FD scalar(localtime()) . " found new or unknown host $resourceid\n";
                close FD;
              }
            } 
          }
        }
      }
    } 
  }
  if ( $knownResource ) {
    for my $kit ( @{$resource->{Kit}} ) {
      my $kitid = $kit->{Name} . "-" . $kit->{Version};
      my $out = `grep $kitid /localdisk/inca/updateincatXSEDE/config.xml`;
      if ( $? != 0 && $kit->{Name} !~ $ignoreKitsRE ) {
        `echo $kitid $resourceid | mail -s "$resourceid registering $kitid kit not in config.xml" inca\@sdsc.edu`;
      }
    }
  }
}
if ( @newHosts ) {
  `echo @newHosts | mail -s "New hosts found in XSEDE info" inca\@sdsc.edu`;
}

