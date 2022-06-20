#!/bin/bash

# Install, Run and Sumarise Gitleaks reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Name of the repository we are analysing
# $3 --> Aditional Gitleaks command line arguments
# $4 --> Full path to the file containing the hases of secrets to ignore
# $5 --> Debug mode
# $6 --> Output Style

function usage() {
    if [ -n "$1" ]; then
        echo -e "--> $1\n";
    fi
    echo "Usage: $0 [--debug] [--config] [--cmd] [--output-styles]"
    echo "------------------------------------ Required ------------------------------------"
    echo "                                                                    "
    echo "  --debug                        Is debug active"
    echo "  --config                       Config file for Secrets"
    echo "  --cmd                          Command line arguments for GitLeaks"
    echo "  --repo                         Name of the repository"
    echo "  --output-styles                Output styles requested"
    echo ""
    exit 1
}

# Parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --config) CONFIG="$2"; shift;shift;;
  --cmd) CMD="$2"; shift;shift;;
  --repo) REPO="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ASSETS=$(dirname -- "$0")

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/SecretScan"
    mkdir -p $DEBUG_DIR
fi

# Directory configuration
DIR="Reports/SecretScan"
mkdir -p $DIR

# Get outside the repository 
cd ..

# Clone the Gitleaks repository in the main branch
git clone https://github.com/zricethezav/gitleaks.git

# Enter the repository and build the gitleaks binary from source
cd gitleaks
make build

# Return to the repository to analise and do so outputting the result in json
cd ../$REPO
../gitleaks/gitleaks detect \
                    --report-format json \
                    --report-path output.json $CMD


# Run Gitleaks
if [ $CONFIG != "" ] 
then
    python3 $ASSETS/SecretsReporting.py \
                            --json output.json \
                            --ignore $CONFIG \
                            --current-path $ASSETS \
                            --output $DIR/SecretsReport \
                            --output-styles "$OUTPUT_STYLES"
    RET=$?
else
    touch .ignoresecrets
    python3 $ASSETS/SecretsReporting.py \
                            --json output.json \
                            --ignore .ignoresecrets \
                            --current-path $ASSETS \
                            --output $DIR/SecretsReport \
                            --output-styles "$OUTPUT_STYLES"
    RET=$?
fi

if [ $DEBUG = "true" ]
then
    mv output.json SecretsReport.json
    mv SecretsReport.json $DEBUG_DIR
fi

exit $RET
