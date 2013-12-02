#!/usr/bin/perl

use strict;
use warnings;

my $dir = "/etc/grid-security/certificates.$$";
mkdir( $dir ) or die "Unable to create temp directory";
chdir( $dir ) or die "Unable to cd to temp directory";
`wget --no-check-certificate
https://software.xsede.org/security/xsede-certs.tar.gz 2>&1`;
`tar zxvf xsede-certs.tar.gz`;
my $out = `diff -x '*.r0' -r certificates /etc/grid-security/certificates`;
if ( $? != 0 ) {
  `rm -fr /etc/grid-security/certificates.old`;
  `mv /etc/grid-security/certificates /etc/grid-security/certificates.old`;
  `mv $dir/certificates /etc/grid-security/certificates`;
   `cp /etc/grid-security/InCommon-Server-CA /etc/grid-security/certificates`
   open( MAIL, '| mail -s "quarry certs were refreshed" ssmallen@sdsc.edu') ||
die "Unable to mail";
   print MAIL $out;
   close MAIL;
} 
`rm -fr $dir`;

