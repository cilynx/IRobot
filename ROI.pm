#!/usr/bin/perl

package IRobot::ROI;

use strict;

use Device::SerialPort;

sub new
{
   my $class = shift;
   my $self = {
      device 	=> (shift || '/dev/iRobot'),
      mode	=> 'Off',
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

=head1 METHODS

Open Interface Command Reference

The following is a list of all of Roomba's Open Interface commands.  Each command starts with a one-
byte opcode.  Some of the commands must be followed by data bytes.  All of Roomba's OI commands
including their required data bytes are described below.

NOTE:

Always send the required number of data bytes for the command, otherwise, the processor will enter and
remain in a "waiting" state until all of the required data bytes are received.

=head2 Getting Started Commands

The following commands start the Open Interface and get it ready for use.

=item IRobot::ROI->Start()

This command starts the OI.  You must always send the Start command before sending any other 
commands to the OI.

Serial sequence: [128]
Available in modes: Passive, Safe, or Full
Changes mode to: Passive.  Roomba beeps once to acknowledge it is starting from "off" mode.

=cut

sub Start
{
   my $opCode = 128;
   my $self = shift;
   print "IRobot::ROI->Start() BEGIN\n" if $self->{debug};
   $self->{mode} = 'Passive' if $self->write($opCode);
   print "IRobot::ROI->Start() END\n" if $self->{debug};
}

=item IRobot::ROI->Baud($baudCode)

This command sets the baud rate in bits per second (bps) at which OI commands and data are sent 
acconding to the baud code sent in the data byte.  The default baud rate at power up is 115200 bps, but
the starting baud rate can be changed to 19200 by holding down the Clean button while powering on
Roomba until you hear a sequence of descending tones.  Once the baud rate is changed, it persists until
Roomba is power cycled by pressing the power button or removing the battery, or when the battery
voltage falls below the minimum requerid for processor operation.  You must wait 100ms after sending
this command before sending additional commands at the new baud rate.

Serial sequence: [129][Baud Code]
Available in modes: Passive, Safe, or Full
Changes mode to: No Change
Baud data byte 1: Baud Code (0-11)

Baud Code	Baud Rate in BPS
0		300
1		600
2		1200
3		2400
4		4800
5		9600
6		14400
7		19200
8		28800
9		38400
10		57600
11		115200

=cut 

sub Baud
{
   my $opCode = 129;
   my($self, $baudCode) = @_;
   print "IRobot::ROI->Baud() BEGIN\n" if $self->{debug};
   if(0 <= $baudCode && $baudCode <= 11) {
      $self->Start if $self->{mode} eq 'Off';
      $self->write($opCode, $baudCode);
      sleep(1);
      print "IRobot::ROI->Baud() END\n" if $self->{debug}; 
      return(1);
   } else {
      print "Baud Code ($baudCode) is out of range (0-11):

      Baud Code       Baud Rate in BPS
      0               300
      1               600
      2               1200
      3               2400
      4               4800
      5               9600
      6               14400
      7               19200
      8               28800
      9               38400
      10              57600
      11              115200";
      print "IRobot::ROI->Baud() END\n" if $self->{debug}; 
      return(0);
   }
}

=head2 Mode Commands

Roomba has four operating modes: Off, Passive, Safe, and Full.  Roomba powers on in the Off mode.  The
following commands change Roomba's OI mode.

=item IRobot::ROI->Safe()

This command puts the OI into Safe mode, enabling user control of Roomba.  It turns off all LEDs.  The OI
can be in Passive, Safe, or Full mode to accept this command.  IF a safety condition occurs (see above)
Roomba reverts automatically to Passive mode.

Serial sequence: [131]
Available in modes: Passive, Safe, Full
Changes mode to: Safe

Note: The effect and usage of the Control command (130) are identical to the Safe command.

=cut

sub Control
{
   my $opCode = 130;
   my $self = shift;
   print "IRobot::ROI->Control() BEGIN\n" if $self->{debug}; 
   $self->Start if $self->{mode} eq 'Off';
   $self->{mode} = 'Safe' if $self->write($opCode);
   print "IRobot::ROI->Control() END\n" if $self->{debug}; 
}

sub Safe
{
   my $opCode = 131;
   my $self = shift;
   print "IRobot::ROI->Safe() BEGIN\n" if $self->{debug}; 
   $self->Start if $self->{mode} eq 'Off';
   $self->{mode} = 'Safe' if $self->write($opCode);
   print "IRobot::ROI->Safe() END\n" if $self->{debug}; 
}

=item IRobot::ROI->Full()

This command gives you complete control over Roomba by putting the OI into Full mode, and turning off
the cliff, wheel-drop and internal charger safety features.  That is, in Full mode, Roomba executes any 
command that you send it, even if the internal charger is plugged in, or command triggers and cliff or wheel
drop condition.

Serial sequence: [132]
Available in modes: Passive, Safe, or Full
Changes mode to: Full

Note: Use the Start command (128) to change the mode to Passive.

=cut

sub Full
{
   my $opCode = 132;
   my $self = shift;
   print "IRobot::ROI->Full() BEGIN\n" if $self->{debug};
   $self->Start if $self->{mode} eq 'Off'; 
   $self->{mode} = 'Full' if $self->write($opCode);
   print "IRobot::ROI->Full() END\n" if $self->{debug}; 
}

=head2 Actuator Commands

The following commands control Roomba's actuators: wheels, brushes, vacuum, speaker, LEDS, and
buttons.

=item IRobot::ROI->Drive($velocity, $radius)

This command controls Roomba's drive wheels.  It takes four data bytes, interpreted as two 16-bit signed
values using two's complement.  The first two bytes specify the average velocity of the drive wheels in 
millimeters per second (mm/s), with the high byte being sent first.  The next two bytes specify the radius
in millimeters at which Roomba will turn.  The longer radii make Roomba driver straighter, while the 
shorter radii make Roomba turn more.  The radius is measured from the center of the turning circle to the
center of Roomba.  A Drive command with a positive velocity and a positive radius makes Roomba drive 
forward while turning toward the left.  A negative radius makes Roomba turn toward the right.  Special
cases for the radius make Roomba turn in place or drive straight, as specified below.  A negative velocity
makes Roomba drive backward.

NOTE:

Internal and environmental restrictions may prevent Roomba from accurately carrying out some drive
commands.  For example, it make not be possible for Roomba to drive at full speed in an arc with a large 
radius of curvature.

Serial sequence: [137][Velocity high byte][Velocity low byte][Radius high byte][Radius low byte]
Available in modes: Safe or Full
Changes mode to: No Change
Velocity (-500 - 500 mm/s)
Radius (-2000 - 2000 mm)

Special Cases:

Straight = 32768 or 32767 = hex 8000 or 7FFF
Turn in place clockwise = -1
Turn in place counter-clockwise = 1

Example:

To drive in reverse at a velocity for -200 mm/s while turning at a radius of 500mm, send the following
serial byte sequence:

[137][255][56][1][244]

Velocity = -200 = hex FF38 = [hex FF][hex 38] = [255][56]
Radius = 500 = hex 01F4 = [hex 01][hex F4] = [1][244]

=cut

sub Drive
{
   die "Not yet implemented";
   my $opCode = 137;
   my($self, $velocity, $radius) = @_;
   print "IRobot::ROI->Drive() BEGIN\n" if $self->{debug};
   $self->Safe unless($self->{mode} eq 'Safe' || $self->{mode} eq 'Full'); 
   $self->write($opCode);
   print "IRobot::ROI->Drive() END\n" if $self->{debug};
}

=item LEDs

This command controls the LEDs common to all models of Roomba 500.  The clean/Power LED is 
specified by two data bytes: one for the color and the other for the intensity.

Serial sequence: [139][LED Bits][Clean/Power Color][Clean/Power Intensity]
Available in modes: Safe or Full
Changes to mode to: No Change
LED Bits (0-255)

Home and Spot use green LEDs: 0 = off, 1= on
Check Robot uses an orange LED.
Debris uses a blue LED.
Clean/Power uses a bicolor (red/green) LED.  The intensity and color of this LED can be controlled with 
8-bit resolution.

LED Bits (0-255)

Bit	Value
7	Reserved
6	Reserved
5	Reserved
4	Reserved
3	Check Robot
2	Dock
1	Spot
0	Debris

Clean / Power LED Color (0-255)

0 = green, 255 = red.  Intermediate values are intermediate colors (orange, yellow, etc).

Clean / Power LED Intensity (0-255)

0 = off, 200 = full intensity.  Intermediate values are intermediate intensities.

Example:

To turn on the Home LED and light the Clean / Power LED green at half intensity, send the serial byte
sequence [139][4][0][128]

=cut

sub LEDs
{
   my $opCode = 139;
   my($self, $ledBits, $color, $intensity) = @_;
   print "IRobot::ROI->LEDs() BEGIN\n" if $self->{debug};
   $self->Safe unless($self->{mode} eq 'Safe' || $self->{mode} eq 'Full'); 
   if($self->write($opCode, $ledBits, $color, $intensity))
   {
      $self->{ledBits} = $ledBits;
      $self->{color} = $color;
      $self->{intensity} = $intensity;
   }
   print "IRobot::ROI->LEDs() END\n" if $self->{debug};
}

sub DebrisLedOn
{
   my $bitMask = 1;
   my $self = shift;
   print "IRobot::ROI->DebrisLedOn() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} | $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DebrisLedOn() END\n" if $self->{debug};
}

sub DebrisLedOff
{
   my $bitMask = 15 - 1;
   my $self = shift;
   print "IRobot::ROI->DebrisLedOff() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} & $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DebrisLedOff() END\n" if $self->{debug};
}

sub DebrisLedToggle
{
   my $bitMask = 1;
   my $self = shift;
   print "IRobot::ROI->DebrisLedToggle() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} ^ $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DebrisedToggle() END\n" if $self->{debug};
}

sub SpotLedOn
{  
   my $bitMask = 2;
   my $self = shift;
   print "IRobot::ROI->SpotLedOn() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} | $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->SpotLedOn() END\n" if $self->{debug};
}

sub SpotLedOff
{  
   my $bitMask = 15 - 2;
   my $self = shift;
   print "IRobot::ROI->SpotLedOff() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} & $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->SpotLedOff() END\n" if $self->{debug};
}

sub SpotLedToggle
{  
   my $bitMask = 2;
   my $self = shift;
   print "IRobot::ROI->SpotLedToggle() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} ^ $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->SpotLedToggle() END\n" if $self->{debug};
}

sub DockLedOn
{  
   my $bitMask = 4;
   my $self = shift;
   print "IRobot::ROI->DockLedOn() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} | $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DockLedOn() END\n" if $self->{debug};
}

sub DockLedOff
{  
   my $bitMask = 15 - 4;
   my $self = shift;
   print "IRobot::ROI->DockLedOff() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} & $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DockLedOff() END\n" if $self->{debug};
}

sub DockLedToggle
{
   my $bitMask = 4;
   my $self = shift;
   print "IRobot::ROI->DockLedToggle() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} ^ $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->DockLedToggle() END\n" if $self->{debug};
}

sub CheckLedOn
{  
   my $bitMask = 8;
   my $self = shift;
   print "IRobot::ROI->CheckLedOn() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} | $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->CheckLedOn() END\n" if $self->{debug};
}

sub CheckLedOff
{  
   my $bitMask = 15 - 8;
   my $self = shift;
   print "IRobot::ROI->CheckLedOff() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} & $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->CheckLedOff() END\n" if $self->{debug};
}

sub CheckLedToggle
{  
   my $bitMask = 8;
   my $self = shift;
   print "IRobot::ROI->CheckLedToggle() BEGIN\n" if $self->{debug};
   $self->LEDs($self->{ledBits} ^ $bitMask, $self->{color}, $self->{intensity});
   print "IRobot::ROI->CheckLedToggle() END\n" if $self->{debug};
}

1;
