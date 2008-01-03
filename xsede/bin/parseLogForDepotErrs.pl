#!/usr/bin/perl

use strict;
use warnings;

my @log;
my $numArgs = $#ARGV + 1;
my $logFile = "reporter-manager.log";
if ($numArgs == 1){
  $logFile = $ARGV[0];
}

open(RM, $logFile) || die("can't open RM file");
  @log=<RM>;
close RM;

my $numAttempts = 0;
my $numSuccess = 0;
my $numFailure = 0;
my $lastExe = "";
my %failHash;
sub hashValueDescendingNum {
  $failHash{$b} <=> $failHash{$a};
}
	 
foreach my $line (@log){
 if ($line =~ "INFO ReporterInstanceManager:853 - End bash"){
   $line =~ s/.[^\n]*INFO//g;
   $lastExe = $line;
 }
 if ($line =~ "Attempting to connect to depot"){
   $numAttempts++;
 }
 if ($line =~ "Sending report to"){
   $numSuccess++;
 }
 if ($line =~ "Unable to send report to available depots"){
   $numFailure++;
	 if(!defined $failHash{$lastExe}){
	   $failHash{$lastExe} = 1;
	 }else{
	   $failHash{$lastExe} = $failHash{$lastExe} + 1;
	 }
 }
}

open(DE,">>depotErrs.log") || die("can't open deport err file");
  print DE "\n----PARSE LOG: " . `date`;
  print DE "\nAttempts: $numAttempts";
  print DE "\nSuccesses: $numSuccess";
  print DE "\nFailures: $numFailure\n";
	foreach my $key (sort hashValueDescendingNum (keys(%failHash))) {
	  print DE "\t\t$failHash{$key} \t\t $key\n";
	}
close DE;
