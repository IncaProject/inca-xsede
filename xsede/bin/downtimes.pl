#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;
use DateTime;
use DateTime::Format::Strptime;

my $home = "$ENV{'HOME'}";
my $dir = "/misc/inca/install-2r5/etc/";
my $cacheFile = $dir . "downtime.properties";
my $tmpFile = $dir . "downtime.properties.tmp";
my $publicFile = $dir . "../webapps/inca/html/downtimes.txt";
my $publicIISFile = $dir . "../webapps/inca/html/downtimes-iis.txt";
my $map = $home."/bin/iis/nickname-iis-map";
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
my $nowMinusHour =  $now->clone->subtract( hours => 1 );

my $query = "SELECT i.item_id, i.subject, i.content, 
                s.event_start_time, s.event_end_time, s.event_time_zone, s.update_id,
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
#print $query;
my $sth = $dbh->prepare($query);
if ( !defined $sth ) {
  die "Cannot prepare statement: $DBI::errstr\n";
}
$sth->execute();
my $email = "";
my @new = ();
my %equivHosts = ( "anl-ia64" => ["anl-grid"],
    "ncsa-abe" => ["ncsa-grid-abe"],
    "ncsa-ia64" => ["ncsa-grid-hg"],
    "loni-lsu-queenbee" => ["loni-lsu-qb"] );
open TMP,">$tmpFile";
open IIS,">$publicIISFile";
while ( my ($id, $subject, $content, $start, $end, $zone, $update, $name ) = $sth->fetchrow()){
  my $startDate = convertToDateTime($start, $zone, $id);
  my $endDate = convertToDateTime($end, $zone, $id);
  if ($startDate <= $now && $endDate >= $now){
    print TMP "$name=$id\n";
    my $iis = getIIS($name);
    print IIS "$iis=$id\n";
    if (grep(/^$name$/, keys %equivHosts)){
      for my $eqiv (@{$equivHosts{$name}}){
        print TMP "$eqiv=$id\n";
      }
    }
    my $str = "$id\t$update\t$start\t$zone\t$end\t$zone";
    if (!grep(/^$str$/, @past)){
      #$email .= "New resource down: $name, http://news.teragrid.org/view-item.php?item=$id\n";
      push (@new, $str);
    }
  }
}
close IIS;
close TMP;
`mv $tmpFile $cacheFile`;
`cp $cacheFile $publicFile`;

$dbh->disconnect();
if ($email ne ""){
  #`echo "$email" | mail -s "TeraGrid News DB has new update or resource down" inca\@sdsc.edu`;
  my $newDown = join("\n", @new);
  open PF,">>$pastFile";
  print PF "\n$newDown\n";
  close PF;
}

sub getIIS{
  my $name = shift;
  my @mapfile;
  open(FILE, $map) || die("Could not open $map!");
  @mapfile=<FILE>;
  close(FILE);
  my $iis;
  foreach my $mapline (@mapfile){
    my ($mapnickname, $mapiis) = split("=",$mapline);
    if($mapnickname eq $name){
      $mapiis =~ s/\s+$//;
      $iis = $mapiis;
    }
  }
  if(!$iis){
    `echo "Can't map \"$name\" in $map on sapa" | mail -s "Error in downtime.pl script" inca\@sdsc.edu`;
    exit;
  }
  return $iis;
}

sub convertToDateTime{
  my $date = shift;
  my $zone = shift;
  my $id = shift;

  $zone =~ s/P(|.)T/America\/Los_Angeles/g;
  $zone =~ s/M(|.)T/America\/Denver/g;
  $zone =~ s/C(|.)T/America\/Chicago/g;
  $zone =~ s/E(|.)T/America\/New_York/g;
  #print "Date: $date\nZone: $zone\nNews: http://news.teragrid.org/view-item.php?item=$id\n";
  my $parser = DateTime::Format::Strptime->new( 
               pattern => '%Y-%m-%d %l.%M.%S %p' ); # 2008-02-26 08.00.00 AM
  my $parseDate = $parser->parse_datetime($date);
  if ($? || !defined($parseDate)){
    die "Can't parse date: $!\n";
  }
  $parseDate->set_time_zone($zone);
  return $parseDate;
}
