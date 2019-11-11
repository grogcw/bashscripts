#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

OUTPUT=/folder/icecast.pem

echo -e "${YELLOW}Getting Cert and PrivKey from certbot${NC}"
echo ""

CERT=/etc/letsencrypt/live/<domain>/cert.pem
if test -f "$CERT";
then
	echo -e "${GREEN}$CERT exist !${NC}"
	echo ""
else
	echo -e "${RED}$CERT doesn't exist !${NC}"
	exit
fi

PRIVKEY=/etc/letsencrypt/live/<domain>/privkey.pem
if test -f "$PRIVKEY";
then
	echo -e "${GREEN}$PRIVKEY exist !${NC}"
	echo ""
else
	echo -e "${RED}$PRIVKEY doesn't exist !${NC}"
	exit
fi

#CONCATENATING (Yes, that simple...but safe !)
cat $CERT $PRIVKEY > $OUTPUT

if test -f "$OUTPUT";
then
	echo -e "${GREEN}$OUTPUT OK !${NC}"
	exit
else
        echo -e "${RED}Output to $OUTPUT error !${NC} (permission problem ?)"
        exit
fi
