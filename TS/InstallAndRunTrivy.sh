#!/bin/bash

# Install, Run and Sumarise Trivy reporting

function usage() {
    if [ -n "$1" ]; then
        echo -e "--> $1\n";
    fi
    echo "Usage: $0 [--debug] [--config] [--cmd] [--tag] [--output-styles]"
    echo "------------------------------------ Required ------------------------------------"
    echo "                                                                    "
    echo "  --debug                        Is debug active"
    echo "  --config                       Config file for Horusec"
    echo "  --cmd                          Command line arguments for Horusec"
    echo "  --tag                          Image tag to scan"
    echo "  --output-styles                Output styles requested"
    echo ""
    exit 1
}

# Parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --config) CONFIG="$2"; shift;shift;;
  --cmd) CMD="$2"; shift;shift;;
  --tag) TAG="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ASSETS=$(dirname -- "$0")

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/TrivyScan"
    mkdir -p $DEBUG_DIR
fi

# Directory configuration
DIR="Reports/TrivyScan"

if [ $CONFIG != "" ]
then
    mv $CONFIG .
fi

# Install trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.29.1

# Run trivy against the image to scan
trivy image \
        $CMD \
        --exit-code 1 \
        --format json \
        -o TrivyReport.json \
        $TAG
RET=$?

# Sumarize the reports
mkdir -p $DIR
python3 $ASSETS/TrivyReporting.py \
                --json TrivyReport.json \
                --current-path $ASSETS \
                --output $DIR/TrivyReport \
                --output-styles "$OUTPUT_STYLES"

if [ $DEBUG = "true" ]
then
    mv TrivyReport.json  $DEBUG_DIR
fi

exit $RET
