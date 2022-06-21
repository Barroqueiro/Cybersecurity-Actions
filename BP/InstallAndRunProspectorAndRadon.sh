#!/bin/bash

# Install, Run and Sumarise Prospector and Radon reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Prospector profile file path inside the scanned repository
# $3 --> Aditional prospector command line arguments
# $4 --> Aditional radon command line arguments
# $5 --> Debug mode

function usage() {
    if [ -n "$1" ]; then
        echo -e "--> $1\n";
    fi
    echo "Usage: $0 [--debug] [--config] [--cmd-rd] [--cmd-p] [--files-toscan] [--output-styles]"
    echo "------------------------------------ Required ------------------------------------"
    echo "                                                                    "
    echo "  --debug                        Is debug active"
    echo "  --config                       Config file for Prospector"
    echo "  --cmd-rd                       Command line arguments for radon"
    echo "  --cmd-p                        Command line arguments for prospector"
    echo "  --files-toscan                 Files to scan"
    echo "  --output-styles                Output styles requested"
    echo ""
    exit 1
}

# Parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --config) CONFIG="$2"; shift;shift;;
  --cmd-rd) CMD_RD="$2"; shift;shift;;
  --cmd-p) CMD_P="$2"; shift;shift;;
  --files-toscan) FILES_TOSCAN="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ASSETS=$(dirname -- "$0")

# Install both tools and jinja
python3 -m pip install radon
python3 -m pip install prospector

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    DEBUG_DIR="Reports/Debug/BadPracticesScan"
    mkdir -p $DEBUG_DIR
fi

DIR="Reports/BadPracticesScan"

sufix=".py"
empty=""

# Directory where reports will be uploaded from
mkdir -p $DIR

RET=0

# Run propector and radon on the files passed as arguments

for file in $FILES_TOSCAN; do
    if [[ $file =~ \.py$ ]]; then

        # Removing all / with \ to not cause problems with directory searching
        before=$file
        file=${file////\\}
        prosp_file=${file}_prospector.json
        radon_file=${file}_radon.txt
        final_file=${file//$sufix/$empty}.html


        # Run prospector and radon, compile results with the BadPracticesReporting script, clean the files that are no longer useful
        if [ $CONFIG != "" ] 
        then
            prospector \
                    --output-format json:$prosp_file \
                    $CMD_P \
                    --profile $CONFIG \
                    -0 "$before"
        else
            prospector \
                    --output-format json:$prosp_file \
                    $CMD_P \
                    -0 "$before"
        fi
        radon cc $CMD_RD "$before" > "$radon_file"
        python3 $ASSETS/BadPracticesReporting.py \
                    --json "$prosp_file" \
                    --txt "$radon_file" \
                    --current-path "$ASSETS" \
                    --output $DIR/"$final_file"
                    --output-styles "$OUTPUT_STYLES"
        temp=$?
        if [ $temp = 1 ] 
        then
            RET=1
        fi
        
        if [ $DEBUG = "true" ]
        then
            mv "$prosp_file" $DEBUG_DIR
            mv "$radon_file" $DEBUG_DIR
        fi
    fi
done

exit $RET