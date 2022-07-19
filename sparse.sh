cd $(dirname -- "$0")

rm -rf Reporting

git clone https://github.com/Barroqueiro/Cybersecurity-Actions.git --recurse-submodules

cd Cybersecurity-Actions

mv Reporting ..

cd ..

rm -rf Cybersecurity-Actions