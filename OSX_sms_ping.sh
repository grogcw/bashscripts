#!/bin/bash

### ping ###
/sbin/ping -t 1 -q -c 1 server > /dev/null
retval=$?

# If value = 2 (fail) [0 is succes] then send msg
if [ $retval -eq 2 ]; then
/usr/local/bin/wget -O - -q "https://smsapi.free-mobile.fr/sendmsg?user=00000000&pass=TOKEN&msg=Hostname%20down%20%21"
fi
