#!/bin/bash
curDir="$PWD"
echo "Enter username: "
read username < /dev/tty

echo "Enter token key: "
read token < /dev/tty

sudo yum -y install git git-lfs

rm -rf "sources"
mkdir "sources"

cd "sources"
git clone --depth 1 "https://$username:$token@github.com/$username/NWEB-SERVER.git"
mv "NWEB-SERVER" "NSERVER"

mkdir "APPS"

cd "APPS"
sourceList=( "NCDN" "NDEV" "NRESTAURANT" )
for item in "${sourceList[@]}"; do
    git clone --depth 1 "https://$username:$token@github.com/$username/$item.git"
done
cd ".."

curl -fsSL "https://raw.githubusercontent.com/cnhuyminh/NSERVER-SCRIPT/master/online/build.sh" -o "build.sh"
curl -fsSL "https://raw.githubusercontent.com/cnhuyminh/NSERVER-SCRIPT/master/online/install.sh" -o "install.sh"

zip -r "../sources.zip" *

cd "$curDir"

echo "COMPLETE DOWNLOAD SOURCES"