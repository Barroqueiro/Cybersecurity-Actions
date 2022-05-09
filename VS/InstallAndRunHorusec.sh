# Directory configuration
dir="Reports/VulnerabilityScan"
assets="$1"

echo assets

mv $2 .

# Install and run horusec
curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh | bash -s latest
horusec start -p="./" -e="true" -o="json" -O="./full_report.json" $3
ret=$?

# Sumarise reports
mkdir -p $dir
python3 -m pip install Jinja2
python3 $assets/HorusecReporting.py ./full_report.json $assets > $dir/HorusecReport.html
mv ./full_report.json $dir

exit $ret