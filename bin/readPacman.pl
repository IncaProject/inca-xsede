#!/usr/bin/perl

#############################################################
# Quick and dirty script to parse kit information from
# kit html files
#
# NOTE: must be executed on capac to get list of suites
#############################################################

use strict;
use warnings;

my $PACMAN = "http://software.teragrid.org/pacman/ctss4";
my @kitfiles = glob("/localdisk/inca/teragrid/var/suites/*teragrid.org*");
my @kits = map( /([^\/]+)\.xml$/, @kitfiles );
open( KIT, ">ctss-kits.xml" );
print KIT "<kits>\n";
for my $kit ( @kits ) {
  my ($kitname, $kitversion) = $kit =~ /([a-z\-]+)\.teragrid\.org-([\d\.]+)$/;
  my $url = undef;
  my $reg = undef;
  for my $urltry ( ("ctss-$kitname-registration", "ctss-$kitname", "$kitname-registration") ) {
    $url = $PACMAN . "/" . $urltry;
    $reg = $urltry;
    `wget -O - $url 2>&1 > /dev/null`;
    last if $? == 0; 
    $url = undef;
  }
  die "$kit not found at urls" if ! defined $url;
  $url .= "/$reg-$kitversion-r1";
  `wget -O - $url 2>&1 > /dev/null`;
  print "ERROR $kit not found at $url\n" if $? != 0;
  my $readmeUrl = $url . "/README.config.html";
  `wget -O config.html  $readmeUrl 2>&1 > /dev/null`;
print "PROCESSING $kitname\n";
  print KIT "<kit name=\"$kitname\" version=\"$kitversion\" release=\"r1\">\n";
  open( FD, "<config.html");
  while( <FD> ) {
    if ( /fixed/ ) {
      print KIT "  <kitRequirements>fixed</kitRequirements>\n";
    }
    if ( /variable list/ ) {
      print KIT "  <kitRequirements>variable</kitRequirements>\n";
    }
    if ( /Service Configuration/ ) {
      my $endService = 0;
      my $previousLine = "";
      while( ! $endService && ($_=<FD>) ) {
        if ( $previousLine =~ /Configuration file/ || $_ =~ /Configuration file/ ) {
          my $optional = 0;
          my ($servername) = /([^\/\.]+)\.conf/;
          ($servername) = $previousLine =~ /([^\/\.]+)\.(conf|noreg)/ if ! defined $servername;
          print KIT "  <service>\n";
          print KIT "    <name>$servername</name>\n";
          while( <FD> ) {
            if ( /version/ ) {
              my ($version) = />([^<]+)/;
              chomp($version);
              $version =~ s/The version should be//;
              print KIT "    <version>$version</version>\n";
            }
            $optional = 1 if /noreg/; 
            $endService = 1 if /<h2/;
            $previousLine = $_ if /Configuration file/;
            last if $_ =~ /Configuration file/ || $_ =~ /<h2/;
          }
          print KIT "    <type>";
          print KIT $optional ? "optional" : "required";
          print KIT "</type>\n";
          print KIT "  </service>\n";
        }
        last if /<h2/;
      }
    }
    if ( /Software Configuration/ ) {
      my $previousLine = "";
      while( <FD> ) {
        if ( $previousLine =~ /<h3>/ || (/<h3>/ && $_ !~ /[rR]egistration/) ) {
          my ($package) = /<h3>([\w\s]+)/;
          ($package) = $previousLine =~ /<h3>([\w\s]+)/ if ! defined $package;
          my $optional = 0;
          my ($key, $version, $handleKey) = ("not defined", "not defined", "not defined");
          if ( /Configuration \w*\s*file/ ) {
            ($key) = /([^\.\/]+)\.(conf|noreg|conf\.noreg)/; 
          }
          while( <FD> ) {
            if ( /Configuration \w*\s*file/ ) {
              ($key) = /([^\.\/]+)\.(conf|noreg|conf\.noreg)/; 
            }
            if ( /Version/ ) {
              ($version) = /Version: ([^<]+)/;
              $version = "not defined" if ! defined $version;
              $version =~ s/\s*A value like\s*//;
            }
            if ( /HandleKey/ ) {
              ($handleKey) = /HandleKey: ([^<]+)/;
              $handleKey = "not defined" if ! defined $handleKey;
              $handleKey =~ s/\s*A SoftEnv key of the form \+*//;
            }
            $optional = 1  if /optional/;
            $previousLine = $_ if /<h3>/;
            last if /^\s*<!-/ || /<h3>/;
          }
          print KIT "  <package>\n";
          print KIT "    <name>$key</name>\n";
          print KIT "    <version>$version</version>\n";
          print KIT "    <handleKey>$handleKey</handleKey>\n";
          print KIT "    <type>";
          print KIT $optional ? "optional" : "required";
          print KIT "</type>\n";
          print KIT "  </package>\n";
        }
        last if ! defined $_ || /<h2/;
      }
    }
  }
  close FD;
  print KIT "</kit>\n";
  #last if $kit =~ /core/;
}
print KIT "</kits>\n";
close KIT;
