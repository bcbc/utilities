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
size=               # size of new virtual disk 
maxsize=32          # max size of new virtual disk
ignore_max=false    # override max size limit?
size_entered=false  # did the user enter the new size?
verbose=false       # verbose output

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
  --max-override          ignore maximum size constraint of 32GB
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
    --max-override)
    ignore_max=true
    ;;
    -*)
    echo "$0: Unrecognized option '$option'. (--help for usage instructions)"
    exit 1
    ;;
# Get the new size in GB
    *[^0-9]*)
        if test "x"$virtualdisk"" != x; then
          echo "$0: Too many parameters" 1>&2
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

### Present Y/N questions and check response 
### (a valid response is required)
### Parameter: the question requiring an answer
### Returns: 0 = Yes, 1 = No
test_YN ()
{
    while true; do
      echo "$@"
      read input
      case "$input" in
        "y" | "Y" )
          return 0 ;;
        "n" | "N" )
          return 1 ;;
        * )
          echo "Invalid response ('$input')"
      esac
    done
}

# Check it's a standard wubi loopmounted install 
# The size must be valid and between 5GB and the default maximum size 
# unless the --max-override option is supplied.
# There must be sufficient space on /host for the new disk
# including a remaining space buffer of 5% of total disk size
precheck()
{
    if [ "$(whoami)" != root ]; then
        echo "$0: Admin rights are required to run this program." 
        exit 1
    fi

    if [ ! -f "$virtualdisk" ]; then
        echo "$0: "$virtualdisk" not found" 1>&2
        exit 1
    fi

    if [ "$size_entered" != "true" ]; then
        echo "$0: Please enter the new size" 1>&2
        echo "$0: Use \"--help\" for usage instructions" 1>&2
        exit 1
    fi
    if [ $size -lt 5 ]; then
        echo "$0: The new disk must be at least 5GB." 1>&2
        exit 1
    fi
    if [ "$ignore_max" = "false" ]; then
        if [ $size -gt $maxsize ]; then
            echo "$0: The new size cannot exceed $maxsize G unless the"
            echo "$0: --max-override option is used (not recommended)."
            exit 1
        fi
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

# check available space where virtual disk is located 
# (derive mountpoint, check space)
    loop_file="$(readlink -e "$virtualdisk")" # get full path and file name
    mtpt="${loop_file%/*}"
    while [ -n "$mtpt" ]; do
        while read DEV MTPT FSTYPE OPTS REST; do
            if [ "$MTPT" = "$mtpt" ]; then
                loop_file=${loop_file#$MTPT}
                host_mountpoint=$MTPT
                break
            fi
        done < /proc/mounts
        mtpt="${mtpt%/*}"
        [ -z "$host_mountpoint" ] || break
    done
    if [ "$host_mountpoint" == "" ]; then
        host_mountpoint=/
    fi

# get free space in G; it returns the ceiling, we need the floor
    free_space=$(df -BG "$host_mountpoint" |tail -n 1|awk '{print $4}')
    free_space=${free_space%G}
    free_space=$((free_space - 1))
#    echo "Free space on host: "$free_space"G"

# leave this one as a ceiling - need some buffer anyway
    current_size=$(du -BG "$virtualdisk" | cut -f 1)
    current_size=${current_size%G}
#    echo "Current size: "$current_size"G"

# no space issue if reducing the size
    if [ $size -gt $current_size ]; then
        increased_size=$((size - current_size))
#        echo "Increased size: "$increased_size"G"
        if [ $increased_size -ge $free_space ]; then
            echo "$0: Not enough free space" 1>&2
            echo "$0: Free space on "$host_mountpoint": "$free_space"G" 1>&2
            echo "$0: Space required for resize: "$increased_size"G" 1>&2
            exit 1
        fi
    elif [ $size -lt $current_size ]; then
        echo "$0: Note:resize2fs checks for the minimum allowed size, but"
        echo "$0: it lists this as a 'known issue' so please check yourself."
    else
        echo "$0: "$virtualdisk" is already "$size"G" 1>&2
        exit 1
    fi
}

# Do an inplace resize of the supplied virtual disk
# 
resize()
{
    echo ""
    test_YN "$0: About to resize "$virtualdisk" from "$current_size"G to "$size"G. Continue? (Y/N)"
    # User pressed N
    if [ "$?" -eq "1" ]; then
       echo "$0: Canceled"
       exit 0
    fi


    # Force fsck and correct without prompt 
    # Exit codes:
    #    0 - no problem
    #    1 - errors corrected.
    echo "$0: Running required fsck on "$virtualdisk""
    fsck -fp "$virtualdisk" > /tmp/wubi-resize-output 2>&1
    if [ "$?" -gt 1 ]; then
        echo "$0: Cancelling resize - fsck failed"
        echo "Error is: $(cat /tmp/wubi-resize-output)"
        exit 1
    fi

    if [ "$verbose" == "true" ]; then
      echo "$(cat /tmp/wubi-resize-output)"
      echo ""
    fi

    echo "$0: Resizing "$virtualdisk"..."
    resize2fs "$virtualdisk" "$size"G > /tmp/wubi-resize-output 2>&1 # this is actually gibibytes
    if [ "$?" -ne 0 ]; then
        echo "$0: Resize of "$virtualdisk" to "$size"G failed"
        echo "Error is: $(cat /tmp/wubi-resize-output)"
        exit 1
    fi

    if [ "$verbose" == "true" ]; then
      echo "$(cat /tmp/wubi-resize-output)"
      echo ""
    fi

    # report new size
    new_size=$(du -BG --apparent-size "$virtualdisk" 2> /dev/null | cut -f 1)
    echo "$0: "$virtualdisk" resized to "$new_size""

}

precheck
resize
exit 0
