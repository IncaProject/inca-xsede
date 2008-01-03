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
my $DAY = "Thu"; # weekly reports should start and end on Thurs.
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
    my ($suffix) = $url =~ /\.(.+)$/;
    my $filename;
    if ( ! exists $suffixCounter{$suffix} ) {
      $suffixCounter{$suffix} = 1;
      $filename = "$suffix" . "0.$suffix";
    } else {
      $filename = "$suffix" . $suffixCounter{$suffix} . "." . $suffix;
    }
    $localFiles{$url} = $filename;
    my $fullUrl = $url;
    if ( $url =~ /^\// ) {
      $fullUrl = $rootUrl . $url;
    } elsif ( $url =~ /^\w/ ) {
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
      my ( $junk, $url ) = $_ =~ /(href|src)=\"([^\"]+)\"/;
      push( @urls, $url );
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
    my $result = $html =~ s/\Q$url\Q/$filemap{$url}/;
  }

  open( NEW_FD, ">$filename.tmp") || die "Cannot open $filename.tmp";
  print NEW_FD $html;
  close NEW_FD;
  `mv $filename.tmp $filename`;
}

#-----------------------------------------------------------------------------#
# Main
#-----------------------------------------------------------------------------#

# check arg
my $url = $ARGV[0];
die "Missing url" if ! defined $url;

my ( $relUrl ) = $url =~ /^(.+)\/[^\/]+$/;
my ( $rootUrl ) = $url =~ /^(http:\/\/[^\/]+)/;

# calculate start and end dates based on a weekly schedule calculated at
# day $DAY
my $date = ParseDate("today");
if ( $url !~ /startDate/ ) {
  my $lastThurs = Date_GetPrev($date,"Thu", 0);
  my $startDate = UnixDate( $lastThurs, "%m%d%y");
  $url = $url . "&startDate=" . $startDate;
}
if ( $url !~ /endDate/ ) {
  # add 1 to get all of Thurs that we can
  my $nextThursPlus1 = DateCalc( Date_GetNext($date, $DAY, 0), "+1D" );
  my $endDate = UnixDate( $nextThursPlus1, "%m%d%y");
  $url = $url . "&endDate=" . $endDate;
}

# lets create a directory for the local copy based on start and end dates
my ( $startDate ) = $url =~ /startDate=(\d+)/;
my ( $endDate ) = $url =~ /endDate=(\d+)/;
my $dir = "$startDate-$endDate";
if ( ! -d $dir && ! mkdir($dir) ) {
  die "Cannot create dir $dir";
}

# download html
`wget -q -O $dir/$INDEX_FILENAME.tmp '$url'`;
die "Unable to fetch '$url'" if $? != 0;
die "No error but file not written to disk" if ! -f "$dir/$INDEX_FILENAME.tmp";

my @urls = getUrlsFromHtml( "$dir/$INDEX_FILENAME.tmp" );
my %localFiles = downloadFiles( $dir, $relUrl, $rootUrl, @urls );
replaceUrls( "$dir/$INDEX_FILENAME.tmp", %localFiles );
`mv $dir/$INDEX_FILENAME.tmp $dir/$INDEX_FILENAME`
