#!/usr/bin/perl

package IRobot::ROI;

use strict;
use Device::SerialPort;

my $dispatch = {
   Reset => {
      serialSequence => [7],
      minMode => 'Off',
      setMode => 'Off'
   },
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
#   Baud => {
#      serialSequence => [129,'Baud Code'],
#      minMode => 'Passive',
#      dataRange => [[0,11]]
#   },
   Control => {
      serialSequence => [130],
      setMode => 'Passive'
   },
   Safe => {
      serialSequence => [131],
      minMode => 'Passive',
      setMode => 'Safe',
   },
#   Full => {
#      serialSequence => [132],
#      minMode => 'Passive',
#      setMode => 'Full'
#   },
   Power => {
      serialSequence => [133],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   Spot => {
      serialSequence => [134],
      minMode => 'Passive',
      setMode => 'Passive'
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
#   Drive => {
#      serialSequence => [137,'Velocity high byte','Velocity low byte','Radius high byte','Radius low byte'],
#      minMode => 'Safe',
#      dataRange => [[-500,500],[-500,500],[-2000,2000],[-2000,2000]]
#   },
#   Motors => {
#      serialSequence => [138,'Motors'],
#      minMode => 'Safe',
#      code => ['Side Brush','Vacuum','Main Brush','Side Brush Direction','Main Brush Direction',undef,undef,undef]
#   },
#   LowSideDrivers => {
#      serialSequence => [138,'Driver Bits'],
#      minMode => 'Safe',
#      code => ['Low Side Driver 0 (pin 23)','Low Side Driver 1 (pin 22)','Side Driver 2 (pin 24)']
#   },
   LEDs => {
      serialSequence => [139,'LED Bits','Clean/Power Color','Clean/Power Intensity'],
      minMode => 'Safe',
      dataRange => [[0,15],[0,255],[0,255]],
      code => ['Debris','Spot','Dock','Check Robot'],
   },
#   Song => {
#      serialSequence => [140,'Song Number','Song Length','Note Number 1','Note Duration 1','Note Number 2','Note Duration 2'],
#      minMode => 'Passive'
#   },
#   PlaySong => {
#      serialSequence => [141,'Song Number'],
#      minMode => 'Passive'
#   },
   Sensors => {
      serialSequence => [142,'Packet ID'],
      minMode => 'Passive',
      dataRange => [[0,107]]
   },
   SeekDock => {
      serialSequence => [143],
      minMode => 'Passive',
      setMode => 'Passive'
   },
#   PWMMotors => {
#      serialSequence => [144,'Main Brush PWM','Side Brush PWM','Vacuum PWM'],
#      minMode => 'Safe',
#      dataRange => [[-127,127],[-127,127],[0,127]]
#   },
#   DriveDirect => {
#      serialSequence => [145,'Right velocity high byte','Right velocity low byte','Left velocity high byte','Left velocity low byte'],
#      minMode => 'Safe',
#      dataRange => [[-255,-255],[-255,-255],[-255,255],[-255,255]]
#   },
#   DrivePWM => {
#      serialSequence => [146,'Right PWM high byte','Right PWM low byte','Left PWM high byte','Left PWM low byte'],
#      minMode => 'Safe',
#      dataRange => [[-255,-255],[-255,-255],[-255,255],[-255,255]]
#   },
#   DigitalOutputs => {
#      serialSequence => [147,'Output Bits'],
#      minMode => 'Safe',
#      code => ['digital-out-0 (pin 19)','digital-out-1 (pin 7)','digital-out-2 (pin 20)']
#   },
   Stream => {
      serialSequence => [148,'Number of Packets','Packet IDs'],
      minMode => 'Passive'
   },
   QueryList => {
      serialSequence => [149,'Number of Packets','Packet IDs'],
      minMode => 'Passive'
   },
   PauseResumeStream => {
      serialSequence => [150,'Stream State'],
      minMode => 'Passive',
      dataRange => [[0,1]]
   },
#   SendIR => {
#      serialSequence => [151,'Byte Value'],
#      minMode => 'Safe',
#      dataRange => [[0,255]]
#   },
#   Script => {
#      serialSequence => [152,'Script Length','Opcodes'],
#      minMode => 'Passive',
#      dataRange => [[0,100]]
#   },
#   PlayScript => {
#      serialSequence => [153],
#      minMode => 'Passive'
#   },
#   ShowScript => {
#      serialSequence => [154],
#      minMode => 'Passive'
#   },
#   WaitTime => {
#      serialSequence => [155,'Time'],
#      minMode => 'Passive',
#      dataRange => [[0,255]]
#   },
#   WaitDistance => {
#      serialSequence => [156,'Distance High Byte','Distance Low Byte'],
#      minMode => 'Passive',
#      dataRange => [[-255,255],[-255,255],[-255,255],[-255,255]]
#   },
#   WaitAngle => {
#      serialSequence => [157,'Angle High Byte','Angle Low Byte'],
#      minMode => 'Passive',
#      dataRange => [[-255,255],[-255,255],[-255,255],[-255,255]]
#   },
#   WaitEvent => {
#      serialSequence => [158,'Event Number'],
#      minMode => 'Passive',
#      dataRange => [[-22,22]],
#      code => [undef,'Wheel Drop','Front Wheel Drop','Left Wheel Drop','Right Wheel Drop','Bump','Left Bump','Right Bump','Virtual Wall','Wall','Cliff','Left Cliff','Front Left Cliff','Front Right Cliff','Right Cliff','Home Base','Advance Button','Play Button','Digital Input 0','Digital Input 1','Digital Input 2','Digital Input 3','OI Mode = Passive']
#   },
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
   Stop => {
      serialSequence => [173],
      minMode => 'Passive',
      setMode => 'Off'
   }
};

my $sensors = {
   BumpsAndWheelDrops => {
      packetId => 7,
      dataBytes => 1,
      code => ['Bump Right','Bump Left','Wheel Drop Right','Wheel Drop Left',undef,undef,undef,undef]
   },
   Wall => {
      packetId => 8,
      dataBytes => 1
   },
   CliffLeft => {
      packetId => 9,
      dataBytes => 1
   },
   CliffFrontLeft => {
      packetId => 10,
      dataBytes => 1
   },
   CliffFrontRight => {
      packetId => 11,
      dataBytes => 1
   },
   CliffRight => {
      packetId => 12,
      dataBytes => 1
   },
   VirtualWall => {
      packetId => 13,
      dataBytes => 1
   },
   WheelOvercurrents => {
      packetId => 14,
      dataBytes => 1,
      code => ['Side Brush',undef,'Main Brush','Right Wheel','Left Wheel',undef,undef,undef]
   },
   DirtDetect => {
      packetId => 15,
      dataBytes => 1
   },
   UnusedByte => {
      packetId => 16,
      dataBytes => 1
   },
   InfraredCharacterOmni => {
      packetId => 17,
      dataBytes => 1
   },
   Buttons => {
      packetId => 18,
      dataBytes => 1,
      code => ['Clean','Spot','Dock','Minute','Hour','Day','Schedule','Clock']
   },
   Distance => {
      packetId => 19,
      dataBytes => 2,
      signed => 1
   },
   Angle => {
      packetId => 20,
      dataBytes => 2,
      signed => 1
   },
   ChargingState => {
      packetId => 21,
      dataBytes => 1,
      code => ['Not Charging','Reconditioning Charging','Full Charging','Trickle Charging','Waiting','Charging Fault Condition']
   },
   Voltage => {
      packetId => 22,
      dataBytes => 2
   },
   Current => {
      packetId => 23,
      dataBytes => 2,
      signed => 1
   },
   Temperature => {
      packetId => 24,
      dataBytes => 1,
      signed => 1
   },
   BatteryCharge => {
      packetId => 25,
      dataBytes => 2
   },
   BatteryCapacity => {
      packetId => 26,
      dataBytes => 2
   },
   WallSignal => {
      packetId => 27,
      dataBytes => 2
   },
   CliffLeftSignal => {
      packetId => 28,
      dataBytes => 2
   },
   FrontCliffLeftSignal => {
      packetId => 29,
      dataBytes => 2
   },
   FrontCliffRightSignal => {
      packetId => 30,
      dataBytes => 2
   },
   CliffRightSignal => {
      packetId => 31,
      dataBytes => 2
   },
   Unused32 => {
      packetId => 31,
      dataBytes => 3
   },
   Unused33 => {
      packetId => 31,
      dataBytes => 3
   },
   ChargingSourcesAvailable => {
      packetId => 34,
      dataBytes => 1,
      code => ['Internal Charger','Home Base',undef,undef,undef,undef,undef,undef]
   },
   OIMode => {
      packetId => 35,
      dataBytes => 1,
      code => ['Off','Passive','Safe','Full']
   },
   SongNumber => {
      packetId => 36,
      dataBytes => 1
   },
   SongPlaying => {
      packetId => 37,
      dataBytes => 1
   },
   NumberOfStreamPackets => {
      packetId => 38,
      dataBytes => 1
   },
   RequestedVelocity => {
      packetId => 39,
      dataBytes => 2,
      signed => 1
   },
   RequestedRadius => {
      packetId => 40,
      dataBytes => 2,
      signed => 1
   },
   RequestedRightVelocity => {
      packetId => 41,
      dataBytes => 2,
      signed => 1
   },
   RequestedLeftVelocity => {
      packetId => 42,
      dataBytes => 2,
      signed => 1
   },
   RightEncoderCounts => {
      packetId => 43,
      dataBytes => 2
   },
   LeftEncoderCounts => {
      packetId => 44,
      dataBytes => 2
   },
   LightBumper => {
      packetId => 45,
      dataBytes => 2,
      code => ['Light Bumper Left','Light Bumper Front Left','Light Bumper Center Left','Light Bumper Center Right','Light Bumper Front Right','Light Bumper Right',undef,undef]
   },
   LightBumpLeftSignal => {
      packetId => 46,
      dataBytes => 2
   },
   LightBumpFrontLeftSignal => {
      packetId => 47,
      dataBytes => 2
   },
   LightBumpCenterLeftSignal => {
      packetId => 48,
      dataBytes => 2
   },
   LightBumpCenterRightSignal => {
      packetId => 49,
      dataBytes => 2
   },
   LightBumpFrontRightSignal => {
      packetId => 50,
      dataBytes => 2
   },
   LightBumpRightSignal => {
      packetId => 51,
      dataBytes => 2
   },
   InfraredCharacterLeft => {
      packetId => 52,
      dataBytes => 1
   },
   InfraredCharacterRight => {
      packetId => 53,
      dataBytes => 1
   },
   LeftMotorCurrent => {
      packetId => 54,
      dataBytes => 2,
      signed => 1
   },
   RightMotorCurrent => {
      packetId => 55,
      dataBytes => 2,
      signed => 1
   },
   MainBrushMotorCurrent => {
      packetId => 56,
      dataBytes => 2,
      signed => 1
   },
   SideBrushMotorCurrent => {
      packetId => 57,
      dataBytes => 2,
      signed => 1
   },
   Stasis => {
      packetId => 58,
      dataBytes => 1
   }
};

sub new($)
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

sub initPort($)
{
   my $self = shift;
   print "IRobot::ROI->initPort() BEGIN\n" if $self->{debug};
   $| = 1; # make unbuffered
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

sub read($$)
{
   my($self, $dataBytes) = @_;
   print "IRobot::ROI->read() BEGIN\n" if $self->{debug};
   while($dataBytes)
   {
      print "Reading data ($dataBytes bytes left to read)\n";
      my($count, $saw) = $self->{port}->read($dataBytes);
      print "Read bytes: " . join(", ",unpack('C*',$saw)) . "\n" if $self->{debug};
      $dataBytes -= $count;
   }
   print "IRobot::ROI->read() END\n" if $self->{debug};
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

   if($command eq 'Raw') {
      $self->write(@dataBytes);
      print "IRobot::ROI->AUTOLOAD($command) END\n" if $self->{debug};
      return(0);
   }

   # Verify Command Validity
   unless($dispatch->{$command})
   {
      if($sensors->{$command}) {
	 @dataBytes = ($sensors->{$command}->{packetId});
	 $command = 'Sensors';
      } else {
	 print "Unknown command: $command\n";
	 print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	 return(0);
      }
   }

   my $opCode = ${$dispatch->{$command}->{serialSequence}}[0];
   my $requiredDataBytes = scalar @{$dispatch->{$command}->{serialSequence}} - 1;

   print "opCode: ", $opCode, "\n" if $self->{debug} > 1;
   print "dataBytes: ", $requiredDataBytes, "\n" if $self->{debug} > 1;
   print "minMode: ", $dispatch->{$command}->{minMode}, "\n" if $self->{debug} > 1;

   # Verify Data Length
   unless(scalar @dataBytes == $requiredDataBytes || grep { $_ eq 'Packet IDs' } @{$dispatch->{$command}->{serialSequence}})
   {
      print "Expected $requiredDataBytes data bytes, but received ", scalar @dataBytes, "\n";
      print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
      return(0);
   }

   if(grep { $_ eq 'Packet IDs' } @{$dispatch->{$command}->{serialSequence}})
   {
      if($dataBytes[0] != $#dataBytes) {
	 print "Expected $dataBytes[0] Packet IDs, but received ", $#dataBytes, "\n";
      }
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
   my @modes = @{$sensors->{OIMode}->{code}};
   my($currentMode) = grep($modes[$_] eq $self->{mode}, 0..$#modes);
   my($requiredMode) = grep($modes[$_] eq $dispatch->{$command}->{minMode}, 0..$#modes);
   if($currentMode < $requiredMode)
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
      my @serialSequence = @{$dispatch->{$command}->{serialSequence}};
      if(grep { $_ =~ 'Packet ID' } @serialSequence)
      {
	 my $numberOfPackets = 1;
	 if(grep { $_ eq 'Packet IDs' } @serialSequence) {
	    $numberOfPackets = shift(@dataBytes);
	 }
	 while($numberOfPackets) {
	    my ($sensorName) = grep($sensors->{$_}->{packetId} eq $dataBytes[$numberOfPackets-1], keys %$sensors);
	    unless($sensorName) {
	       print "Unknown Packet ID: $dataBytes[$numberOfPackets-1]\n";
	       print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	       return(1);
	    }
	    print "$dataBytes[$numberOfPackets-1]: $sensorName: $sensors->{$sensorName}->{dataBytes}\n" if $self->{debug};
	    $self->read($sensors->{$sensorName}->{dataBytes});
	    $numberOfPackets--;
	 }
      }
      print "IRobot::ROI->AUTOLOAD($command) END\n" if $self->{debug};
      return(1);
   } else {
      print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
      return(1);
   }
}

1;
