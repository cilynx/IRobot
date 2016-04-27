#!/usr/bin/perl

package IRobot::ROI;

use strict;
use Device::SerialPort;

my $spec = {
   R500OI 	=> 'Roomba 500 Open Interface Specification',
   COI2		=> 'Create Open Interface v2',
};

my $dispatch = {
   Reset => {
      serialSequence => [7],
      minMode => 'Off',
      setMode => 'Off',
      description => 'This command resets the robot, as if you had removed and reinserted the battery.',
      spec => ['R500OI']
   },
   Start => {
      serialSequence => [128],
      setMode => 'Passive',
      description => 'This command starts the OI.  You must always send the start command before sending any other commands to the OI.',
      spec => ['COI2','R500OI']
   },
   Passive => {
      serialSequence => [128],
      setMode => 'Passive',
      description => "There is no 'Passive' command in the iRobot specs.  This method calls the Start method.  It's only here to make development easier.",
      spec => ['COI2','R500OI']
   },
#   Baud => {
#      serialSequence => [129,'Baud Code'],
#      minMode => 'Passive',
#      dataRange => [[0,11]],
#      description => "This command sets the baud rate in bits per second (bps) at which OI commands and data are sent according to the baud code sent in the data byte. The default baud rate at power up is 57600 bps, but the starting baud rate can be changed to 19200 by holding down the Play button while powering on Create until you hear a sequence of descending tones. Once the baud rate is changed, it persists until Create is power cycled by pressing the power button or removing the battery, or when the battery voltage falls below the minimum required for processor operation.  You must wait 100ms after sending this command before sending additional commands at the new baud rate.\n\nNote: at a baud rate of 115200, there must be at least 200μs between the onset of each character, or some characters may not be received.",
#      spec => ['COI2','R500OI']
#   },
   Control => {
      serialSequence => [130],
      setMode => 'Passive',
      description => 'The effect and usage of the Control command (130) is identical to the Safe command. The Control command is deprecated but is present for backward compatibility with the Roomba Open Interface. Use Safe command instead.',
      spec => ['COI2','R500OI']
   },
   Safe => {
      serialSequence => [131],
      minMode => 'Passive',
      setMode => 'Safe',
      description => 'This command puts the OI into Safe mode, enabling user control of Roomba.  It turns off all LEDs.  The OI can be in Passive, Safe, or Full mode to accept this command.  If safety condition occurs, Roomba reverts automatically to Passive mode.',
      spec => ['COI2','R500OI']
   },
   Full => {
      serialSequence => [132],
      minMode => 'Passive',
      setMode => 'Full',
      description => 'This command gives you complete control over Roomba by putting the OI into Full mode, and turning off the cliff, wheel-drop and internal charger safety feat ures.  That is, in Full mode, Roomba executes any command that you send it, even if the internal charge r is plugged in, or command triggers a cliff or wheel drop condition.',
      spec => ['COI2','R500OI']
   },
   Power => {
      serialSequence => [133],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   Spot => {
      serialSequence => [134],
      minMode => 'Passive',
      setMode => 'Passive',
      spec => ['COI2','R500OI']
   },
   Clean => {
      serialSequence => [135],
      minMode => 'Passive',
      setMode => 'Passive'
   },
   Cover => {
      serialSequence => [135],
      minMode => 'Passive',
      setMode => 'Passive',
      description => 'This command starts the Cover demo.',
      spec => ['COI2']
   },
   Max => {
      serialSequence => [136],
      minMode => 'Passive',
      setMode => 'Passive',
      spec => ['R500OI']
   },
   Demo => {
      serialSequence => [136,'Which-demo'],
      minMode => 'Passive',
      setMode => 'Passive',
      description => 'This command starts the requested built-in demo.',
      dataRange => [[-1,9]],
      code => ['Cover','Cover and Dock','Spot Cover','Mouse','Figure Eight','Wimp','Home'],
      spec => ['COI2']
   },
   Drive => {
      serialSequence => [137,'Velocity high byte','Velocity low byte','Radius high byte','Radius low byte'],
      minMode => 'Safe',
      dataRange => [[0,255],[0,255],[0,255],[0,255]],
      description => "This command controls Create’s drive wheels. It takes four data bytes, interpreted as two 16-bit signed values using two’s complement. The first two bytes specify the average velocity of the drive wheels in millimeters per second (mm/s), with the high byte being sent first. The next two bytes specify the radius in millimeters at which Create will turn. The longer radii make Create drive straighter, while the shorter radii make Create turn more. The radius is measured from the center of the turning circle to the center of Create. A Drive command with a positive velocity and a positive radius makes Create drive forward while turning toward the left. A negative radius makes Create turn toward the right. Special cases for the radius make Create turn in place or drive straight, as specified below. A negative velocity makes Create drive backward.\n\nNOTE: Internal and environmental restrictions may prevent Create from accurately carrying out some drive commands.  For example, it may not be possible for Create to drive at full speed in an arc with a large radius of curvature.",
      spec => ['COI2','R500OI'],
      easySequence => ['Velocity','Radius'],
      easyRange => [[-500,500],[-2000,2000]],
      easyTransform => sub { unpack("C2",pack("n!",shift)) }
   },
   Motors => {
      serialSequence => [138,'Motors'],
      minMode => 'Safe',
      code => ['Side Brush','Vacuum','Main Brush','Side Brush Direction','Main Brush Direction',undef,undef,undef],
      spec => ['R500OI']
   },
   LowSideDrivers => {
      serialSequence => [138,'Driver Bits'],
      minMode => 'Safe',
      description => 'This command lets you control the three low side drivers.  The state of each driver is specified by one bit in the data byte.\n\nLow side drivers 0 and 1 can provide up to 0.5A of current.  Low side driver 2 can provide up to 1.5A of current.  If too much current is requested, the current is limited and the overcurrent flag is set (Sensor Packet 14).',
      code => ['Low Side Driver 0 (pin 23)','Low Side Driver 1 (pin 22)','Side Driver 2 (pin 24)'],
      spec => ['COI2']
   },
   LEDs => {
      serialSequence => [139,'LED Bits','Clean/Power Color','Clean/Power Intensity'],
      minMode => 'Safe',
      dataRange => [[0,15],[0,255],[0,255]],
      description => "This command controls the LEDs on Create. The state of the Play and Advance LEDs is specified by two bits in the first data byte. The power LED is specified by two data bytes: one for the color and the other for the intensity.",
      code => ['Debris','Spot','Dock','Check Robot'],
      spec => ['COI2','R500OI'],
   },
#   Song => {
#      serialSequence => [140,'Song Number','Song Length','Note Number 1','Note Duration 1','Note Number 2','Note Duration 2'],
#      minMode => 'Passive',
#      spec => ['COI2','R500OI']
#   },
#   PlaySong => {
#      serialSequence => [141,'Song Number'],
#      minMode => 'Passive'
#   },
   Sensors => {
      serialSequence => [142,'Packet ID'],
      minMode => 'Passive',
      dataRange => [[0,107]],
      description => "This command requests the OI to send a packet of sensor data bytes.  There are 43 different sensor data packets.  Each provides a value of a specific sensor or group of sensors.",
      spec => ['COI2','R500OI']
   },
   SeekDock => {
      serialSequence => [143],
      minMode => 'Passive',
      setMode => 'Passive',
      spec => ['R500OI']
   },
   CoverAndDock => {
      serialSequence => [143],
      minMode => 'Passive',
      setMode => 'Passive',
      description => 'This command starts the Cover and Dock demo.',
      spec => ['COI2']
   },
   PWMMotors => {
      serialSequence => [144,'Main Brush PWM','Side Brush PWM','Vacuum PWM'],
      minMode => 'Safe',
      dataRange => [[-127,127],[-127,127],[0,127]],
      spec => ['R500OI']
   },
   PWMLowSideDrivers => {
      serialSequence => [144,'Low Side Driver 2 Duty Cycle','Low Side Driver 1 Duty Cycle','Low Side Driver 0 Duty Cycle'],
      minMode => 'Safe',
      dataRange => [[0,128],[0,128],[0,128]],
      spec => ['COI2']
   },
   DriveDirect => {
      serialSequence => [145,'Right velocity high byte','Right velocity low byte','Left velocity high byte','Left velocity low byte'],
      minMode => 'Safe',
      dataRange => [[0,255],[0,255],[0,255],[0,255]],
      description => "This command lets you control the forward and backward motion of Create’s drive wheels independently. It takes four data bytes, which are interpreted as two 16-bit signed values using two’s complement. The first two bytes specify the velocity of the right wheel in millimeters per second (mm/s), with the high byte sent first. The next two bytes specify the velocity of the left wheel, in the same format.  A positive velocity makes that wheel drive forward, while a negative velocity makes it drive backward.",
      spec => ['COI2','R500OI'],
      easySequence => ['Right Velocity','Left Velocity'],
      easyRange => [[-500,500],[-500,500]],
      easyTransform => sub { unpack("C2",pack("n!",shift)) }
   },
#   DrivePWM => {
#      serialSequence => [146,'Right PWM high byte','Right PWM low byte','Left PWM high byte','Left PWM low byte'],
#      minMode => 'Safe',
#      dataRange => [[-255,-255],[-255,-255],[-255,255],[-255,255]]
#   },
   DigitalOutputs => {
      serialSequence => [147,'Output Bits'],
      minMode => 'Safe',
      description => 'This command controls the state of the 3 digital output pins on the 25 pin Cargo Bay Connector.  The digital outputs can provide up to 20 mA of current.',
      code => ['digital-out-0 (pin 19)','digital-out-1 (pin 7)','digital-out-2 (pin 20)'],
      spec => ['COI2']
   },
   Stream => {
      serialSequence => [148,'Number of Packets','Packet IDs'],
      minMode => 'Passive',
      description => "This command starts a continuous stream of data packets.  The list of packets requested is sent every 15 ms, which is the rate iRobot Create uses to update data.\n\nThis is the best method of requesting sensor data if you are controlling Create over a wireless network (which has poor real-time characteristics) with software running on a desktop computer.",
      spec => ['COI2','R500OI']
   },
   QueryList => {
      serialSequence => [149,'Number of Packets','Packet IDs'],
      minMode => 'Passive',
      description => "This command lets you ask for a list of sensor packets.  The result is returned once, as in the Sensors command.  The robot returns the packets in the order you specify.\n\nExample:\n\nTo get the state of the left cliff sensor (packet 9) and the Virtual Wall detector (packet 13), send the following sequence: [149][2][9][13]",
      spec => ['COI2','R500OI']
   },
   PauseResumeStream => {
      serialSequence => [150,'Stream State'],
      minMode => 'Passive',
      dataRange => [[0,1]],
      description => "This command lets you stop and restart the stream without clearing the list of requested packets.",
      spec => ['COI2','R500OI']
   },
   SendIR => {
      serialSequence => [151,'Byte Value'],
      minMode => 'Safe',
      dataRange => [[0,255]],
      description => "This command sends the requested byte out of low side driver 1 (pin 23 on the Cargo Bay Connector), using the format expected by iRobot Create’s IR receiver. You must use a preload resistor (suggested value: 100 ohms) in parallel with the IR LED and its resistor in order turn it on.",
      spec => ['CIO2']
   },
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

sub Help($)
{
   my($self, $parm) = @_;
   print "\n";
   if($dispatch->{$parm}) {
      print "$parm\n\n$dispatch->{$parm}->{description}\n";
   } else {
      my @commands;
      foreach my $command (keys %$dispatch) {
	 push(@commands, $command) if grep { $_ eq $parm } @{$dispatch->{$command}->{spec}};
      }
      if(@commands) {
	 print "", $spec->{$parm}, ":\n\n", join(', ',sort @commands), "\n\nHelp [Command] for more details.\n";
      } else {
	 if($parm) {
	    print "I don't know anything about '$parm'.\n";
	 } else {
	    print "Specifications:\n\n", join(', ', sort keys %$spec), "\n\nCommands:\n\n", join(', ', sort keys %$dispatch), "\n\nHelp [Spec / Command] for more details.\n";
	 }
      }
   }
   print "\n";
}

sub new($)
{
   my $class = shift;
   my $self = {
      device 	=> (shift || '/dev/iRobot'),
      mode	=> 'Off',
      autoMode	=> 0,
      ledBits	=> 0,
      color	=> 0,
      intensity	=> 255,
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

   # Verify Spec
   if($self->{spec})
   {
      unless(grep { $_ eq $self->{spec} } @{$dispatch->{$command}->{spec}}) {
	 print "Command ($command) is not available in ", $spec->{$self->{spec}}, "\n";
	 print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	 return(0);
      }
   }

   my $opCode = ${$dispatch->{$command}->{serialSequence}}[0];
   my $requiredDataBytes = scalar @{$dispatch->{$command}->{serialSequence}} - 1;
   my $easyInputs = scalar @{$dispatch->{$command}->{easySequence}} if($dispatch->{$command}->{easySequence});

   print "opCode: ", $opCode, "\n" if $self->{debug} > 1;
   print "dataBytes: ", $requiredDataBytes, "\n" if $self->{debug} > 1;
   print "minMode: ", $dispatch->{$command}->{minMode}, "\n" if $self->{debug} > 1;

   # Verify Data Length
   if(scalar @dataBytes == $requiredDataBytes) {
      # We're in good shape with a traditional call.  Carry on.
   } elsif(grep { $_ eq 'Packet IDs' } @{$dispatch->{$command}->{serialSequence}}) {
      # We're in good shape with an unbounded call.  Carry on.
   } elsif(scalar @dataBytes == $easyInputs) {
      if($dispatch->{$command}->{easyRange}) {
	 for my $x (0..$#dataBytes) {
	    my $min = $dispatch->{$command}->{easyRange}[$x][0];
	    my $max = $dispatch->{$command}->{easyRange}[$x][1];
	    if($min > $dataBytes[$x] || $dataBytes[$x] > $max) {
	       print "$dispatch->{$command}->{easySequence}[$x] ($dataBytes[$x]) is out of range ($min - $max)\n";
	       print "IRobot::ROI->AUTOLOAD($command) PUNT\n" if $self->{debug};
	       return(0);
	    }
	 }
      }
      my @easyDataBytes;
      foreach (@dataBytes) { push(@easyDataBytes, $dispatch->{$command}->{easyTransform}->($_)); }
      @dataBytes = @easyDataBytes;
   } else {
      if($easyInputs) {
	 print "Expected $requiredDataBytes dataBytes or $easyInputs easyInputs, but received ", scalar @dataBytes, " parameters\n";
      } else {
	 print "Expected $requiredDataBytes data bytes, but received ", scalar @dataBytes, "\n";
      }
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
