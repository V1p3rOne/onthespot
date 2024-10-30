#!/bin/bash

echo "========= OnTheSpot AppImage Build Script ==========="

# Step 1: Clean up any previous builds and set up directories
echo " => Cleaning up previous builds and setting up directories!"
rm -rf dist build
mkdir -p dist build
cd build || exit 1

# Step 2: Download appimagetool
echo " => Fetching appimagetool"
wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage || {
    echo "Error: Failed to download appimagetool"; exit 1;
}
chmod +x appimagetool-x86_64.AppImage

# Step 3: Download Python AppImage
echo " => Fetching Python AppImage"
wget -q https://github.com/niess/python-appimage/releases/download/python3.12/python3.12.3-cp312-cp312-manylinux2014_x86_64.AppImage -O python3.AppImage || {
    echo "Error: Failed to download Python AppImage"; exit 1;
}
chmod +x python3.AppImage

# Step 4: Extract Python AppImage
./python3.AppImage --appimage-extract || { 
    echo "Error: Python extraction failed"; exit 1;
}
mv squashfs-root OnTheSpot.AppDir

# Step 5: Build OnTheSpot Python wheel
echo " => Building OnTheSpot Python wheel"
cd ..
./build/OnTheSpot.AppDir/AppRun -m build || {
    echo "Error: Failed to build OnTheSpot wheel"; exit 1;
}

# Step 6: Prepare the AppImage environment
echo " => Installing dependencies into AppImage environment"
cd build/OnTheSpot.AppDir || exit 1
./AppRun -m pip install -r ../../requirements.txt
./AppRun -m pip install ../../dist/onthespot-*-py3-none-any.whl

# Step 7: Clean up unnecessary files
rm AppRun .DirIcon python.png python3.12.3.desktop
cp ../../src/onthespot/resources/icons/onthespot.png .
cp ../../src/onthespot/resources/org.onthespot.OnTheSpot.desktop .

# Step 8: Create AppRun script
echo " => Creating AppRun script for AppImage"
echo '#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH=$HERE/usr/bin:$PATH
"$HERE/opt/python3/bin/python3" -m onthespot "$@"' > AppRun
chmod +x AppRun

# Step 9: Build the AppImage
echo " => Building final AppImage"
cd ..
./appimagetool-x86_64.AppImage OnTheSpot.AppDir -o ../dist/OnTheSpot-latest-x86_64.AppImage || {
    echo "Error: AppImage creation failed"; exit 1;
}

echo " => Done! AppImage successfully created in 'dist' folder."
