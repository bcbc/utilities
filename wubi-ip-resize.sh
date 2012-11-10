#!/bin/bash
# Increase the size of the a wubi virtual disk (root.disk)
# 
# This script resizes a wubi virtual disk in place. It can't be
# mounted so this should be run from a live CD/USB or another
# install.
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
version=1.0
virtualdisk=

usage () 
{
    cat <<EOF
Usage: sudo bash $0 [options] | wubi_virtual_disk [size in GB]
       e.g. sudo bash $0 --help (print this message)
       e.g. sudo bash $0 /host/ubuntu/disks/new.disk 10 (resize new.disk to 10GB)
       e.g. sudo bash $0 --version (print version number)

Resize the wubi virtual disk size  
  -h, --help              print this message and exit
  --version               print the version information and exit
EOF
}

# Check the arguments.
for option in "$@"; do
    case "$option" in
    -h | --help)
    usage
    exit 0 ;;
    --version)
    echo "$0: Version $version"
    exit 0 ;;
    -v | --verbose)
    echo "$0: Verbose option selected"
    verbose=true
    ;;
   -*)
    echo "$0: Unrecognized option '$option'. (--help for usage instructions)"
    exit 1
    ;;
# Get the new size in GB
    *[^0-9]*)
        if test "x$virtualdisk" != x; then
          echo "$self: Too many parameters" 1>&2
          usage
          exit 1
        else
          virtualdisk="${option}"
        fi
        ;;
    *)
    if test "x$size" != x; then
          echo "$0: Too many parameters"
          exit 1
    else
          size="${option}"
          size_entered=true
    fi
    ;;
    esac
done

# Check it's a standard wubi loopmounted install 
# The size must be valid and between 5GB and the default maximum size 
# unless the --max-override option is supplied.
# There must be sufficient space on /host for the new disk
# including a remaining space buffer of 5% of total disk size

    if [ "$(whoami)" != root ]; then
        echo "$0: Admin rights are required to run this program." 
        exit 1
    fi

    while read DEV MTPT FSTYPE OPTS REST; do
        case "$DEV" in
          /dev/loop/*|/dev/loop[0-9])
            loop_file=`losetup "$DEV" | sed -e "s/^[^(]*(\([^)]\+\)).*/\1/"`
            if  [ "$loop_file" = "$virtualdisk" ]; then
                echo "$0: "$virtualdisk" is mounted - please unmount and try again" 1>&2
                exit 1
            fi
          ;;
        esac
    done < /proc/mounts

            # Force fsck and correct without prompt 
            # Ignore exit codes:
            #    0 - no problem
            #    1 - errors corrected.
            fsck -fp "$virtualdisk" > /dev/null # just let errors show
            if [ "$?" -gt 1 ]; then
              echo "$0: Cancelling resize - fsck failed"
              exit 1
            fi
            resize2fs "$virtualdisk" "$size"G > /dev/null # this is actually gibibytes
            if [ "$?" -ne 0 ]; then
              echo "$0: Resize of "$virtualdisk" to "$size"G failed"
              exit 1
            fi
            new_size=$(du -b "$virtualdisk" 2> /dev/null | cut -f 1)
            new_size=`echo "$new_size / 1000000000" | bc`  #assumes made by this program, otherwise will underreport
            echo "$0: "$virtualdisk" resized to "$new_size" GB"
     

exit 0
