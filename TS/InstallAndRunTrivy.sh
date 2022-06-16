# Install, Run and Sumarise Trivy reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Trivy ignore file path inside the scanned repository
# $3 --> Aditional Trivy command line arguments
# $4 --> Image tag to scan
# $5 --> Debug mode
# $6 --> Output style

DEBUG=$5
OUTPUT_STYLE=$6

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    debug_dir="Reports/Debug/TrivyScan"
    mkdir -p $debug_dir
fi

# Directory configuration
dir="Reports/TrivyScan"
assets="$1"

if [ $2 != "" ]
then
    mv $2 .
fi

# Install trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.18.3

# Run trivy against the image to scan
trivy image $3 --exit-code 1 --format json -o TrivyReport.json $4
ret=$?

# Sumarize the reports
mkdir -p $dir
python3 -m pip install Jinja2
python3 $assets/TrivyReporting.py --json TrivyReport.json --current-path $assets --output $dir/TrivyReport --output-styles "$OUTPUT_STYLE"

if [ $DEBUG = "true" ]
then
    mv TrivyReport.json  $debug_dir
fi

exit $ret