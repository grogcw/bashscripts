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
fi

mv $owncloud_dir/owncloud $owncloud_dir/owncloud-bck

unzip $owncloud_dir/owncloud-latest.zip -d $owncloud_dir

cp $owncloud_dir/owncloud-bck/config/config.php $owncloud_dir/owncloud/config/config.php
cp -r $owncloud_dir/owncloud-bck/data $owncloud_dir/owncloud/data
chown -R www-data:www-data $owncloud_dir/owncloud

echo ""
read -p "Is Owncloud successfully updated ? (I can wait...) [Y/N]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	rm $owncloud_dir/owncloud-latest.zip
	rm -rf $owncloud_dir/owncloud-bck/
fi
