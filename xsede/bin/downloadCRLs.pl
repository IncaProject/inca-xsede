#!/usr/bin/perl

use strict;
use warnings;

my @crlFiles=glob( "/etc/grid-security/certificates/*crl_url" );
for my $crlFile ( @crlFiles ) {
  my @crlUrls;
  open( FD, "<$crlFile" );
  while( <FD> ) {
    my ($crlUrl) = /(\S+)/;
    push( @crlUrls, $crlUrl );
  }
  close FD;
  for my $crlurl ( @crlUrls ) {
    my ($remoteCrlFilename) = $crlurl =~ /([^\/]+)$/;
    my ($hash) = $crlFile =~ /([^\/]+)\.crl_url$/;
    my $localr0Filename = "/etc/grid-security/certificates/$hash.r0";
    my $localCrlFilename = "/etc/grid-security/certificates/$remoteCrlFilename";
    `rm -f $localr0Filename`;
    #print "wget -O $localCrlFilename  $crlurl 2>&1 > /dev/null\n";
    `wget -O $localCrlFilename  $crlurl 2>&1`; # > /dev/null`;
    if ( $remoteCrlFilename =~ /crl$/ || $remoteCrlFilename =~ /der$/  ) {
      #print "openssl crl -inform DER -outform PEM -in $localCrlFilename -out $localr0Filename\n";
      `openssl crl -inform DER -outform PEM -in $localCrlFilename -out $localr0Filename`;
      `rm -f $localCrlFilename`;
    } elsif ( $localCrlFilename ne $localr0Filename ) {
      #print "cp $localCrlFilename $localr0Filename\n";
      `mv $localCrlFilename $localr0Filename`;
    }
    last if -f $localCrlFilename;
  }
}


