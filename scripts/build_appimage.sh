#!/bin/bash

echo "========= OnTheSpot AppImage Build Script ==========="

# Step 1: Clean up any previous build artifacts and set up directories
echo " => Cleaning up previous builds and setting up directories!"
rm -rf dist build
mkdir build
cd build

# Step 2: Download appimagetool with retry logic in case of failures
echo " => Fetching appimagetool"
for attempt in {1..3}; do
  wget -q --show-progress https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && break
  echo "Download failed, retrying ($attempt/3)..."
  sleep 3
done
chmod +x appimagetool-x86_64.AppImage

# Step 3: Download Python AppImage with similar retry logic
echo " => Fetching Python AppImage"
for attempt in {1..3}; do
  wget -q --show-progress https://github.com/niess/python-appimage/releases/download/python3.12/python3.12.3-cp312-cp312-manylinux2014_x86_64.AppImage && break
  echo "Download failed, retrying ($attempt/3)..."
  sleep 3
done
chmod +x python3.12.3-cp312-cp312-manylinux2014_x86_64.AppImage

# Verify that both downloads were successful
if [[ ! -f appimagetool-x86_64.AppImage ]] || [[ ! -f python3.12.3-cp312-cp312-manylinux2014_x86_64.AppImage ]]; then
  echo "Error: Required AppImage tools failed to download. Exiting."
  exit 1
fi

# Step 4: Extract Python AppImage and set up the AppDir structure
echo " => Setting up AppDir for OnTheSpot"
./python3.12.3-cp312-cp312-manylinux2014_x86_64.AppImage --appimage-extract
mv squashfs-root OnTheSpot.AppDir

# Step 5: Build OnTheSpot Python wheel
echo " => Building OnTheSpot.whl"
cd ..
build/OnTheSpot.AppDir/AppRun -m build

# Step 6: Install dependencies within the AppDir environment
echo " => Installing dependencies in AppDir"
cd build/OnTheSpot.AppDir
./AppRun -m pip install -r ../../requirements.txt
./AppRun -m pip install ../../dist/onthespot-*-py3-none-any.whl

# Step 7: Prepare the AppRun launcher script
rm AppRun .DirIcon python.png python3.12.3.desktop
cp -t . ../../src/onthespot/resources/icons/onthespot.png ../../src/onthespot/resources/org.onthespot.OnTheSpot.desktop

# Step 8: Create custom AppRun script for launching the application
echo '#! /bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH=$HERE/usr/bin:$PATH;
export APPIMAGE_COMMAND=$(command -v -- "$ARGV0")
export TCL_LIBRARY="${APPDIR}/usr/share/tcltk/tcl8.6"
export TK_LIBRARY="${APPDIR}/usr/share/tcltk/tk8.6"
export TKPATH="${TK_LIBRARY}"
export SSL_CERT_FILE="${APPDIR}/opt/_internal/certs.pem"
"$HERE/opt/python3.12/bin/python3.12" "-m" "onthespot" "$@"' > AppRun

# Set permissions for AppDir and AppRun script
chmod -R 0755 ../OnTheSpot.AppDir
chmod 0755 AppRun

# Step 9: Add FFmpeg binaries if required
echo ' '
echo ' # ffmpeg and ffplay need to be manually added to OnTheSpot.AppDir/usr/bin.'
echo ' # Make sure to run chmod +x on each, binaries can be found here:'
echo ' # https://johnvansickle.com/ffmpeg/'
echo ' '
echo ' => Done adding ffmpeg binaries? (y/n)'
read ffmpeg
case $ffmpeg in
  y)
    sleep 1
    clear
    ;;
esac

# Step 10: Build the final AppImage
echo " => Building OnTheSpot AppImage"
cd ..
./appimagetool-x86_64.AppImage --appimage-extract
squashfs-root/AppRun OnTheSpot.AppDir
mv OnTheSpot-x86_64.AppImage ../dist/OnTheSpot-x86_64.AppImage

echo " => Done"
