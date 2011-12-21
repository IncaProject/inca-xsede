#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

print "Starting\n";
my $JAR = ".jar";
my $XSLT_CLASS = "org.apache.xalan.xslt.Process";

my $xslthome = dirname( $0 ) . "/../";
print "$xslthome\n";
my @jars = glob( "$xslthome/lib/*.jar" );

my @classpath = @jars;

sub readAndPrintFile {
  my $filename = shift;
  my $fd = shift;

  open( READ, "<$filename" ) || die "Unable to open $filename";
  while( <READ> ) {
    next if /\?xml/;
    print $fd $_;
  }
  close READ;
}

# create xml file to be fed to def2config.xsl 
my $fd;
open( $fd, ">$xslthome/def2config.xml") || die "Unable to open def2config.xml";
print $fd "<def2config>\n";
print $fd "<Kits>\n";
my @xmls = glob( "$xslthome/etc/kits/*" );
for my $xml ( @xmls ) {
  readAndPrintFile( $xml, $fd );
}
print $fd "</Kits>\n";
readAndPrintFile( "config.xml", $fd );
print $fd "</def2config>\n";
close $fd;

# create a new version of config.xml with kit queries and groups
# auto-generated
my $cmd = "java -cp " . join( ":", @classpath ) . " " . $XSLT_CLASS . " " .
          "-xsl $xslthome/etc/def2config.xsl -in $xslthome/def2config.xml > config-auto.xml.tmp";
if ( scalar(@ARGV) > 0 ) {
  $cmd .= " > $ARGV[0]";
}
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 

# remove namespaces from config tag
$cmd = "cat config-auto.xml.tmp | sed 's/^<config.*\$/<config>/' > config-auto.xml";
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 

# feed thru updateIncat to auto-generated a new incat.xml
$cmd = "$xslthome/bin/updateIncat.sh config-auto.xml cache incat-auto.xml";
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 
