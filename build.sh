#!/bin/bash
sourceList=( "NCDN" "NDEV" "NRESTAURANT" )

cd "sources"
cd "NSERVER"

npm run build
cd "dist/core/debug"
zip -r "../../../../RELEASE/NSERVER.zip" *

cd "../../../.."

rm -rf "BUILD"
rm -rf "RELEASE"

mkdir "BUILD"
mkdir "RELEASE"

cd "APPS"
for item in "${sourceList[@]}"; do
    cd $item
	rm -rf "dist"
	mkdir "dist"
	mkdir "../BUILD/$item"
	ln -s "../BUILD/$item" "dist"
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