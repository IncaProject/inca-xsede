#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $dir = "/users/u3/inca/bin/iis";
my $map = $dir."/nickname-iis-map";
my $xsl = $dir."/iis-query.xsl";
my $xml = $dir."/iis.xml.$$";
my $out = $dir."/iis-resources.$$";
`wget -o /dev/null -O $xml 'http://info.teragrid.org:8080/webmds/webmds?info=tgislocal'`;
`export CLASSPATH=$dir/saxon9.jar; /misc/inca/jdk1.5.0_14/bin/java net.sf.saxon.Transform -o $out $xml $xsl`;
my @mapfile;
open(FILE, $map) || die("Could not open $map!");
@mapfile=<FILE>;
close(FILE);
my @mapiis;
foreach my $mapline (@mapfile){
  my ($mapnickname, $mapiis) = split("=",$mapline);
  if(!grep(/^$mapiis$/,@mapiis)){
    push(@mapiis,$mapiis);
  }
}
my @iisfile;
open(FILE, $out) || die("Could not open $out!");
@iisfile=<FILE>;
close(FILE);
my @missing;
foreach my $iisresource (@iisfile){
  if(!grep(/^$iisresource$/,@mapiis)){
    push(@missing,$iisresource);
  }
}
if(@missing){
  my $missing = "The following resources are defined in IIS but have no Inca nickname mapping:\n\n  ";
  $missing .= join("\n  " , @missing);
  $missing .= "\nThe script generating this email is on sapa in $dir.";
  `echo "$missing" | mail -s \"Undefined IIS resource\" inca\@sdsc.edu`; 
}
unlink $xml, $out;
