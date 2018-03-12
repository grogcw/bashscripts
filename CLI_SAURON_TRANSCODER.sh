#!/bin/bash
############ SAURON TRANSCODER ############

### SETUP VARIABLES ###
sourcedir=/TRANSCODE_WATCH ### /!\ NO END SLASH IN PATH
targetdir=/MUSIC_DATA ### /!\ NO END SLASH IN PATH

##### COLOR DEFINITIONS #####
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

### TEST DEPENDENCIES ###
#-- INOTIFYWAIT --#
command -v inotifywait >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error${NC} : ${YELLOW}inotifywait${NC} is missing, please install ${YELLOW}inotify-tools${NC} package."
        exit
fi
#-- FFMPEG-NORMALIZE --#
command -v ffmpeg-normalize >/dev/null 2>&1 || if [[ $? -ne 0 ]] ; then
        echo -e "${RED}Error${NC} : ${YELLOW}ffmpeg-normalize${NC} is missing, please install via ${YELLOW}pip3 install ffmpeg-normalize${NC}."
        exit
fi

#-- SOURCEDIR --#
if [ ! -d "$sourcedir" ]; then
        echo -e "${RED}Error${NC} : sourcedir missing !"
        exit
fi

#-- TARGETDIR --#
if [ ! -d "$targetdir" ]; then
        echo -e "${RED}Error${NC} : targetdir missing !"
        exit
fi

### GO TO SOURCEDIR TO EXECUTE ###
cd $sourcedir

### LURK SOME FILE TO BE CLOSED AFTER WRITING ###
inotifywait -m -r $sourcedir -e close_write |

### DAEMONISE ! ###
while read path action file; do

### SUBDIR VARIABLE FORGING ###
subdir=${path//$sourcedir/}

### UNCOMMENT TO SHOW EVENTS (DEBUG) ###
#echo "The file '$file' appeared in directory '$path' via '$action'"
#echo "$subdir"
#echo "$sourcedir$subdir$file"

### MAKE SUBDIR IN TARGETDIR ###
mkdir $targetdir$subdir

### TRANSCODE FILE AND OUTPUT IN TARGETDIR'S SUBFOLDER ###
echo "Starting transcoding $file"
ffmpeg-normalize "$sourcedir$subdir$file" -c:a libmp3lame -b:a 128k -nt ebu -t -12 -vn -sn -f -v -o "$targetdir$subdir$file"
echo "Finished transcoding $file"

### DELETE SUBDIR AND FILE FROM SOURCEDIR ###
rm -rf .$subdir
echo "SAURON TRANSCODER -- HIT CTRL-C TO END"
done
