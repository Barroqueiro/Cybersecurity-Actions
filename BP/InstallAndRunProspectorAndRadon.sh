#!/bin/bash

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

# Run propector and radon on a file passed as the first argument

sufix=".py"
empty=""

# Directory where reports will be uploaded from
mkdir -p $dir

for file in "${@:5}"; do
    if [[ $file =~ \.py$ ]]; then

        # Removing all / with \ to not cause problems with directory searching
        before=$file
        file=${file////\\}
        prosp_file=./$dir/${file}_prospector.json
        radon_file=./$dir/${file}_radon.html
        final_file=./$dir/${file//$sufix/$empty}.html


        # Run prospector and radon, compile results with the CodeReporting script, clean the files that are no longer useful
        if [ $2 != "" ] 
        then
            prospector $3 --profile $2 -0 "$before" > "$prosp_file"
        else
            prospector $3 -0 "$before" > "$prosp_file"
        fi
        radon cc $4 "$before" > "$radon_file"
        python3 $reporting/CodeReporting.py "$prosp_file" "$radon_file" > "$final_file"
        rm "$prosp_file" "$radon_file"
    fi
done