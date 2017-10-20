#!/bin/bash
##### Color definitions #####
RED='\033[0;31m'
BLUE='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

##### Check dependencies #####
# -> for Zip
command -v zip >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error : Zip not installed (Whaaaaaat ?!)${NC}"
	exit
fi
# -> for OpenSSL
command -v openssl >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error : OpenSSL not installed !${NC}"
	exit
fi

##### Variables #####

############# Folders definitions #############
#                                             #
#     /!\ Set folder in absolute path /!\     #
# /!\ Don't forget the slash at the end ! /!\ #
#                                             #
###############################################
source_dir="SOURCE_DIR"
target_dir="TARGET_DIR"

# Defines filenames based on date
date_now=$(date +"%Y-%m-%d_%H-%M")
output_file="Backup_$date_now"
enc_file="$output_file.enc"

##### Verifiying if there's an argument in command #####
if [ -z "$1" ];
        then printf "\nUsage : cryptit '<password>'\n\n";
        exit;
fi

##### Now, some art. #####
echo -e "${RED}                             __  ${BLUE} __ ${GREEN}__ "
echo -e "${RED}  _____ _____ __  __ ____   / /_ ${BLUE}/ /${GREEN}/ /_"
echo -e "${RED} / ___// ___// / / // __ \ / __/${BLUE}/ /${GREEN}/ __/"
echo -e "${RED}/ /__ / /   / /_/ // /_/ // /_ ${BLUE}/_/${GREEN}/ /_  "
echo -e "${RED}\___//_/    \__, // .___/ \__/${BLUE}(_) ${GREEN}\__/  "
echo -e "${RED}           /____//_/                    "
echo -e "${NC}"

##### Zipping #####
zip -r $target_dir$output_file".zip" $source_dir > /dev/null 2>&1

##### Encrypting #####
openssl enc -aes-256-cbc -salt -in $target_dir$output_file".zip" -out $target_dir$enc_file -k $1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error : Encryption problem !${NC}"

	# -> Breaking zip
	dd if=/dev/zero of=$target_dir$output_file".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

	# -> Deleting zip
	rm $target_dir$output_file".zip"
	exit
fi

##### Break temp files and remove #####

# -> Breaking zip
dd if=/dev/zero of=$target_dir$output_file".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

# -> Deleting zip
rm -rf $target_dir$output_file".zip"

echo "Encryption succesfull : "$enc_file
echo ""

##### Some dev stuff #####
#echo "passwd : "$1
#echo "date_now : "$date_now
#ls $target_dir
