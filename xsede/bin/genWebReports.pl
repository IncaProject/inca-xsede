#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Date::Manip;
use File::Temp qw(tempfile);

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
      if ( $url =~ /(\.png|\.js|\.jpg)$/ ) {
        push( @urls, $url );
      } else {
        #print "Discarding url $url\n";
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

my $timeLog = "$ENV{HOME}/logs/genWebPagesTimes.log";
my $webdir = "/misc/inca/install-2r5/webapps/inca/html/reports";
die "Unable to cd to '$webdir'" if !chdir($webdir);

my %pages = (
  'summaryHistoryByResource' => "http://sapa.sdsc.edu:8080/inca/jsp/summaryHistory.jsp?groupBy=resource&lines=total",
  'summaryHistoryBySuite' => "http://sapa.sdsc.edu:8080/inca/jsp/summaryHistory.jsp?groupBy=suite&lines=total"
);

for my $page ( keys %pages ) {
  my $dir = "tmp/$page";
  `rm -rf $dir`;
  if ( ! -d $dir && ! mkdir($dir) ) { die "Cannot create dir $dir"; }
  my $url = $pages{$page};
  my ( $relUrl ) = $url =~ /^(.+)\/[^\/]+$/;
  my ( $rootUrl ) = $url =~ /^(http:\/\/[^\/]+)/;
  my $startTime = time();
  my $tmpFile = "$dir/$page.tmp";
  my $prodFile = "$dir/index.html";
  # download html
  `wget -T 7200 -q -O $tmpFile --header='Accept-Language: en-us,en' '$url'`;
  die "Unable to fetch '$url'" if $? != 0;
  die "No error but file not written to disk" if ! -f "$tmpFile";
  my $endTime = time();
  my $loadTime = $endTime - $startTime;
  `echo "$page.html,$endTime: $loadTime" >> $timeLog`;
  # check results
  open( FD, "<$tmpFile" );
  local $/; # enable localized slurp mode
  my $html = <FD>;
  close FD;
  if ( $html =~ /Error occured in page: java.lang.IllegalStateException/ ) {
    `date | mail -s "report generation failed" inca\@sdsc.edu`;
    exit( 0 );
  }
  my @urls = getUrlsFromHtml($tmpFile);
  my %localFiles = downloadFiles( $dir, $relUrl, $rootUrl, @urls );
  replaceUrls( $tmpFile, $rootUrl, %localFiles );
  `mv $tmpFile $prodFile`;
  my $err = "";
  opendir(DIR, $dir);
  my @files = grep(/\.png$/,readdir(DIR));
  closedir(DIR);
  foreach my $file (@files){
    my $filename = "$dir/$file";
    $filename =~ s/\n//g;
    my $filesize = -s "$filename" || die "'$filename': $!" ;
    if ($filesize eq "8544" || $filesize == 8544){
      $err .= "$filename is expired\n";
    }
  }
  if ($err ne ""){
    `date | mail -s "report generation failed (expired charts)" inca\@sdsc.edu`;
  } else {
  `rm -rf $page; mv $dir .`;
  }
}
