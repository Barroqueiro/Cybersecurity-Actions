#!/bin/bash

# Install, Run and Sumarise Horusec reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Horusec config file path inside the scanned repository
# $3 --> Aditional horusec command line arguments
# $4 --> Debug mode

DEBUG=$4
OUTPUT_STYLE=$5

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    debug_dir="Reports/Debug/VulnerabilityScan"
    mkdir -p $debug_dir
fi

# Directory configuration
dir="Reports/VulnerabilityScan"
assets="$1"

# Install horusec
curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh | bash -s latest

# Run horusec
if [ $2 != "" ] 
then
    horusec start -p="./" -e="true" -o="json" -O="./HorusecReport.json" --config-file-path $2 $3
    ret=$?
else
    horusec start -p="./" -e="true" -o="json" -O="./HorusecReport.json" $3
    ret=$?
fi

# Sumarise reports
mkdir -p $dir
python3 -m pip install Jinja2
python3 $assets/HorusecReporting.py --json ./HorusecReport.json --current-path $assets --output $dir/HorusecReport --output-styles "$OUTPUT_STYLE"

if [ $DEBUG = "true" ]
then
    mv ./HorusecReport.json $debug_dir
fi

# Return with the exit code related to how the horusec run went
exit $ret