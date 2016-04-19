# IRobot
Pure Perl implementation of the iRobot Roomba 500 Open Interface Spec.  Very much WIP.  LEDs are confirmed functional because I can play with those without waking up my family in the middle of the night =)

```perl
#!/usr/bin/perl

use IRobot::ROI;

my $robot = IRobot::ROI->new('/dev/ttyUSB0');

$robot->{debug} = 1;

$robot->SpotLedToggle;
while(1)
{  
   $robot->SpotLedToggle;
   $robot->DebrisLedToggle;
   sleep(1);
   $robot->DebrisLedToggle;
   $robot->DockLedToggle;
   sleep(1);
   $robot->DockLedToggle;
   $robot->CheckLedToggle;
   sleep(1);
   $robot->CheckLedToggle;
   $robot->SpotLedToggle;
   sleep(1);
}
```
