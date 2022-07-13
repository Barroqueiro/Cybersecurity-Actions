cd $1

rm Reporting

git clone git@github.com:Barroqueiro/Cybersecurity-Actions.git --recurse-submodules

cd Cybersecurity-Actions

mv Reporting ..

cd ..

rm -rf Cybersecurity-Actions