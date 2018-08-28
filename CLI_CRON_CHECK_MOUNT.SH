#!/bin/bash

### Check FOLDER Mount ###
if /bin/mount | /bin/grep /mnt/FOLDER > /dev/null;
then
	echo "MUSIC_DATA MOUNT OK !"
else
	echo "MUSIC_DATA MOUNT NOT OK !"
fi
