#!/bin/bash

# To help debugging
set -x

# Install, Run and Sumarise Horusec reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Horusec config file path inside the scanned repository
# $3 --> Aditional horusec command line arguments

# Directory configuration
dir="Reports/VulnerabilityScan"
assets="$1"

docker run --rm -d -p 5050:5050 scan/scanimage:latest

volume="zap/wrk"

mkdir -p $volume

docker run --user root -v $(pwd):/$volume:rw --network="host" -t owasp/zap2docker-stable zap-full-scan.py \
    -t http://localhost:5050/ -g gen.conf -r testreport.html