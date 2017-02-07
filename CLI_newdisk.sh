#!/bin/bash
cd /
read -e -p 'Mountpoint : ' mount
if [ -d "$mount" ]; then
while true; do
	read -p 'Are you sure about mountpoint = '$mount' ? [Y/N]' yn
	case $yn in
		[Yy]* ) echo "Creating default folders...";
		mkdir $mount/\@ANIME;
		mkdir $mount/\@DOWN_PROGS;
		mkdir $mount/\@MOVIES;
		mkdir $mount/\@MUSIC;
		mkdir $mount/\@SERIES;
		echo "Folders created !"
		break;;

		[Nn]* ) exit;;

		* ) echo Yes or No ?
	esac
done
else
echo $mount "doesn't exists !"
fi
