#!/bin/bash

# Install, Run and Sumarise Gitleaks reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Name of the repository we are analysing
# $3 --> Aditional Gitleaks command line arguments
# $4 --> Full path to the file containing the hases of secrets to ignore
# $5 --> Debug mode

DEBUG=$5

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    debug_dir="Reports/Debug/SecretScan"
    mkdir -p $debug_dir
fi

# Directory configuration
dir="Reports/SecretScan"
assets="$1"
mkdir -p $dir

# Get outside the repository 
cd ..

# Clone the Gitleaks repository in the main branch
git clone https://github.com/zricethezav/gitleaks.git

# Enter the repository and build the gitleaks binary from source
cd gitleaks
make build

# Return to the repository to analise and do so outputting the result in json
cd ../$2
../gitleaks/gitleaks detect --report-format json --report-path output.json $3


# Run Gitleaks
if [ $4 != "" ] 
then
    python3 $assets/SecretsReporting.py output.json $4 $1 $dir/SecretsReport.html
    ret=$?
else
    touch .ignoresecrets
    python3 $assets/SecretsReporting.py output.json .ignoresecrets $1 $dir/SecretsReport.html
    ret=$?
fi

if [ $DEBUG = "true" ]
then
    mv output.json SecretsReport.json
    mv SecretsReport.json $debug_dir
fi

exit $ret
