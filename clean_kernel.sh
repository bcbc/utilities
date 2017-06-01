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

# If you keep a single kernel there is some risk because kernels are
# sometimes updated, not just replaced. If you about to do a release
# upgrade or you are installing a newer kernel, then keeping one is ok.
keep=2
quiet=false
options=q
version=0.1beta
usage ()
{
    cat <<EOF
Removes all but the 2 most recent linux kernels.

Options:
  --keep=num     Change the number of kernels to keep (1-9)
  --quiet        No prompt except for sudo (if required)
EOF
}

for option in "$@"; do
    case "$option" in
    -h | --help)
    usage
    exit 0 ;;
    --version)
    echo "$0: Version $version"
    exit 0 ;;
    --quiet)
      options=qq
      quiet=true
    ;;
    --keep=*)
        keep=`echo "$option" | sed 's/--keep=//'` ;;
    -*)
    echo "$0: Unrecognized option '$option'. (--help for usage instructions)"
    exit 1
    ;;
    *)
    echo "$0: Unrecognized argument '$option'. (--help for usage instructions)"
    exit 1
    ;;
  esac
done

if ! [[ "$keep" =~ ^[1-9]$ ]] ; then
  exec >&2
  echo "--keep= option only accepts values 1 to 9"
  exit 1
fi

OLD=$(ls -tr /boot/vmlinuz-* | grep -vi 'efi' | head -n -$keep | cut -d- -f2- | awk '{print "linux-image-" $0}')
KEEP=$(ls -t /boot/vmlinuz-* | grep -vi 'efi' | head -n $keep | cut -d- -f2- | awk '{print "linux-image-" $0}')
if [ -n "$OLD" ]; then
    # let user know
    echo ""
    echo "The following kernels will be kept:"
    echo "$KEEP"
    echo "-----------------------------------"
    echo "These kernels will be removed:"
    echo "$OLD"
    echo "-----------------------------------"
    if [ "$quiet" != "true" ]; then
        echo "Press Enter to continue (Ctrl+C to cancel)"
        read
    fi
    purge_command="sudo apt-get -"$options" remove --purge $OLD"
    echo "Running:"
    echo " "$purge_command""
    ${purge_command}
    echo "-----------------------------------"
    echo "Removing packages that are no longer needed"
    echo "and clean up unneeded packages from the cache..."
    echo "-----------------------------------"
    if [ "$quiet" != "true" ]; then
        echo "Press Enter to continue (Ctrl+C to cancel)"
        read
    fi
    autoremove_command="sudo apt-get -"$options" autoremove"
    echo "Running:"
    echo " "$autoremove_command""
    ${autoremove_command}
    autoclean_command="sudo apt-get -"$options" autoclean"
    echo ""
    echo "Running:"
    echo " "$autoclean_command""
    ${autoclean_command}
else
    echo ""
    echo "The following kernels were found:"
    echo "$KEEP"
    echo "-----------------------------------"
    echo "No kernels were found that can be removed."
fi
