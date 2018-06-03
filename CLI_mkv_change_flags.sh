#!/bin/bash
#
#   Requires mkvtoolnix
#
#   Usage : bash mkv_change_flags.sh <directory>
#
#

OIFS="$IFS"
IFS=$'\n'
for file in $1*.mkv
do

# Show filename being processed
echo $file

# Change theese settings according to mkvinfo
# 
# Example below un-sets enabled, default and forced flags for track 2 & 4, and sets unable & default for track 3

mkvpropedit "${file}" --edit track:2 --set flag-forced=0
mkvpropedit "${file}" --edit track:2 --set flag-enabled=0
mkvpropedit "${file}" --edit track:2 --set flag-default=0

mkvpropedit "${file}" --edit track:4 --set flag-default=0
mkvpropedit "${file}" --edit track:4 --set flag-enabled=0
mkvpropedit "${file}" --edit track:4 --set flag-forced=0

mkvpropedit "${file}" --edit track:3 --set flag-forced=0
mkvpropedit "${file}" --edit track:3 --set flag-enabled=1
mkvpropedit "${file}" --edit track:3 --set flag-default=1

done
IFS="$OIFS"
