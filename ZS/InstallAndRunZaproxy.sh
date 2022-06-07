#!/bin/bash

# Install, Run and Sumarise Zap reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> ZAP config file path inside the scanned repository
# $3 --> Aditional Zap command line arguments
# $4 --> Target to analyse
# $5 --> Debug mode

DEBUG=$5

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    debug_dir="Reports/Debug/ZapScan"
    mkdir -p $debug_dir
fi

# Directory configuration
dir="Reports/ZapScan"
assets="$1"

volume="zap/wrk/"

mkdir -p $volume

docker ps

if [ $2 != "" ] 
then
    docker run --user root -v $(pwd):/$volume/:rw --network="host" -t owasp/zap2docker-stable zap-full-scan.py -t $4 -c "$2" -J ZapReport.json $3
    ret=$?
else
    docker run --user root -v $(pwd):/$volume/:rw --network="host" -t owasp/zap2docker-stable zap-full-scan.py -t $4 -J ZapReport.json $3
    ret=$?
fi

mkdir -p $dir
python3 -m pip install Jinja2
python3 $assets/ZapReporting.py ZapReport.json $assets $dir/ZapReport.html

if [ $DEBUG = "true" ]
then
    mv ZapReport.json $debug_dir
fi

exit $ret