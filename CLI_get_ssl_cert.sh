#!/bin/bash

SERVERNAME=$(echo $1 | cut -d ":" -f1)
THE_PORT=$(echo $1 | sed 's/.*://')

### TEST DEPENDENCIES ###
#-- OPENSSL --#
command -v openssl >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "Error : openssl is missing, please install openssl package."
        exit
fi

#-- PARAMS CHECK --#
if [[ $SERVERNAME = "" ]]; then
        echo -e "Error, SERVER parameter is missing !"
        echo -e "Usage : get_ssl_cert.sh SERVER:PORT"
        exit
fi

if ! [[ $THE_PORT =~ [0-9] ]]; then
        echo -e "Error, PORT parameter is missing !"
        echo -e "Usage : get_ssl_cert.sh SERVER:PORT"
        exit
fi

echo -n | openssl s_client -servername $SERVERNAME -connect $SERVERNAME:$THE_PORT | openssl x509 > $SERVERNAME.cert
