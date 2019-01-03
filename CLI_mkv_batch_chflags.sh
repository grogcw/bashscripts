#!/bin/bash
#
#   Requires mkvtoolnix
#
#   Usage : bash mkv_batch_chflags.sh <directory>
#
#   To configure see the SETTINGS section below.
#


### TEST DEPENDENCIES ###
#-- MKVPROPEDIT --#
command -v mkvpropedit >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error${NC} : ${YELLOW}mkvpropedit${NC} is missing, please install ${YELLOW}mkvtoolnix${NC} package."
        exit
fi
#-- MKVINFO --#
command -v mkvinfo >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error${NC} : ${YELLOW}mkvinfo${NC} is missing, please install ${YELLOW}mkvtoolnix${NC} package."
        exit
fi

### CHECK ARGUMENT PRESENCE ###
if [[ -z $1 ]]
	then
        echo -e "${RED}Error${NC} : No folder provided in argument, please specify a folder."
	exit
fi

### CHECK FOLDER ###
if [ ! -d $1 ]; then
        echo -e "${RED}Error${NC} : folder $1 incorrect or missing. (Wrong path ?)"
        exit
fi

### ASKS IF SURE OF CONFIG ###
clear
echo -e "-- Batch change MKV flags ---"
echo ""
echo -e "Warning !"
echo ""
echo -e "This tool is about to modify ALL mkv files contained in folder $1."
echo -e "You must edit its settings according to mkvinfo."
echo ""
read -e -p "Are you sure of its config (Y/N) ? " IS_SURE
echo ""

if [[ "$IS_SURE" = "y" ]] || [[ "$IS_SURE" = "Y" ]]; then

OIFS="$IFS"
IFS=$'\n'
for file in $1*.mkv
do

#-- Show filename being processed --#
echo $file


### SETTINGS ###

#  Change theese settings according to mkvinfo
#
#  Example below un-sets enabled, default and forced flags
#  for track 2 & 4, and sets unable & default for track 3
#
#  You can add or delete lines below according to mkvpropedit syntax
#
#  Echos are only here for keeping track of progress and eye candy.

echo ""
echo -e "Pass 1"
echo ""
echo -e "Disabling track 2 force flag."
mkvpropedit "${file}" --edit track:2 --set flag-forced=0
echo -e "Disabling track 2 enabled flag."
mkvpropedit "${file}" --edit track:2 --set flag-enabled=0
echo -e "Disabling track 2 default flag."
mkvpropedit "${file}" --edit track:2 --set flag-default=0

echo ""
echo -e "Pass 2"
echo ""
echo -e "Disabling track 4 default flag."
mkvpropedit "${file}" --edit track:4 --set flag-default=0
echo -e "Disabling track 4 enabled flag."
mkvpropedit "${file}" --edit track:4 --set flag-enabled=0
echo -e "Disabling track 4 forced flag."
mkvpropedit "${file}" --edit track:4 --set flag-forced=0

echo ""
echo -e "Pass 3"
echo ""
echo -e "Disabling track 3 forced flag."
mkvpropedit "${file}" --edit track:3 --set flag-forced=0
echo -e "Enabling track 3 enabled flag."
mkvpropedit "${file}" --edit track:3 --set flag-enabled=1
echo -e "Enabling track 3 default flag."
mkvpropedit "${file}" --edit track:3 --set flag-default=1
### END OF SETTINGS ###

done
IFS="$OIFS"

else
echo "Exiting."
exit

fi
