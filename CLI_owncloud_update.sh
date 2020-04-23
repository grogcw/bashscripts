#!/bin/bash

### CONFIG ###
owncloud_dir=/var/www

### COLOR DEFINITIONS ###
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

#-- TEST COMMAND --#

# wget
command -v wget >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error${NC} : ${YELLOW}wget${NC} is missing, please install ${YELLOW}wget${NC} package."
	exit
fi

# Unzip
command -v unzip >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
	echo -e "${RED}Error${NC} : ${YELLOW}unzip${NC} is missing, please install ${YELLOW}unzip${NC} package."
	exit
fi

# STARTUP #
echo ""
echo -e "${YELLOW}Owncloud Updater${NC}"
echo "by Grogcw"
echo ""

read -e -p "Url to fetch Owncloud's latest ZIPPED version from (enter or q to quit) : `echo $'\n> '`" targeturl

if [ -z "$targeturl" ] || [[ "$targeturl" = "q" ]] || [[ "$targeturl" = "Q" ]];
	then
exit
	else
echo ""
wget $targeturl -O $owncloud_dir/owncloud-latest.zip
	if [ $? -ne 0 ]; then
		echo ""
		echo "Error while fetching file."
		exit 1
	fi
fi

read -p "Proceed update ? [Y/N]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Nn]$ ]]
then
	exit 1
fi

mv $owncloud_dir/owncloud $owncloud_dir/owncloud-bck

unzip $owncloud_dir/owncloud-latest.zip -d $owncloud_dir

rm $owncloud_dir/owncloud-latest.zip

cp $owncloud_dir/owncloud-bck/config/config.php $owncloud_dir/owncloud/config/config.php
cp -r $owncloud_dir/owncloud-bck/data $owncloud_dir/owncloud/data
chown -R www-data:www-data $owncloud_dir/owncloud

echo ""
read -p "Is Owncloud successfully updated ? (I can wait...) [Y/N]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	rm -rf $owncloud_dir/owncloud-bck/
else
	echo "Reverting to previous version."
	mv $owncloud_dir/owncloud/ $owncloud_dir/owncloud-update_pending/
	mv $owncloud_dir/owncloud-bck/ $owncloud_dir/owncloud/
	echo "Files are kept in $owncloud_dir/owncloud-update_pending/"
fi
