#!/bin/bash

# Install, Run and Sumarise Horusec reporting

function usage() {
    if [ -n "$1" ]; then
        echo -e "--> $1\n";
    fi
    echo "Usage: $0 [--debug] [--config] [--cmd] [--output-styles]"
    echo "------------------------------------ Required ------------------------------------"
    echo "                                                                    "
    echo "  --debug                        Is debug active"
    echo "  --config                       Config file for Horusec"
    echo "  --cmd                          Command line arguments for Horusec"
    echo "  --output-styles                Output styles requested"
    echo ""
    exit 1
}

# Parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --config) CONFIG="$2"; shift;shift;;
  --cmd) CMD="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ASSETS=$(dirname -- "$0")/../Reporting

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/VulnerabilityScan"
    mkdir -p $DEBUG_DIR
fi

# Directory configuration
DIR="Reports/VulnerabilityScan"

# Install horusec
curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh | bash -s latest

# Run horusec
if [ $CONFIG != "" ] 
then
    sudo horusec start \
                -p="./" \
                -e="true" \
                -o="json" \
                -O="./HorusecReport.json" \
                --config-file-path $CONFIG $CMD
    RET=$?
else
    sudo horusec start \
                -p="./" \
                -e="true" \
                -o="json" \
                -O="./HorusecReport.json" $CMD
    RET=$?
fi

# Sumarise reports
mkdir -p $DIR
python3 $ASSETS/scripts/HorusecReporting.py \
                        --json ./HorusecReport.json \
                        --current-path $ASSETS \
                        --output $DIR/HorusecReport \
                        --output-styles "$OUTPUT_STYLES"

if [ $DEBUG = "true" ]
then
    mv ./HorusecReport.json $DEBUG_DIR
fi

# Return with the exit code related to how the horusec run went
exit $RET