#!/bin/bash
### DEFINE DOMAIN AND USER DIRECTORY ###
DOMAIN="MY_DOMAIN"
TOKEN="MY_TOKEN"

# -> DON'T PUT ANY SLASH AT PATH END !
userdir="/USER/DIRECTORY"

### CREATE FILES & DIRS ###
mkdir $userdir/duckdns
touch $userdir/duckdns/duck.sh
touch $userdir/duckdns/duck.log

# -> POURING SCRIPT
echo "echo url=\"https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=\" | curl -k -o $userdir/duckdns/duck.log -K -" > $userdir/duckdns/duck.sh

# -> MAKING SCRIPT EXECUTABLE
chmod 700 $userdir/duckdns/duck.sh
chmod +x $userdir/duckdns/duck.sh

### CRONTAB MODIFY ###

# -> EXPORT CRONTAB
crontab -l > $userdir/duckdns/crontab.txt

# -> ECHO IN CRONTAB TEMP
echo '' >> $userdir/duckdns/crontab.txt
echo '### DUCKDNS CRON JOB ###' >> $userdir/duckdns/crontab.txt
echo "*/5 * * * * $userdir/duckdns/duck.sh >/dev/null 2>&1" >> $userdir/duckdns/crontab.txt
echo '' >> $userdir/duckdns/crontab.txt

# -> REPLACE CRONTAB BY THE MODIFIED ONE
crontab $userdir/duckdns/crontab.txt

# -> DELETE TEMP CRONTAB
rm $userdir/duckdns/crontab.txt

### SCRIPT FIRST STARTUP ###
$($userdir/duckdns/duck.sh > /dev/null 2>&1)

# -> CHECK IF WORKING // MUST BE OK
cat $userdir/duckdns/duck.log
printf "\n"
