#/bin/bash

#DEFINES MOUNTFOLDER & IP_POOL
MOUNTFOLDER=/mnt

IP_POOL="192.168.0."
echo "IP Pool is "$IP_POOL"XXX"

#ASKS IP TERMINATION
read -p "IP Address (enter or q to quit) : " IP_ADDRESS_TERM

if [ -z "$IP_ADDRESS_TERM" ] || [[ "$IP_ADDRESS_TERM" = "q" ]] || [[ "$IP_ADDRESS_TERM" = "Q" ]];
	then
exit
	else

#CHECK IF IP IS CORRECT
stat=0

IP_ADDRESS=$IP_POOL$IP_ADDRESS_TERM

if [[ $IP_ADDRESS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=1
fi

if [[ $stat = 1 ]]; then

#TRY TO CONNECT
smbclient -L $IP_ADDRESS -N -m SMB2

#CHECK COMMAND SUCCESS
retval=$?
if [ $retval -ne 0 ]; then
    exit
fi

#ASK FOR SHARENAME
read -p "Sharename (enter or q to quit) : " SHARENAME
if [ -z "$SHARENAME" ] || [[ "$SHARENAME" = "q" ]] || [[ "$SHARENAME" = "Q" ]];
        then
exit
fi

#ASK FOR USERNAME - GUEST IS DEFAULT
read -p "Username [GUEST] : " USERNAME
USERNAME=${USERNAME:-GUEST}

#ASK FOR PASSWORD - GUEST IS DEFAULT
read -p "Password [GUEST] : " PASSWORD
PASSWORD=${PASSWORD:-GUEST}

#CREATES MOUNTPOINT
mkdir /mnt/"$SHARENAME"

#MOUNTS
mount -t cifs -o user=$USERNAME,password=$PASSWORD,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=2.1,sec=ntlm "//"$IP_ADDRESS/"$SHARENAME" $MOUNTFOLDER/"$SHARENAME"

#CHECKS IF SUCCESS
retval=$?
if [ $retval -ne 0 ]; then
	exit
fi

#SAVES MOUNTPOINT TO log_mountscript.log
echo \"$MOUNTFOLDER/"$SHARENAME"\" > log_mountscript.log

echo "Mounting of "$MOUNTFOLDER"/"$SHARENAME" succesful !"

else
echo "Invalid ip"
exit
fi
fi
