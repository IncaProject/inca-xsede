package Inca::XSEDE::Unicore;

################################################################################

=head1 NAME

Inca::Unicore - Convenience module for Unicore reporters

=head1 SYNOPSIS

  use Inca::Unicore;

  my $reporter = new Inca::Reporter::SimpleUnit();
  ...
  my $unicore = new Inca::XSEDE::Unicore();
  ...
  $reporter->processArgv(@ARGV);
  ...
  $unicore->loggedCommand( $reporter, "ucc list-sites" );
  ...
  $reporter->unitSuccess();
  $reporter->print();

=head1 DESCRIPTION

This module is a utility class for authenticating to Unicore and running 
Unicore commands.

=cut

################################################################################

use strict;
use warnings;
use Carp;

#=============================================================================#

=head1 CLASS METHODS

=cut

#=============================================================================#

#-----------------------------------------------------------------------------#

=head2 new( $reporter )

Class constructor which returns a new Inca::XSEDE::Unicore object and
attaches the current reporter object to it.  Must be called before the 
processArgv in order to process the dependency correctly.  The contructor will
create a temporary directory to store Unicore related files and will look for
the X509_USER_PROXY credential and convert it to a PKCS12 file.  

=over 13

=item reporter

the reporter object associated with the reporter

=back

=cut

#-----------------------------------------------------------------------------#
sub new {
  my ($this, $reporter, %attrs) = @_;
  my $class = ref($this) || $this;
  my $debug = exists( $attrs{debug} ) ? $attrs{debug} : 0;
  my $self = { 
    reporter => $reporter
  };
  bless ($self, $class);

  $self->{reporter}->addDependency(__PACKAGE__);
  $self->{dotucc} = "$ENV{HOME}/.ucc.$$";
  $self->{reporter}->tempFile( $self->{dotucc} ) if ! $debug;

  return $self;
}

#-----------------------------------------------------------------------------#

=head2 getDotUccDir()

Return the path to the temporary ~/.ucc.$$ directory in use for this instance.

=cut

#-----------------------------------------------------------------------------#
sub getDotUccDir {
  my ($self ) = @_;

  if ( ! -d $self->{dotucc} ) {
    $self->{reporter}->failPrintAndExit("Cannot create temp dir " . $self->{dotucc} ) 
      if !  mkdir( $self->{dotucc} );
    $self->{reporter}->log( 'INFO', "Created temp dir " . $self->{dotucc} );
  }
  return $self->{dotucc};
}
#-----------------------------------------------------------------------------#

=head2 loggedCommand($cmd)

A convenience; appends $cmd to the 'system'-type log messages stored in the
reporter, then returns `$cmd 2>&1`.  If $timeout is specified and the command
doesn't complete within $timeout seconds, aborts the execution of $cmd, sets $!
to POSIX::EINTR and $? to a non-zero value, and returns any partial output.

=over 13

=item cmd 

Unicore command to run

=back

=cut

#-----------------------------------------------------------------------------#
sub loggedCommand {
  my ($self, $cmd, $timeout) = @_;

  $self->{reporter}->failPrintAndExit("X509_USER_PROXY must be defined") 
    if ! exists $ENV{X509_USER_PROXY};
  if ( ! -f $self->getDotUccDir() . "/default-myproxy.p12" ) {
    $self->{randpass} = `openssl rand -base64 32`;
    chomp($self->{randpass});
    my $cmd = "openssl pkcs12 -export -in $ENV{X509_USER_PROXY} -out " .
              $self->getDotUccDir() . "/default-myproxy.p12  -name myproxy -password stdin";
    $self->{reporter}->failPrintAndExit("Problem running command $cmd") 
      if ! open( SSL, "|$cmd" ); 
    $self->{reporter}->log('system', $cmd);
    print SSL $self->{randpass} . "\n";
    print SSL $self->{randpass} . "\n";
    close SSL;
    my $prefs = $self->getDotUccDir() . "/preferences";
    open( FD, ">$prefs" );
    print FD "credential.path=" . $self->getDotUccDir() . "/default-myproxy.p12\n";
    print FD "credential.format=pkcs12\n";
    print FD "truststore.type=directory\n";
    print FD "truststore.directoryLocations.1=/etc/grid-security/certificates/*.0\n";
    print FD "truststore.crlLocations.1=/etc/grid-security/certificates/*.r0\n";
    print FD "client.http.connection.timeout=2000\n";
    print FD "client.http.socket.timeout=2000\n";
    print FD "client.outHandlers=de.fzj.unicore.uas.security.ProxyCertOutHandler\n";
    print FD "uas.security.out.handler.classname=de.fzj.unicore.uas.security.ProxyCertOutHandler\n";
    close FD;
  }
  $cmd .= " -c " . $self->getDotUccDir() . "/preferences";
  $self->{reporter}->log('system', $cmd);
  my $tempfile = $self->getDotUccDir() . "/ucc-" . time() . ".out";
  open( CMD, "|$cmd &> $tempfile" );
  print CMD $self->{randpass} . "\n";
  close CMD;

  my $saveExit = $?;
  my $output = "";
  if ( open( FD, "<$tempfile" ) ) {
    local $/ = undef;
    $output = <FD>;
    close FD;
  }
  $? = $saveExit;
  return $output;
}


1;

__END__

