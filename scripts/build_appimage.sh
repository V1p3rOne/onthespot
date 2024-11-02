#!/bin/bash

# Display start message for the AppImage build process
echo "========= OnTheSpot AppImage Build Script ==========="

# Clean up previous build artifacts and set up the build directory
echo " => Cleaning up!"
rm -rf dist build

# Create the build directory and enter it
echo " => Fetching Dependencies"
mkdir build
cd build

# Step 3: Download appimagetool to package the final AppImage
wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Download Python AppImage, which will be used to run the application in a self-contained environment
wget https://github.com/niess/python-appimage/releases/download/python3.12/python3.12.7-cp312-cp312-manylinux2014_x86_64.AppImage -O python.AppImage
chmod +x python.AppImage

# Extract Python AppImage to set up the AppDir structure
./python.AppImage --appimage-extract
mv squashfs-root OnTheSpot.AppDir  # Move the extracted contents to the AppDir

# Build the Python wheel for OnTheSpot
echo " => Building OnTheSpot.whl"
cd ..
build/OnTheSpot.AppDir/AppRun -m build

# Install dependencies and OnTheSpot package into the AppDir
echo " => Preparing OnTheSpot AppImage"
cd build/OnTheSpot.AppDir
./AppRun -m pip install -r ../../requirements.txt
./AppRun -m pip install ../../dist/onthespot-*-py3-none-any.whl

# Set up the desktop integration for AppImage by removing unneeded files and adding resources
rm AppRun .DirIcon python.png python*.desktop
cp -t . ../../src/onthespot/resources/icons/onthespot.png ../../src/onthespot/resources/org.onthespot.OnTheSpot.desktop

# Create a custom AppRun script to launch the application within AppImage
echo '#! /bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH=$HERE/usr/bin:$PATH;
export APPIMAGE_COMMAND=$(command -v -- "$ARGV0")
export TCL_LIBRARY="${APPDIR}/usr/share/tcltk/tcl8.6"
export TK_LIBRARY="${APPDIR}/usr/share/tcltk/tk8.6"
export TKPATH="${TK_LIBRARY}"
export SSL_CERT_FILE="${APPDIR}/opt/_internal/certs.pem"
"$HERE/opt/python3.12/bin/python3.12" "-m" "onthespot" "$@"' > AppRun

# Set permissions for the AppDir contents and the custom AppRun script
chmod -R 0755 ../OnTheSpot.AppDir
chmod +x AppRun

# Add FFmpeg and FFplay binaries for multimedia support
cp $(which ffmpeg) ../OnTheSpot.AppDir/usr/bin
cp $(which ffplay) ../OnTheSpot.AppDir/usr/bin

# Package the final AppImage
echo " => Building OnTheSpot AppImage"
cd ..
./appimagetool-x86_64.AppImage --appimage-extract
squashfs-root/AppRun OnTheSpot.AppDir

# Move the built AppImage to the dist folder
mv OnTheSpot-x86_64.AppImage ../dist/OnTheSpot-x86_64.AppImage

# Completion message with the location of the final AppImage file
echo " => Done! Packaged AppImage is available in 'dist/OnTheSpot-x86_64.AppImage'."
