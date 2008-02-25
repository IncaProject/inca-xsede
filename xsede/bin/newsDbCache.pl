#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;
use DateTime;
use DateTime::Format::Strptime;

my $dir = "/misc/inca/install-2r5/webapps/xsl/";
my $cacheFile = $dir . "newsCache";
my $tmpFile = $dir . "newsCache.tmp";

my $service = q{inca/PW@(DESCRIPTION =
          (ADDRESS = (PROTOCOL = TCP)(HOST = spike-vip.sdsc.edu)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = jet-vip.sdsc.edu)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = faye-vip.sdsc.edu)(PORT = 1521))
          (LOAD_BALANCE = on)(FAILOVER = on)(CONNECT_DATA =
          (SID = NPACI_RAC)(SERVER = DEDICATED)(SERVICE_NAME = npaci.sdsc.edu)
          (FAILOVER_MODE = (TYPE = select)(METHOD = basic))))};

my $dbh = DBI->connect('dbi:Oracle:', $service, '') || die "Database connect err: $DBI::errstr";
my $now = DateTime->now;

my $query = "SELECT i.item_id, i.subject, i.content, 
                s.event_start_time, + s.event_end_time, s.event_time_zone, 
                ps.inca_name 
          FROM  user_news.item i, 
                user_news.system_event s,
                user_news.platform_system ps, 
                user_news.item_platform ip 
          WHERE s.item_id = i.item_id  AND
                ip.item_id = i.item_id AND
                ip.system_id = ps.system_id AND
                s.event_end_time >= '" . $now->ymd . "' AND
                s.outage_type_id = '2' AND
                i.deleted IS NULL AND
                s.update_id = (SELECT MAX(se.update_id) FROM user_news.system_event se WHERE se.item_id = i.item_id) 
          ORDER BY s.event_start_time";

my $sth = $dbh->prepare($query);
if ( !defined $sth ) {
  die "Cannot prepare statement: $DBI::errstr\n";
}
$sth->execute();
open TMP,">$tmpFile";
while ( my ($id, $subject, $content, $start, $end, $zone, $name ) = $sth->fetchrow()){
  my $startDate = convertToDateTime($start, $zone);
  my $endDate = convertToDateTime($end, $zone);
  #$now = DateTime::Format::Strptime->new(pattern=>'%Y-%m-%d %l.%M.%S %p')->parse_datetime('2008-02-26 08.00.00 AM')->set_time_zone('America/Chicago');
  if ($startDate <= $now && $endDate >= $now){
    #print TMP "$id\t$name\t$startDate\t$endDate\t$now\n";
    print TMP "$name\t$id\n";
  }
}
$dbh->disconnect();
close TMP;
`mv $tmpFile $cacheFile`;


sub convertToDateTime{
  my $date = shift;
  my $zone = shift;

  $zone =~ s/PT/America\/Los_Angeles/g;
  $zone =~ s/CT/America\/Chicago/g;
  $zone =~ s/ET/America\/New_York/g;
  my $parser = DateTime::Format::Strptime->new( 
               pattern => '%Y-%m-%d %l.%M.%S %p' ); # 2008-02-26 08.00.00 AM
  my $parseDate = $parser->parse_datetime($date);
  if ($? || !defined($parseDate)){
    die "Can't parse date: $!\n";
  }
  $parseDate->set_time_zone($zone);
  return $parseDate;
}
