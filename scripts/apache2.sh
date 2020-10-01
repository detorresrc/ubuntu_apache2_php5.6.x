#!/bin/bash
source /usr/local/bin/envvars
while true
do
    /usr/local/bin/apachectl -DFOREGROUND
    sleep 1
done