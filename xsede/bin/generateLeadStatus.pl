#!/usr/bin/perl

################################################################################

=head1 NAME

generateLeadStatus.pl - Generate LEAD weekly report

=cut
################################################################################

#=============================================================================#
# Usage
#=============================================================================#
use strict;
use warnings;
use Data::Dumper;
use Date::Manip;
use File::Temp qw(tempfile);

#=============================================================================#
# Global Vars
#=============================================================================#
my $DAY = "Mon"; # weekly reports should start and end on Monday.
my $INDEX_FILENAME = "index.html";  # name of top level index file

#-----------------------------------------------------------------------------#
# Public methods (documented with pod markers)
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
#
# downloadFiles( $dir, $relUrl, $rootUrl, @urls ) 
#
# Download a set of urls to disk.
#
# Arguments:
#
#   dir     The directory the local copy of the url should be stored
#
#   relUrl  To resolve relative urls in the list (i.e., urls beginning with an 
#           alphanumeric character).
#
#   rootUrl To resolve relative urls to the root server in the list (i.e., urls 
#           beginning with '/'.
#
#   urls    A list of unprocessed urls found in an html document.
#-----------------------------------------------------------------------------#
sub downloadFiles {
  my ( $dir, $relUrl, $rootUrl, @urls ) = @_;

  my %localFiles;
  my %suffixCounter;
  for my $url ( @urls ) {
    my ($suffix) = $url =~ /\.(\w+)$/;
    my $filename;
    if ( ! exists $suffixCounter{$suffix} ) {
      $suffixCounter{$suffix} = 1;
      $filename = "$suffix" . "0.$suffix";
    } else {
      $filename = "$suffix" . $suffixCounter{$suffix} . "." . $suffix;
      $suffixCounter{$suffix}++;
    }
    $localFiles{$url} = $filename;
    my $fullUrl = $url;
    if ( $url =~ /^\// ) {
      $fullUrl = $rootUrl . $url;
    } elsif ( $url =~ /^[\w\.]/ ) {
      $fullUrl = $relUrl . "/" . $url;
    }
    `wget -q -O $dir/$filename "$fullUrl"`;

  }
  return %localFiles;
}

#-----------------------------------------------------------------------------#
# getUrlsFromHtml( $filename ) 
#
# Extract a list of external links from the given html file
#
# Arguments:
#
#   filename   A local html file
#
# Returns:
#
#   A list of strings containing urls
#-----------------------------------------------------------------------------#
sub getUrlsFromHtml {
  my ( $filename ) = @_;

  my @urls;
  open( FD, "<$filename" ) || die "Unable to open $filename";
  while( <FD> ) {
    if ( /(href|src)=\"[^\"]+\"/ ) {
      my ( @hrefs ) = $_ =~ /href=\"([^\"]+)\"/g;
      my ( @srcs ) = $_ =~ /src=\"([^\"]+)\"/g;
      for my $url ( @hrefs, @srcs ) {
      if ( $url =~ /(\.png|\.css|\.js|\.gif|\.jpg)$/ ) {
        push( @urls, $url );
      } else {
        print "Discarding url $url\n";
      }
      }
    }
  }
  close FD;
  return @urls;
}

#-----------------------------------------------------------------------------#
# replaceUrls( $filename, %filemap ) 
#
# Replace the urls in $filename with those in the %filemap.
#
# Arguments:
#
#   filename   A local html file containing external urls
#
#   filemap    A hash array where the keys are urls in $filename and the 
#              values are the local copies of the urls.
#-----------------------------------------------------------------------------#
sub replaceUrls {
  my $filename = shift;
  my $rootUrl = shift;
  my %filemap = @_;

  open( FD, "<$filename") || die "Cannot open $filename";
  my $html = "";
  while( <FD> ) {
    $html .= $_;
  }
  close FD;

  for my $url ( keys %filemap ) {
    if ( $html !~ /\Q$url/ ) {
      print "Cannot find $url\n";
    }
    my $result = $html =~ s/\Q$url\Q/$filemap{$url}/g;
  }

  # delete jsession
  $html =~ s/;jsessionid=\w+//g;
  # replace instance.jsp
  $html =~ s/instance\.jsp/$rootUrl\/inca\/jsp\/instance\.jsp/g;

  open( NEW_FD, ">$filename.tmp") || die "Cannot open $filename.tmp";
  print NEW_FD $html;
  close NEW_FD;
  `mv $filename.tmp $filename`;
}

#-----------------------------------------------------------------------------#
# Main
#-----------------------------------------------------------------------------#

# time it
my $startTime = time();

# check arg
my $url = $ARGV[0];
die "Missing url" if ! defined $url;

my ( $relUrl ) = $url =~ /^(.+)\/[^\/]+$/;
my ( $rootUrl ) = $url =~ /^(http:\/\/[^\/]+)/;

# calculate start and end dates based on a weekly schedule calculated at
# day $DAY
my $date = ParseDate("today");
my $lastWeek = Date_GetPrev($date, $DAY, 0);
if ( $url !~ /startDate/ ) {
  my $startDate = UnixDate( $lastWeek, "%m%d%y");
  $url = $url . "&startDate=" . $startDate;
}
my ( $startDate ) = $url =~ /startDate=(\d+)/;
if ( $url !~ /endDate/ ) {
  # add 1 to get all of last day that we can
  my $nextWeekPlus1 = DateCalc( $lastWeek, "+7D" );
  my $endDate = UnixDate( $nextWeekPlus1, "%m%d%y");
  $url = $url . "&endDate=" . $endDate;
}
my ( $endDate ) = $url =~ /endDate=(\d+)/;

# lets create a directory for the local copy based on start and end dates
my $dir = "$startDate-$endDate";
if ( ! -d $dir && ! mkdir($dir) ) {
  die "Cannot create dir $dir";
}

# download html
`wget -T 7200 -q -O $dir/$INDEX_FILENAME.tmp --header='Accept-Language: en-us,en' '$url'`;
die "Unable to fetch '$url'" if $? != 0;
die "No error but file not written to disk" if ! -f "$dir/$INDEX_FILENAME.tmp";

# log time
my $loadTime = time() - $startTime;
open( FD, ">> $ENV{HOME}/lead.log" ) || die "Cannot open log";
print FD time() . " " . $loadTime . "\n";
close FD;

# check results
`grep 'Error occured in page: java.lang.IllegalStateException' $dir/$INDEX_FILENAME.tmp`;
if ( $? ==  0 ) {
  `date | mail -s "lead summary page failed" inca\@sdsc.edu`;
  exit( 0 );
}

my @urls = getUrlsFromHtml( "$dir/$INDEX_FILENAME.tmp" );
my %localFiles = downloadFiles( $dir, $relUrl, $rootUrl, @urls );
replaceUrls( "$dir/$INDEX_FILENAME.tmp", $rootUrl, %localFiles );
`mv $dir/$INDEX_FILENAME.tmp $dir/$INDEX_FILENAME`;

