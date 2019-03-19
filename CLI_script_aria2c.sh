#!/bin/bash

##### COLOR DEFINITIONS #####
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#-- TEST COMMAND --#
command -v aria2c >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error${NC} : ${YELLOW}aria2c${NC} is missing, please install ${YELLOW}aria2c${NC} package."
	exit
fi

#STARTUP
echo ""
echo -e "${YELLOW}aria2c list downlodaer${NC}"
echo "by Grogcw"
echo ""

#ASKS LIST TO DOWNLOAD
unset options i
while IFS= read -r -d $'\0' f; do
	options[i++]="$f"
done < <( find ./ -maxdepth 1 -type f -name "*.txt" -print0 )
#if [ -z "${options[0]}" ]
#then
#	echo -e "${RED}No valid .txt list found in current directory,${NC} exiting."
#	exit
#fi
select opt in "${options[@]}" "Paste" "Quit"; do
	case $opt in
		*.txt)
			echo "$opt selected"
			break
			;;
		"Paste")
printf "\n"
read -d "@" -p "Paste links here (then press \"@\" when done) :
" paste
			echo "$paste" > ./Paste
printf "\n"
			break
			;;
		"Quit")
			#echo "You chose to stop"
			exit
			;;
		*)
			echo "Wrong item selected"
			;;
	esac
done

#CHECK IF FILE IS EMPTY
if [ -f $opt ]
then
	if ! [ -s $opt ]
	then
		echo "File exists but empty."
		exit
	fi
	count=$(wc -c < $opt)
	if [ $count -lt 4 ]
	then
		echo "File is empty."
		exit
	fi
else
	echo "File not exists."
	exit
fi

#ASKS DOWNLOAD DESTINATION
read -e -p "Download Folder (enter or q to quit) : " targetdir

if [ -z "$targetdir" ] || [[ "$targetdir" = "q" ]] || [[ "$targetdir" = "Q" ]];
	then
exit
	else

#-- TARGETDIR --#
if [ ! -d "$targetdir" ]; then
	echo -e "${RED}Error${NC} : $targetdir is wrong or missing !"
	exit
fi

aria2c -d $targetdir -j5 -i $opt -c --save-session out.txt
has_error=`wc -l < out.txt`

while [ $has_error -gt 0 ]
do
	echo "still has $has_error errors, rerun aria2 to download ..."
	aria2c -j5 -i $opt -c --save-session out.txt
	has_error=`wc -l < out.txt`
	sleep 10
done
if [ ! -s ./out.txt ] ; then
	rm ./out.txt
	rm $opt
fi
fi
