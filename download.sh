#!/bin/bash
echo "Enter username: "
read username < /dev/tty

echo "Enter token key: "
read token < /dev/tty

sudo yum -y install mesa-libGL libXtst gcc git git-lfs

# install nodejs
echo "Install NodeJS 16"
dnf module install nodejs:16 -y

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

cd ..
cd "NSERVER"
mkdir "declare"
npm install

cd ..
cd "APPS"
for item in "${sourceList[@]}"; do
    cd $item
    npm install
    cd ..
done

cd ..
cd ..
echo "COMPLETE DOWNLOAD SOURCES"