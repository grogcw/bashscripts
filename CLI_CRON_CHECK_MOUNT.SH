#!/bin/bash

### Check FOLDER Mount ###
if /bin/mount | /bin/grep /mnt/FOLDER > /dev/null;
then
	echo "FOLDER MOUNT OK !"
else
	echo "FOLDER MOUNT NOT OK !"
fi
