#!/bin/bash
# Remove all but the last two working kernels
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
##########################################################################

OLD=$(ls -tr /boot/vmlinuz-* | head -n -2 | cut -d- -f2- | awk '{print "linux-image-" $0}')
KEEP=$(ls -t /boot/vmlinuz-* | head -n 2 | cut -d- -f2- | awk '{print "linux-image-" $0}')
#if [ -n "$OLD" ]; then sudo apt-get -q remove --purge $OLD; fi
if [ -n "$OLD" ]; then
    # let user know
    echo ""
    echo "The following kernels will be kept:"
    echo "$KEEP"
    echo "-----------------------------------"
    echo "These kernels will be removed:"
    echo "$OLD"
    echo "-----------------------------------"
    echo "Press Enter to continue (Ctrl+C to cancel)"
    read
    echo "Running:"
    echo " sudo apt-get remove --purge "$OLD""
    sudo apt-get remove --purge $OLD
else
    echo ""
    echo "The following kernels were found:"
    echo "$KEEP"
    echo "-----------------------------------"
    echo "No kernels were found that can be removed."
fi
