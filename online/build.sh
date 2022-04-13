#!/bin/bash
sourceList=( "NCDN" "NDEV" "NRESTAURANT" )

sudo yum -y install mesa-libGL libXtst gcc git git-lfs

# install nodejs
echo "Install NodeJS 16"
dnf module install nodejs:16 -y

cd "sources"

rm -rf "BUILD"
rm -rf "RELEASE"

mkdir "BUILD"
mkdir "RELEASE"

cd "NSERVER"
mkdir "declare"
npm install
npm run build
cd "dist/core/debug"
zip -r "../../../../RELEASE/NSERVER.zip" *

cd "../../../.."

cd "APPS"
for item in "${sourceList[@]}"; do
    cd $item
	npm install
	rm -rf "dist"
	npm run build
	cd ..
done
cd ..

cd "BUILD"
for item in "${sourceList[@]}"; do
    cd $item
	zip -r "../../RELEASE/$item.zip" *
	cd ..
done
cd ..
cd ..

echo "BUILD COMPLETE"
ls "sources/RELEASE"