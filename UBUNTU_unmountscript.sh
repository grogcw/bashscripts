#/bin/bash

echo ""

echo "Unmounting..."
cat log_mountscript.log | xargs umount -n

retval=$?
if [ $retval -ne 0 ]; then
	echo "LOG DOESN'T EXISTS !"
	exit
fi

echo "Removing mountpoint..."
cat log_mountscript.log | xargs rm -rf

retval=$?
if [ $retval -ne 0 ]; then
	echo "MOUNTPOINT DOESN'T EXISTS !"
	exit
fi

echo "Deleting log..."
rm -rf log_mountscript.log

retval=$?
if [ $retval -ne 0 ]; then
	echo "CAN'T DELETE LOG !"
	exit
fi

echo ""
