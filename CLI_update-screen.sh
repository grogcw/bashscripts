#!/bin/bash
screen -S "update-screen" -d -m
screen -r "update-screen" -X stuff $'sudo apt update -qy\nsudo apt upgrade -qy\nsudo apt autoclean -qy\nexit\n'
