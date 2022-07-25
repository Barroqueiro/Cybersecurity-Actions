#!/bin/bash

# Install, Run and Sumarise Zap reporting

function usage() {
    if [ -n "$1" ]; then
        echo -e "--> $1\n";
    fi
    echo "Usage: $0 [--debug] [--config] [--cmd] [--target] [--output-styles]"
    echo "------------------------------------ Required ------------------------------------"
    echo "                                                                    "
    echo "  --debug                        Is debug active"
    echo "  --config                       Config file for Horusec"
    echo "  --cmd                          Command line arguments for Horusec"
    echo "  --target                       Target to scan"
    echo "  --output-styles                Output styles requested"
    echo ""
    exit 1
}

# Parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --config) CONFIG="$2"; shift;shift;;
  --cmd) CMD="$2"; shift;shift;;
  --target) TARGET="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ASSETS=$(dirname -- "$0")/../Reporting

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/ZapScan"
    mkdir -p $DEBUG_DIR
fi

# Directory configuration
DIR="Reports/ZapScan"

VOLUME="zap/wrk/"

mkdir -p $VOLUME

if [ $CONFIG != "" ] 
then
    docker run \
            --user root \
            -v $(pwd):/$VOLUME/:rw \
            --network="host" \
            -t owasp/zap2docker-stable zap-full-scan.py \
            -t $TARGET \
            -c "$CONFIG" \
            -J ZapReport.json \
            $CMD
    RET=$?
else
    docker run \
            --user root \
            -v $(pwd):/$VOLUME/:rw \
            --network="host" \
            -t owasp/zap2docker-stable zap-full-scan.py \
            -t $TARGET \
            -J ZapReport.json \
            $CMD
    RET=$?
fi

mkdir -p $DIR

python3 $ASSETS/scripts/ZapReporting.py \
            --json ZapReport.json \
            --current-path $ASSETS \
            --output $DIR/ZapReport \
            --output-styles "$OUTPUT_STYLES"

if [ $DEBUG = "true" ]
then
    mv ZapReport.json $DEBUG_DIR
fi

exit $RET
