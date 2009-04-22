#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Time::ParseDate;

my $thread;
my %threads;
my $previousLine;
for my $log ( @ARGV ) {
  open( FD, $log );
  while( <FD> ) {
    if ( /gSH:/ || /singly/ ) {
      ($thread) = $_ =~ /(Thread-\d+)/;
      my ($time) = $_ =~ /^(\d\d:\d\d:\d\d)/;
      if ( ! exists $threads{$thread} ) {
        $threads{$thread} = { numJoins => 0, numIns => 0, 
                              joinQueryTime => 0, inQueryTime => 0,
                              startTime => $time, 
                              minJoinTime => 10000000, maxJoinTime => 0, 
                              minInTime => 10000000, maxInTime => 0, 
                              count => [], config => ""
                             };
      }
      $threads{$thread}->{endTime} = $time;
      if ( /singly/ ) {
        ($thread) = $_ =~ /(Thread-\d+)/;
        my ($config) = $_ =~ /(join.*$)/;
        $threads{$thread}->{config} = $config;
      } 
      if ( /\d+ SCs/ ) {
        my ($total) = /(\d+) SCs/;
        $threads{$thread}->{total} = $total;
        if ( $previousLine =~ /$thread/ && $previousLine =~ /QueryImpl/ ) {
          ($threads{$thread}->{query}) = $previousLine =~ /AND \(([^\)]+)\)/;
        } else {
          $threads{$thread}->{query} = "not found";
        }
      }
      if ( /count \d+ reports/ ) {
        my ($count) = /(\d+) reports/;
        push( @{$threads{$thread}->{count}}, $count );
      }
      if ( /report\/instance/ ) {
        my ($qtime) = /(\d+) ms/;
        $threads{$thread}->{joinQueryTime} += $qtime;
        $threads{$thread}->{maxJoinTime} = $qtime if ($qtime > $threads{$thread}->{maxJoinTime}); 
        $threads{$thread}->{minJoinTime} = $qtime if ($qtime < $threads{$thread}->{minJoinTime}); 
        $threads{$thread}->{numJoins} += 5;
      }
      if ( /report fields/ ) {
        my ($qtime) = /(\d+) ms/;
        $threads{$thread}->{inQueryTime} += $qtime;
      }
      if ( /ii fields/ ) {
        my ($qtime) = /(\d+) ms/;
        $threads{$thread}->{inQueryTime} += $qtime;
        $threads{$thread}->{maxInTime} = $qtime 
          if ($qtime > $threads{$thread}->{maxInTime}); 
        $threads{$thread}->{minInTime} = $qtime 
          if ($qtime < $threads{$thread}->{minInTime}); 
        $threads{$thread}->{numIns} += 5;
        if ( ! exists $threads{$thread}->{elapsedDays} ) {
          my ($sdate,$edate) = $previousLine =~ /(\w{3} \w{3} \d\d \d\d:\d\d:\d\d \w{3} \d{4})/g;
          my $stime = parsedate( $sdate ); 
          my $etime = parsedate( $edate );
          $threads{$thread}->{elapsedDays} = ($etime - $stime) / (60 * 60 * 24);
        }
      }
    }
    $previousLine = $_;
  }
  close FD;
}

for my $thread ( keys %threads ) {
  $threads{ $threads{$thread}->{startTime} } = $threads{$thread};
  delete $threads{$thread};
}

for my $thread ( sort(keys %threads) ) {
  my ($shour,$smin,$ssec) = $threads{$thread}->{startTime} =~ /(\d\d):(\d\d):(\d\d)/;
  $smin += $shour * 60;
  my ($ehour,$emin,$esec) = $threads{$thread}->{endTime} =~ /(\d\d):(\d\d):(\d\d)/;
  $ehour += 24 if ( $ehour < $shour );
  $emin += $ehour * 60;
  my $fraction = 0;
  if ( exists $threads{$thread}->{total} && $threads{$thread}->{total} > 0 ) {
    $fraction = ($threads{$thread}->{numJoins} + $threads{$thread}->{numIns}) / 
                 $threads{$thread}->{total};
  }
  print "$thread TOTALS => " . ($emin-$smin)/60 . "h or " . ($emin-$smin) . "m = $fraction\n";
  print $threads{$thread}->{elapsedDays} . ", " . $threads{$thread}->{query}, "\n";
  print $threads{$thread}->{config}, "\n";
  print "\n";        
  if ( $threads{$thread}->{numJoins} > 0 ) {
    print "Total Joins = " . $threads{$thread}->{numJoins} . " took " . 
          ($threads{$thread}->{joinQueryTime}/60000) . "m ==> " . 
        ($threads{$thread}->{joinQueryTime}/$threads{$thread}->{numJoins}/1000) . " s per join\n";
    print "maxJoinTime = " . $threads{$thread}->{maxJoinTime}/1000 . " s, minJoinTime = " . 
         $threads{$thread}->{minJoinTime}/1000 . " s\n";
  }
  print "\n";
  if ( $threads{$thread}->{numIns} > 0 ) {
    print "Total Ins = " . $threads{$thread}->{numIns} . " took " . 
          ($threads{$thread}->{inQueryTime}/60000) . "m ==> " . 
          ($threads{$thread}->{inQueryTime}/$threads{$thread}->{numIns}/1000) . "s per in\n";  
    print "maxInTime = " . $threads{$thread}->{maxInTime}/1000 . " s, minInTime = " . 
          $threads{$thread}->{minInTime}/1000 . " s\n";
    print "count: ";
    my $hundredLess = 0;
    my $hundred = 0;
    my $thousand = 0;
    my $rest = 0;
    for my $count ( sort @{$threads{$thread}->{count}} ) {
      $hundredLess++ if $count < 100;
      $hundred++ if $count >= 100 && $count < 200;
      $thousand++ if $count >= 200 && $count < 1000;
      $rest++ if $count >= 1000;
    }
    print "$hundredLess < 100, $hundred 100s, $thousand 200s-1000, $rest more\n";
  }
  print "-------------------\n";
}
