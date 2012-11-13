#!/bin/bash
# parms:
#       channel year
#
# Download all logs for the channel for the given year
#
for option in "$@"; do
    case "$option" in
    -h | --help)
    echo "Download irclogs from any ubuntu channel for a specific year"
    echo "Usage: bash getlogs.sh channel year month"
    echo "For example, to download logs from #ubuntu in 2012,"
    echo "and store them in ~/irclogs/ubuntu/2012/ ..."
    echo "       bash getfullyear.sh ubuntu 2012"
    exit 0 ;;
    esac
done

local_dir="$(dirname "$(readlink /proc/$$/fd/255)")"
getlogs_script="$local_dir"/getlogs.sh
if [ ! -f "$getlogs_script" ]; then
  error "Script "$getlogs_script" is missing"
  exit 1
fi



# strip off any leading # from the channel name
channel=${1##\#}

# check the 4 digit year is numeric and >= 2004
year=$2
if ! [[ "$year" =~ ^[0-9]+$ ]] ; then
  exec >&2
  echo "Year $year has to be a valid year"
  exit 1
fi
if [ $year -lt 2004 ]; then
  exec >&2
  echo "Earliest year is 2004; inputted value invalid:$year "
  exit 1  
fi

. "$getlogs_script" $1 $2 1 y
. "$getlogs_script" $1 $2 2 y
. "$getlogs_script" $1 $2 3 y
. "$getlogs_script" $1 $2 4 y
. "$getlogs_script" $1 $2 5 y
. "$getlogs_script" $1 $2 6 y
. "$getlogs_script" $1 $2 7 y
. "$getlogs_script" $1 $2 8 y
. "$getlogs_script" $1 $2 9 y
. "$getlogs_script" $1 $2 10 y
. "$getlogs_script" $1 $2 11 y
. "$getlogs_script" $1 $2 12 y

