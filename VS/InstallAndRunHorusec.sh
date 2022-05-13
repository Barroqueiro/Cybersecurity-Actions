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
python3 $assets/HorusecReporting.py ./HorusecReport.json $assets $dir/HorusecReport.html
mv ./HorusecReport.json $dir

# Return with the exit code related to how the horusec run went
exit $ret