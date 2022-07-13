#!/bin/bash

# Install, Run and Sumarise Dockle reporting

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

ASSETS=$(dirname -- "$0")../Reporting

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/DockleScan"
    mkdir -p $DEBUG_DIR
fi

# Directory configuration
DIR="Reports/DockleScan"

if [ $CONFIG != "" ]
then
    mv $CONFIG .
fi

# Install dockle

VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o dockle.deb https://github.com/goodwithtech/dockle/releases/download/v${VERSION}/dockle_${VERSION}_Linux-64bit.deb
sudo dpkg -i dockle.deb && rm dockle.deb

# Run dockle against the image
dockle \
    --exit-code 1 \
    $CMD \
    -f json \
    -o DockleReport.json \
    $TAG
RET=$?

# Sumarize reports
mkdir -p $DIR
python3 $ASSETS/scripts/DockleReporting.py \
                        --json DockleReport.json \
                        --current-path $ASSETS \
                        --output $DIR/DockleReport \
                        --output-styles "$OUTPUT_STYLES"
if [ $DEBUG = "true" ]
then
    mv DockleReport.json $DEBUG_DIR
fi

exit $RET