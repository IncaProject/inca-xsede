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
  }
  $cmd .= " -k " . $self->getDotUccDir() . "/default-myproxy.p12 -T /etc/grid-security/xsede-certs.jks -Y xsede-certs.jks";
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

=head1 EXAMPLES

The following example demonstrates the usage of setUnicoreByGptQuery:

  my $reporter = new Inca::Reporter::Unicore(
    name => 'grid.middleware.globus.version',
    version => 1.25,
    description => 'Reports globus package versions',
    url => 'http://www.globus.org',
    package_name => 'globus'
  );
  $reporter->processArgv(@ARGV);
  $reporter->setUnicoreByGptQuery('globus');
  $reporter->print();

The following example demonstrates the usage of setUnicoreByRpmQuery:

  my $reporter = new Inca::Reporter::Unicore(
    name => 'cluster.compiler.gcc.version',
    version => 1.25,
    description => 'Reports the version of gcc',
    url => 'http://gcc.gnu.org',
    package_name => 'gcc'
  );
  $reporter->processArgv(@ARGV);
  $reporter->setUnicoreByRpmQuery('gcc');
  $reporter->print();

The following example demonstrates the usage of setUnicoreByExecutable:

  my $command = "java -version";
  my $pattern = '^java version \"(.*)\"[.\n]*';
  my $reporter = new Inca::Reporter::Unicore(
    name => 'cluster.java.sun.version',
    version => 1.25,
    description => 'Reports the version of java in the user\'s path',
    url => 'http://java.sun.com',
    package_name => 'java'
  );
  $reporter->processArgv(@ARGV);
  $reporter->setUnicoreByExecutable($command, $pattern);
  $reporter->print();

=head1 AUTHOR

Shava Smallen <ssmallen@sdsc.edu>

=head1 SEE ALSO

L<Inca::Reporter>

=cut
