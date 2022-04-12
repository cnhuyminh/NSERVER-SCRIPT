#!/bin/bash
sourceList=( "NCDN" "NDEV" "NRESTAURANT" )

cd "sources"

rm -rf "BUILD"
rm -rf "RELEASE"

mkdir "BUILD"
mkdir "RELEASE"

cd "NSERVER"
npm run build
cd "dist/core/debug"
zip -r "../../../../RELEASE/NSERVER.zip" *

cd "../../../.."

cd "APPS"
for item in "${sourceList[@]}"; do
    cd $item
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