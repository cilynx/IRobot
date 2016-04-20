#!/usr/bin/perl

package IRobot::ROI;

use strict;
use Device::SerialPort;

my $mode = {
   Off => 0,
   Passive => 1,
   Safe => 2,
   Full => 3
};

my $dispatch = {
   Start => {
      serialSequence => [128],
      setMode => 'Passive'
   },
   # There is no 'Passive' command in the spec, but this maintains the ability to call
   # the mode you want as a method and not have to write a bunch of work-arounds just
   # for 'Passive' mode.
   Passive => {
      serialSequence => [128],
      setMode => 'Passive'
   },
   Control => {
      serialSequence => [130],
      setMode => 'Passive'
   },
   Safe => {
      serialSequence => [131],
      minMode => 'Passive',
      setMode => 'Safe',
   },
   Clean => {
      serialSequence => [135],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   Max => {
      serialSequence => [136],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   Spot => {
      serialSequence => [134],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   LEDs => {
      serialSequence => [139,'LED Bits','Clean/Power Color','Clean/Power Intensity'],
      minMode => 'Safe',
      dataRange => [[0,15],[0,255],[0,255]],
      code => ['Debris','Spot','Dock','Check Robot'],
   },
   SeekDock => {
      serialSequence => [143],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   DriveDirect => {
      serialSequence => [145,'Right velocity high byte','Right velocity low byte','Left velocity high byte','Left velocity low byte'],
      minMode => 'Safe'
   },
   Schedule => {
      serialSequence => [167,'Days','Sun Hour','Sun Minute','Mon Hour','Mon Minute','Tue Hour','Tue Minute','Wed Hour','Wed Minute','Thu Hour','Thu Minute','Fri Hour','Fri Minute','Sat Hour','Sat Minute'],
      minMode => 'Passive',
      dataRange => [[0,127],[0,23],[0,59],[0,23],[0,59],[0,23],[0,59],[0,23],[0,59],[0,23],[0,59],[0,23],[0,59],[0,23],[0,59]],
      code => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
   },
   SetDayTime => {
      serialSequence => [168,'Day','Hour','Minute'],
      minMode => 'Passive',
      code => ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
   },
   Power => {
      serialSequence => [133],
      minMode => 'Passive',
      setMode => 'Passive'
   }
};

sub new
{
   my $class = shift;
   my $self = {
      device 	=> (shift || '/dev/iRobot'),
      mode	=> 'Off',
      autoMode	=> 0,
      ledBits	=> 0,
      color	=> 0,
      intensity	=> 255
   };
   bless($self);
   return($self);
}

sub initPort
{
   my $self = shift;
   print "IRobot::ROI->initPort() BEGIN\n" if $self->{debug};
   my $port;
   my $retries = 5;
   while(!$port && $retries > 0)
   {
      $port = Device::SerialPort->new($self->{device});
      unless($port) { sleep(1) ; $retries-- }
   }
   if($retries > 0) {
      $port->databits(8);
      $port->baudrate(115200);
      $port->parity('none');
      $port->stopbits(1);
      $port->read_char_time(0);
      $port->read_const_time(15);
      $self->{port} = $port;
      print "IRobot::ROI->initPort() END\n" if $self->{debug};
      return(1);
   } else {
      die "Could not initialize port: $!";
   }
}

sub write
{
   my $self = shift;
   print "IRobot::ROI->write() BEGIN\n" if $self->{debug};
   my $data = pack('C*',@_);
   $self->initPort unless($self->{port});
   print "Writing bytes: " . join(", ",@_) . "\n" if $self->{debug};
   $self->{port}->write($data);
   print "IRobot::ROI->write() END\n" if $self->{debug};
}

use vars '$AUTOLOAD';
sub AUTOLOAD
{
   my($self, @dataBytes) = @_;
   my $command = $AUTOLOAD;
   $command =~ s/.*:://;
   print "IRobot::ROI->AUTOLOAD($command) BEGIN\n" if $self->{debug};

   my $opCode = ${$dispatch->{$command}->{serialSequence}}[0];
   my $requiredDataBytes = scalar @{$dispatch->{$command}->{serialSequence}} - 1;

   # Verify Command Validity
   unless($dispatch->{$command})
   {
      print "Unknown command: $command\n";
      print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
      return(0);
   }

   print "opCode: ", $opCode, "\n" if $self->{debug} > 1;
   print "dataBytes: ", $requiredDataBytes, "\n" if $self->{debug} > 1;
   print "minMode: ", $dispatch->{$command}->{minMode}, "\n" if $self->{debug} > 1;

   # Verify Data Length
   unless(scalar @dataBytes == $requiredDataBytes)
   {
      print "Expected $requiredDataBytes data bytes, but received ", scalar @dataBytes, "\n";
      print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
      return(0);
   }

   # Verify Data Byte Ranges
   if($dispatch->{$command}->{dataRange})
   {
      for my $x (0..$#dataBytes) {
	 my $min = $dispatch->{$command}->{dataRange}[$x][0];
	 my $max = $dispatch->{$command}->{dataRange}[$x][1];
	 if($min > $dataBytes[$x] || $dataBytes[$x] > $max) {
	    print "$dispatch->{$command}->{serialSequence}[$x+1] ($dataBytes[$x]) is out of range ($min - $max)\n";
	    print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	    return(0);
	 }
      }
   }

   # Verify Mode
   print "Current mode: ", $self->{mode}, "\n" if $self->{debug} > 1;
   if($mode->{$self->{mode}} < $mode->{$dispatch->{$command}->{minMode}})
   {
      if($self->{autoMode}) {
	 my $minMode = $dispatch->{$command}->{minMode};
	 unless($self->$minMode) {
	    print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	    return(0);
	 }
      } else {
	 print "We're in $self->{mode} mode and $command requires $dispatch->{$command}->{minMode} or higher.  If you don't want to worry about modes, please set the 'autoMode' flag.\n";
	 print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	 return(0);
      }
   }

   # Actually Send Command to Roomba
   if($self->write($opCode, @dataBytes)) {
      $self->{mode} = $dispatch->{$command}->{setMode} if($dispatch->{$command}->{setMode});
      $dispatch->{$command}->{state} = \@dataBytes;
      print "IRobot::ROI->AUTOLOAD($command) END\n" if $self->{debug};
      return(1);
   } else {
      print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
      return(1);
   }
}

1;
