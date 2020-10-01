#!/bin/bash
if [ $# -eq 0 ]
 	then
		echo -e "\nNo input file specified\n"
fi

if [ $# -eq 1 ]
	then
		echo -e "\nNo output file specified\n"
fi

if [ $# -ne 2 ]
	then
		echo -e "Usage : mov_to_webm.sh <input> <output>\n"
		exit
fi

ffmpeg -i $1 -c:v libvpx-vp9 -pix_fmt yuva420p $2
