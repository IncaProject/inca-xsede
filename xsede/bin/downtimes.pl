#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;
use DateTime;
use DateTime::Format::Strptime;

my $home = "$ENV{'HOME'}";
my $dir = "/misc/inca/install-2r5/webapps/xsl/";
my $cacheFile = $dir . "downtime.properties";
my $tmpFile = $dir . "downtime.properties.tmp";
my $pastFile = "$home/logs/downtimes.log";
my $pastDown = `cat $pastFile`;
my @past = split("\n", $pastDown);
my $pw = `cat $home/bin/downtimes.db`;
$pw =~ s/\n//g;

my $service = "inca/". $pw . "@(DESCRIPTION =
          (ADDRESS = (PROTOCOL = TCP)(HOST = spike-vip.sdsc.edu)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = jet-vip.sdsc.edu)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = faye-vip.sdsc.edu)(PORT = 1521))
          (LOAD_BALANCE = on)(FAILOVER = on)(CONNECT_DATA =
          (SID = NPACI_RAC)(SERVER = DEDICATED)(SERVICE_NAME = npaci.sdsc.edu)
          (FAILOVER_MODE = (TYPE = select)(METHOD = basic))))";

my $dbh = DBI->connect('dbi:Oracle:', $service, '') || die "Database connect err: $DBI::errstr";
my $now = DateTime->now;
#debug time that will get a down resource
#$now = DateTime::Format::Strptime->new(pattern=>'%Y-%m-%d %l.%M.%S %p')->parse_datetime('2008-02-26 08.00.00 AM')->set_time_zone('America/Chicago'); 

my $query = "SELECT i.item_id, i.subject, i.content, 
                s.event_start_time, + s.event_end_time, s.event_time_zone, s.update_id,
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
my $email = "";
my @new = ();
open TMP,">$tmpFile";
while ( my ($id, $subject, $content, $start, $end, $zone, $update, $name ) = $sth->fetchrow()){
  my $startDate = convertToDateTime($start, $zone);
  my $endDate = convertToDateTime($end, $zone);
  if ($startDate <= $now && $endDate >= $now){
    print TMP "$name=$id\n";
    if (!grep(/^$id\s$update$/, @past)){
      $email .= "$name, http://news.teragrid.org/view-item.php?item=$id\n";
      push (@new, "$id\t$update");
    }
  }
}
$dbh->disconnect();
close TMP;
`mv $tmpFile $cacheFile`;
if ($email ne ""){
  `echo "$email" | mail -s "TeraGrid News DB has new update or resource down" inca\@sdsc.edu`;
  my $newDown = join("\n", @new);
  `echo $newDown >> $pastFile`;
}

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
