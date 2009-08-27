#! /usr/bin/perl -w
###############################################################################

=head1 NAME

countConnections

=head1 SYNOPSIS

  countConnections.pl depot.log

  or

  cat depot.log.gz | gunzip | countConnections.pl

=head1 DESCRIPTION

Parse an Inca component log (read from stdin) and report the length and number
of client connections from different hosts.

=cut

###############################################################################
use strict;
use warnings;

my %hostCurrentConnectionCount;
my %hostMaxConnectionCount;
my %hostTotalConnectionCount;
my %ipHost;
my @queueArrivals;
my @queueIps;
my %threadClasses;
my %threadClientsAtStart;
my %threadDelay;
my %threadHost;
my %threadQueryTimes;
my %threadSaveTimes;
my %threadStart;
my %threadUpdateTimes;
my %threadWaitingAtStart;

my $failures = 0;
my $maxConcurrentClients = 0;
my $maxQueueDepth = 0;
my $maxRunSeconds = 0;
my $startSeconds;
my $seconds = 0;
my $successes = 0;
my $totalQueryCount = 0;
my $totalQueryTime = 0;
my $totalSaveCount = 0;
my $totalSaveTime = 0;
my $totalUpdateCount = 0;
my $totalUpdateTime = 0;

while(<>) {
  next if $_ !~ /^(\d\d):(\d\d):(\d\d)/;
  $seconds = $1 * 3600 + $2 * 60 + $3;
  $startSeconds = $seconds if !defined $startSeconds;
  if($_ =~ m#Connection from /(.*)#) {
    my $ip = $1;
    push(@queueArrivals, $seconds);
    push(@queueIps, $ip);
    $maxQueueDepth = $#queueIps + 1 if $maxQueueDepth <= $#queueIps;
  } elsif($_ =~ m#Thread-(\d+).*Servicing request from .*?/([\d\.]+)#) {
    my ($threadId, $ip) = ($1, $2);
    my $arrived = shift(@queueArrivals);
    my $queueIp = shift(@queueIps);
    while(defined($queueIp) && $queueIp ne $ip) {
      $arrived = shift(@queueArrivals);
      $queueIp = shift(@queueIps);
    }
    my $host = $ipHost{$ip};
    if(!$host) {
      $host = `host $ip`;
      chomp($host);
      $host =~ s/.* //;
      $host =~ s/\.$//;
      $ipHost{$ip} = $host;
    }
    $hostTotalConnectionCount{$host} = 0
      if !defined($hostTotalConnectionCount{$host});
    $hostTotalConnectionCount{$host}++;
    $hostCurrentConnectionCount{$host} = 0
      if !defined($hostCurrentConnectionCount{$host});
    $hostCurrentConnectionCount{$host}++;
    $hostMaxConnectionCount{$host} = 0
      if !defined($hostMaxConnectionCount{$host});
    $hostMaxConnectionCount{$host} = $hostCurrentConnectionCount{$host}
      if $hostCurrentConnectionCount{$host} > $hostMaxConnectionCount{$host};
    $threadHost{$threadId} = $host;
    $threadStart{$threadId} = $seconds;
    $threadClientsAtStart{$threadId} = scalar(keys %threadHost);
    $maxConcurrentClients = $threadClientsAtStart{$threadId}
      if($threadClientsAtStart{$threadId} > $maxConcurrentClients);
    $threadDelay{$threadId} = defined($arrived) ? $seconds - $arrived : -1;
    $threadClasses{$threadId} = ();
    $threadQueryTimes{$threadId} = ();
    $threadSaveTimes{$threadId} = ();
    $threadUpdateTimes{$threadId} = ();
    $threadWaitingAtStart{$threadId} = scalar(@queueIps);
  } elsif($_ =~ m#Thread-(\d+).*Running ([\w\.]+)#) {
    my ($threadId, $className) = ($1, $2);
    $className =~ s/edu.sdsc.inca.depot.commands.//;
    push(@{$threadClasses{$threadId}}, $className)
      if $className !~ /Ping|VerifyProtocolVersion/;
  } elsif($_ =~ m#Thread-(\d+).*(Query|Saved|Updated).*in (\d+) msecs#) {
    my ($threadId, $dbOp, $msecs) = ($1, $2, $3);
    if($dbOp eq 'Query') {
      push(@{$threadQueryTimes{$threadId}}, $msecs);
      $totalQueryCount++;
      $totalQueryTime += $msecs;
    } elsif($dbOp eq 'Saved') {
      push(@{$threadSaveTimes{$threadId}}, $msecs);
      $totalSaveCount++;
      $totalSaveTime += $msecs;
    } else {
      push(@{$threadUpdateTimes{$threadId}}, $msecs);
      $totalUpdateCount++;
      $totalUpdateTime += $msecs;
    }
  } elsif($_ =~ m#Thread-(\d+).*(Ending conversation|Unable to send error)#) {
    my $threadId = $1;
    my $host = $threadHost{$threadId};
    my $succeeded = $2 eq 'Ending conversation';
    my $status = $succeeded ? 'completed' : 'failed';
    if($succeeded) {
      $successes++;
    } else {
      $failures++;
    }
    next if !defined($host);
    my $start = $threadStart{$threadId};
    my $runSeconds = $seconds - $start;
    $maxRunSeconds = $runSeconds if $runSeconds > $maxRunSeconds;
    my $startHours = int($start / 3600);
    my $startMinutes = int(($start - $startHours * 3600) / 60);
    my $startSeconds = $start % 60;
    my $endHours = int($seconds / 3600);
    my $endMinutes = int(($seconds - $endHours * 3600) / 60);
    my $endSeconds = $seconds % 60;
    my ($queryCount, $saveCount, $updateCount) = (0, 0, 0);
    my ($queryMsecs, $saveMsecs, $updateMsecs) = (0, 0, 0);
    if(defined($threadQueryTimes{$threadId})) {
      $queryCount = scalar(@{$threadQueryTimes{$threadId}});
      foreach my $event(@{$threadQueryTimes{$threadId}}) {
        $queryMsecs += $event;
      }
    }
    if(defined($threadSaveTimes{$threadId})) {
      $saveCount = scalar(@{$threadSaveTimes{$threadId}});
      foreach my $event(@{$threadSaveTimes{$threadId}}) {
        $saveMsecs += $event;
      }
    }
    if(defined($threadUpdateTimes{$threadId})) {
      $updateCount = scalar(@{$threadUpdateTimes{$threadId}});
      foreach my $event(@{$threadUpdateTimes{$threadId}}) {
        $updateMsecs += $event;
      }
    }
    my $classes = '';
    if(defined($threadClasses{$threadId})) {
      $classes = join(' ', @{$threadClasses{$threadId}});
    }
    my $clients = $threadClientsAtStart{$threadId} || 0;
    my $waiting = $threadWaitingAtStart{$threadId} || 0;
    my $delay = $threadDelay{$threadId} || 0;
    print sprintf("Thread-%s (%d/%d) %s", $threadId, $clients, $waiting, $host);
    print sprintf(" %d seconds (%02d:%02d:%02d to %02d:%02d:%02d)",
                  $runSeconds, $startHours, $startMinutes, $startSeconds,
                  $endHours, $endMinutes, $endSeconds);
    print sprintf(" %s %d", $status, $delay);
    print sprintf(" (%d/%d %d/%d %d/%d in %s)\n",
                  $queryMsecs, $queryCount, $saveMsecs, $saveCount,
                  $updateMsecs, $updateCount, $classes);
    $hostCurrentConnectionCount{$host}--;
  }
}

my $totalConnections = $successes + $failures;
$seconds -= $startSeconds;
print "$totalConnections connections in $seconds seconds (" .
      ($totalConnections * 1.0 / $seconds * 1.0) . "/second)\n";
print "$failures/$totalConnections failed (" .
       (($failures * 1.0 / $totalConnections * 1.0) * 100.0) . "%)\n";
print "Maximum queue = $maxQueueDepth\n";
print "Maximum concurrent clients = $maxConcurrentClients\n";
print "Maximum connection length = $maxRunSeconds\n";
print "Total query/save/update time/count $totalQueryTime/$totalQueryCount " .
      "$totalSaveTime/$totalSaveCount $totalUpdateTime/$totalUpdateCount\n";
foreach my $host(sort keys %hostMaxConnectionCount) {
  print "Max conncurrent from $host = $hostMaxConnectionCount{$host}\n";
}
