#!/bin/bash

DEBUG=$5

# To help debugging
if [ $DEBUG = "true"]
then
    set -x
    debug_dir="Reports/Debug/BadPracticesScan"
    mkdir -p $debug_dir
fi

# Install, Run and Sumarise Prospector and Radon reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Prospector profile file path inside the scanned repository
# $3 --> Aditional prospector command line arguments
# $4 --> Aditional radon command line arguments

dir="Reports/BadPracticesScan"
assets="$1"

# Install both tools and jinja
python3 -m pip install Jinja2
python3 -m pip install radon
python3 -m pip install prospector

sufix=".py"
empty=""

# Directory where reports will be uploaded from
mkdir -p $dir

ret=0

# Run propector and radon on the files passed as arguments

for file in $6; do
    if [[ $file =~ \.py$ ]]; then

        # Removing all / with \ to not cause problems with directory searching
        before=$file
        file=${file////\\}
        prosp_file=${file}_prospector.json
        radon_file=${file}_radon.txt
        final_file=${file//$sufix/$empty}.html


        # Run prospector and radon, compile results with the BadPracticesReporting script, clean the files that are no longer useful
        if [ $2 != "" ] 
        then
            prospector --output-format json:$prosp_file $3 --profile $2 -0 "$before"
        else
            prospector --output-format json:$prosp_file $3 -0 "$before"
        fi
        radon cc $4 "$before" > "$radon_file"
        python3 $assets/BadPracticesReporting.py "$prosp_file" "$radon_file" $assets $dir/"$final_file"
        temp=$?
        if [ $temp = 1 ] 
        then
            ret=1
        fi
        if [ $DEBUG = "true"]
        then
            mv "$prosp_file" $debug_dir
            mv "$radon_file" $debug_dir
        fi
    fi
done

exit $ret