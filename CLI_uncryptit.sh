#!/bin/bash

##### Check dependencies #####
# -> for Zip
command -v zip >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : Zip not installed (Whaaaaaat ?!)${NC}"
        exit
fi
# -> for OpenSSL
command -v openssl >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : OpenSSL not installed !${NC}"
        exit
fi

##### Verifiying if there's an argument in command #####
# -> for filename
if [ -z "$1" ];
        then printf "\nUsage : uncryptit <filename> '<password>'\n\n";
        exit;
fi
# -> for password
if [ -z "$2" ];
        then printf "\nUsage : uncryptit <filename> '<password>'\n\n";
        exit;
fi

##### Variables #####

############# Folders definitions #############
#                                             #
#     /!\ Set folder in absolute path /!\     #
# /!\ Don't forget the slash at the end ! /!\ #
#                                             #
###############################################
target_dir="TARGET_DIR"

##### Decrypting #####
openssl enc -aes-256-cbc -d -in $target_dir$1 -out $target_dir$1".zip" -k $2 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : Encryption problem !${NC}"

        # -> Breaking zip
        dd if=/dev/zero of=$target_dir$1".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

        # -> Deleting zip
        rm $target_dir$1".zip"
	exit
fi

##### Type of deflate, comment the right one ! #####

# -> deflate keeping file structure and replacing
#unzip -o $target_dir$1".zip"  > /dev/null 2>&1

# -> deflate in target_dir
unzip -o $target_dir$1".zip" -d $target_dir  > /dev/null 2>&1

##### Breaking and cleaning zip file #####
# -> Breaking zip
dd if=/dev/zero of=$target_dir$1".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

# -> Deleting zip
rm $target_dir$1".zip"

#echo ""
#echo "Decrypted file : "$1
#echo ""
