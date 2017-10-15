#!/bin/bash
##### Color definitions #####
RED='\033[0;31m'
NC='\033[0m' # No Color

##### Check dependencies #####
# -> for UnZip
command -v unzip >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : UnZip not installed (Whaaaaaat ?!)${NC}"
        exit
fi
# -> for OpenSSL
command -v openssl >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : OpenSSL not installed !${NC}"
        exit
fi

##### Verifiying if there's an argument in command #####
# -> for password
if [ -z "$1" ];
        then printf "\nUsage : uncryptit '<password>'\n\n";
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

# File definition
file=$(ls -t $target_dir | head -n 1)

##### Decrypting #####
openssl enc -aes-256-cbc -d -in $target_dir$file -out $target_dir$file".zip" -k $1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error : Encryption problem !${NC}"

        # -> Breaking zip
        dd if=/dev/zero of=$target_dir$file".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

        # -> Deleting zip
        rm $target_dir$file".zip"
        exit
fi

##### Type of deflate, comment the right one ! #####

# -> deflate keeping file structure and replacing
unzip -o $target_dir$file".zip" -d / > /dev/null 2>&1

# -> deflate in target_dir
#unzip -o $target_dir$file".zip" -d $target_dir  > /dev/null 2>&1

##### Breaking and cleaning zip file #####
# -> Breaking zip
dd if=/dev/zero of=$target_dir$file".zip" bs=1 count=8192 conv=notrunc,noerror > /dev/null 2>&1

# -> Deleting zip
rm $target_dir$file".zip"

echo ""
echo "Decrypted file : "$file
echo ""
