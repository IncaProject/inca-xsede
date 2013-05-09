#!/usr/bin/perl

use strict;
use warnings;
use Time::Local;

sub fetchData {
  my ($filename, $suite, $resource, $nickname, $startdate, $enddate) = @_;

  my $url = "http://inca.futuregrid.org:8080/inca/CSV/rest/$suite/$resource/$nickname/$startdate/$enddate";
  print "Fetching data from $url\n";
  `wget --header "Accept-Language: en-US,en"  -O "$filename.tmp" '$url' 2>&1`;
  my $firstline = `head -1 $filename.tmp`;
  die "Problem fetching history from $url" if $firstline !~ /resource, targetResource/;
  return "$filename.tmp";
}

sub getDate {
  my $time = shift;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  return sprintf( "%02d%02d%02d", $mon+1, $mday, $year-100);
}

sub getTimestamp {
  my $collected = shift;

  my ($year, $month, $day, $hour, $min, $sec) = $collected =~ /20(\d\d)-(\d\d)-(\d\d)T(\d+):(\d+):(\d+)/;
  return timelocal($sec,$min,$hour,$day,$month-1,$year);
}

my ($filename, $frequency, $prepend) = @ARGV;
my ($datadir, $basename) = $filename =~ /(\S+?)\/([^\/]+)$/;
my ($suite, $nickname, $resource) = $basename =~ /([^\+]+)\+([^\+]+)\+([^\+]+?)\.csv/;

$datadir = "." if ! defined $datadir;
my $end = time() + 86400;; 
my $enddate = getDate($end);
if ( ! -f $filename || defined $prepend ) {
  if ( -f $filename ) {
    my @firstlines = `head -2 $filename`;
    my $collected = (split(/","/, $firstlines[1]))[6];
    die "No timestamp found in $firstlines[1]" if ! defined $collected;
    $end = getTimestamp($collected);
    my ($year, $month, $day) = $collected =~ /20(\d\d)-(\d\d)-(\d\d)/;
    $enddate = "$month$day$year";
  } else {
    print "Creating new data file $filename\n";
  }
  my $numtries = 0;
  while( $numtries <=10 ) {
     my $start = $end - ($frequency * 3600);
     my $startdate = getDate($start);
     fetchData( $filename, $suite, $resource, $nickname, $startdate, $enddate );
     print "Reading data from $filename.tmp\n";
     open( NEWFD, ">$filename.new" );
     open( FD, "<$filename.tmp" );
     my $numlines = -1; # first line is header
     while( <FD> ) {
       print NEWFD $_;
       $numlines++;
     }
     close FD;
     print "Wrote $numlines new lines to $filename.new\n";
     if ( $numlines <= 0 ) {
       $numtries++;
     } else {
       $numtries = 0;
     }

     if ( -f $filename ) {
       open( FD, "<$filename" );
       my $throwaway = <FD>; # throw away header
       $throwaway =~ s/^[^"]+//;
       my @throwaway_fields = split(/,/, $throwaway);
       if ( scalar(@throwaway_fields) > 7 && $throwaway_fields[6] =~ /\d{4}-\d{2}-\d{2}/ ) {
         # valid line
         print NEWFD $throwaway;
print "Keeping throwaway: $throwaway";
       } else {
print "Throwaway: $throwaway";
       }
       while( <FD> ) {
         print NEWFD $_;
         $numlines++;
       }
       close FD;
       print "Total lines = $numlines in $filename.new\n";
     }
     close NEWFD;
     print "Moving $filename.new $filename\n";
     `mv -f $filename.new $filename`;
     `rm -f $filename.tmp`;
     $end = $start;
     $enddate = $startdate;
  }
} else {
  my $lastline = `tail -1 $filename`;
  my $collected = (split(/","/, $lastline))[6];
  my $lastTimestamp = getTimestamp($collected);
  my ($year, $month, $day) = $collected =~ /20(\d\d)-(\d\d)-(\d\d)/;
  my $startdate = "$month$day$year";
  fetchData( $filename, $suite, $resource, $nickname, $startdate, $enddate );
  open( CUR_FD, ">>$filename" );
  open( FD, "<$filename.tmp" );
  <FD>; # throw away header
  my $numlines = 0;
  while( <FD> ) {
    my $timestamp = getTimestamp( (split(/","/, $_))[6] ); 
    if ( $timestamp > $lastTimestamp ) {
      print CUR_FD $_;
      $numlines++;
    }
  }
  print "Wrote $numlines new lines to $filename\n";
  close FD;
  close CUR_FD;
  `rm -f $filename.tmp`;
}
