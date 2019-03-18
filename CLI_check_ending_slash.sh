#!/bin/bash

# This snippet checks for ending slash in the argument ($1)

slash="/"
if ! [[ "$1" =~ '/'$ ]]; then
        input=$1$slash
else
        input=$1
fi
echo $input
