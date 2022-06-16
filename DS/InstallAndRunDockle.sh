# Install, Run and Sumarise Dockle reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Dockle ignore file path inside the scanned repository
# $3 --> Aditional Dockle command line arguments
# $4 --> Image tag to scan
# $5 --> debug mode
# $6 --> output style

DEBUG=$5

OUTPUT_STYLE=$5

# To help debugging
if [ $DEBUG = "true" ]
then
    set -x
    debug_dir="Reports/Debug/DockleScan"
    mkdir -p $debug_dir
fi

# Directory configuration
dir="Reports/DockleScan"
assets="$1"

if [ $2 != "" ]
then
    mv $2 .
fi

# Install dockle

VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o dockle.deb https://github.com/goodwithtech/dockle/releases/download/v${VERSION}/dockle_${VERSION}_Linux-64bit.deb
sudo dpkg -i dockle.deb && rm dockle.deb

# Run dockle against the image
dockle --exit-code 1 $3 -f json -o DockleReport.json $4
ret=$?

# Sumarize reports
mkdir -p $dir
python3 -m pip install Jinja2
python3 $assets/DockleReporting.py --json DockleReport.json --current-path $assets --output $dir/DockleReport --output-styles "$OUTPUT_STYLE"
if [ $DEBUG = "true" ]
then
    mv DockleReport.json $debug_dir
fi

exit $ret