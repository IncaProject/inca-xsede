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

# create config-part.xml
open( WRITE, ">$xslthome/config-part.xml") || die "Unable to open config.part.xml";
open( READ, "<config.xml") || die "Unable to open config.xml";
while( <READ> ) {
  next if /xml version="1\.0"/;
  next if /config>/;
  if ( /queries/ ) {
    $_ = <READ>;
    while ( $_ !~ /queries/ ) {
      $_ = <READ>;
    }
    $_ = <READ>;
  }
  print WRITE $_;
}
close READ;
close WRITE;

# concat kit defs
my $fd;
open( $fd, ">$xslthome/merged-config.xml") || die "Unable to open merged-config.xml";
print $fd "<config>\n";
readAndPrintFile( "config-part.xml", $fd );
print $fd "<Kits>\n";
my @xmls = glob( "$xslthome/etc/kits/*" );
for my $xml ( @xmls ) {
  readAndPrintFile( $xml, $fd );
}
print $fd "</Kits>\n";
print $fd "</config>\n";
close $fd;

my $cmd = "java -cp " . join( ":", @classpath ) . " " . $XSLT_CLASS . " " .
          "-xsl $xslthome/etc/def2config.xsl -in $xslthome/merged-config.xml > newconfigtmp.xml";
if ( scalar(@ARGV) > 0 ) {
  $cmd .= " > $ARGV[0]";
}
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 

$cmd = "cat newconfigtmp.xml | sed 's/^<config.*\$/<config>/' > newconfig.xml ";
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 

$cmd = "$xslthome/bin/updateIncat.sh newconfig.xml cache newincat.xml";
print "$cmd\n";
`$cmd`;
exit(1) if $? != 0; 
