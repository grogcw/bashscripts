#!/bin/sh
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:0.0

rsync -av --delete "SOURCE/" "DESTINATION/" > MY_LOG.log

date >> MY_LOG.log
