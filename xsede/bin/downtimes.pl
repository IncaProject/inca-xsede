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


my $dbh = DBI->connect("DBI:Pg:dbname=user_news;host=hogatha.sdsc.edu;port=5432", "inca", $pw);
die "Unable to connect to db" if ! defined $dbh;

my %resources = ( "inca_name" => $tmpFile,
                  "system_name" => $publicIISFile );
my $email = "";
my @new = ();
while (my ($resource, $file) = each(%resources)){
  my $now = DateTime->now;
  my $query = "SELECT i.item_id, i.subject, i.content, 
                s.event_start_time, s.event_end_time, s.event_time_zone, s.update_id,
                ps." . $resource . "
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
  #print "$query\n";
  my $sth = $dbh->prepare($query);
  if ( !defined $sth ) {
    die "Cannot prepare statement: $DBI::errstr\n";
  }
  $sth->execute();
  my %equivHosts = ( "anl-ia64" => ["anl-grid"],
    "ornl-login" => ["ornl-login2"],
    "ncsa-abe" => ["ncsa-grid-abe"],
    "ncsa-ia64" => ["ncsa-grid-hg"],
    "loni-lsu-queenbee" => ["loni-lsu-qb"] );
  open TMP,">$file";
  while ( my ($id, $subject, $content, $start, $end, $zone, $update, $name ) = $sth->fetchrow()){
    #print "$subject: $content\n";
    my $startDate = convertToDateTime($start, $zone, $id);
    my $endDate = convertToDateTime($end, $zone, $id);
    if ($startDate <= $now && $endDate >= $now){
      print TMP "$name=$id\n";
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
  close TMP;
}
$dbh->disconnect();
`mv $tmpFile $cacheFile`;
`cp $cacheFile $publicFile`;
if ($email ne ""){
  `echo "$email" | mail -s "TeraGrid News DB has new update or resource down" inca\@sdsc.edu`;
  my $newDown = join("\n", @new);
  open PF,">>$pastFile";
  print PF "\n$newDown\n";
  close PF;
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
               pattern => '%Y-%m-%d %H:%M:%S' ); # 2010-07-02 23:55:00
  my $parseDate = $parser->parse_datetime($date);
  if ($? || !defined($parseDate)){
    die "Can't parse date: $!\n";
  }
  $parseDate->set_time_zone($zone);
  return $parseDate;
}
