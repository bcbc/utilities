#!/bin/bash
# Dell N4010 brightness control workaround
# Note: add the following to /etc/rc.local
#       chmod 777 /sys/class/backlight/intel_backlight/brightness
# For convenience I've assigned the keys Alt-Up and Alt-Down to run this script
# Fine tune the bump parameter as required
#
# Usage:
#    ./brightchg.sh up   # bump up brightness
#    ./brightchg.sh down # bump down brightness
#
curr=`cat /sys/class/backlight/intel_backlight/brightness`
bump=244
if [ "$1" == "up" ]; then
  curr=`echo "$curr + $bump" | bc`
else
  curr=`echo "$curr - $bump" | bc`
fi
echo $curr | tee /sys/class/backlight/intel_backlight/brightness
