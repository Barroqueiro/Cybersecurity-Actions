# To help debugging
set -x

# Install, Run and Sumarise Dockle reporting
#
# $1 --> Full path inside github worker to the folder where this script resides
# $2 --> Dockle ignore file path inside the scanned repository
# $3 --> Aditional Dockle command line arguments
# $4 --> Image tag to scan

# Directory configuration
dir="Reports/DockleScan"
assets="$1"

mv $2 .

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
python3 $assets/DockleReporting.py DockleReport.json $assets $dir/DockleReport.html
mv DockleReport.json $dir

exit $ret