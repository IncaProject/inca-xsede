#!/usr/bin/perl

my @regexes = ( qr/query connect/, qr/query depot/, qr/Suite query for/, qr/Update cache suite/, qr/total query time/ );
open( FD, "<var/consumer.log" );
while( <FD> ) {
  for my $regex ( @regexes ) {
    if ( /$regex/ ) {
      print $_;
      last;
    }
  }
}
close FD;
