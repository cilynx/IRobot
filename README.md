# IRobot
Pure Perl implementation of the iRobot Roomba 500 Open Interface Spec.  Very much WIP.  LEDs are confirmed functional because I can play with those without waking up my family in the middle of the night =)

```perl
#!/usr/bin/perl 

use strict;
use warnings;

use IRobot::ROI;

my $robot = IRobot::ROI->new('/dev/ttyUSB0');

# Show debug info
$robot->{debug} = 1;

# Automatically change modes as necessary for commands to work
$robot->{autoMode} = 1;

my $command = shift;
$robot->$command(@ARGV);

# Set cleaning schedule for 3:00 PM on Wednesdays and 10:36 AM on Fridays
#$robot->Schedule(40,0,0,0,0,0,0,15,0,0,0,10,36,0,0);

# Disable scheduling
#$robot->Schedule(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

# Set Day/Time to 10:25 AM on Wednesday
#$robot->SetDayTime(3,10,25);
```
