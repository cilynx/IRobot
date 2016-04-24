# IRobot
Pure Perl implementation of the iRobot Roomba Open Interface Spec.  Most useful methods are working now, tested on a 500 series.  

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
