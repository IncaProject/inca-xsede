#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

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
my $numFailure = 0;
my $start = "INFO ReporterInstanceManager:729 - Begin executing";
my $end = "INFO ReporterInstanceManager:853 - End";
my $lastError = "";
my %lastErrorHash;
my %completeHash;
my %failHash;

sub hashValueDescendingNum {
  $failHash{$b} <=> $failHash{$a};
}
	 
foreach my $line (@log){
 if ($line !~ "Unable to send report to available depots" && $line =~ "ERROR"){
   $line =~ s/.[^\n]*ERROR//g;
	 $lastError = $line;
 }
 if ($line =~ $start){
   $line =~ s/.[^\n]*$start//g;
	 if (!defined $completeHash{$line}){
	   $completeHash{$line} = 1;
	 }
 }
 if ($line =~ $end){
   $line =~ s/.[^\n]*$end//g;
	 delete $completeHash{$line};
 }
 if ($line =~ "Unable to send report to available depots"){
   $numFailure++;
	 foreach my $key (keys %completeHash){
	   if(!defined $failHash{$key}){
	     $failHash{$key} = 1;
	   }else{
	     $failHash{$key} = $failHash{$key} + 1;
	   }
		 delete $completeHash{$key};
	 }
	 if(!defined $lastErrorHash{$lastError}){
	   $lastErrorHash{$lastError} = 1;
	 }else{
	   $lastErrorHash{$lastError} = $lastErrorHash{$lastError} + 1;
	 }
	 $lastError = "";
 }
 if ($line =~ "Attempting to connect to depot"){
   $numAttempts++;
 }
}
open(DE,">>depotErrs.log") || die("can't open deport err file");
  print DE "\n----PARSE LOG: " . `date`;
  print DE "\nAttempts: $numAttempts";
	my $numSuccess = $numAttempts - $numFailure;
  print DE "\nSuccesses: $numSuccess";
  print DE "\nFailures: $numFailure\n\n";
	foreach my $key (sort hashValueDescendingNum (keys(%failHash))) {
	  print DE "\t\t$failHash{$key} \t\t $key\n";
	}
  print DE "\nLAST ERRS:\n\n";
	foreach my $key (keys %lastErrorHash) {
	  print DE "$lastErrorHash{$key}: $key\n";   
	}
close DE;
