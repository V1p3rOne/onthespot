#!/bin/bash

# Starting message for the build process
echo "========= OnTheSpot macOS Build Script =========="

# Clean up any previous builds
echo " => Cleaning up previous builds!"
rm -rf dist/onthespot_mac.app dist/onthespot_mac_ffm.app

# Set up a virtual environment and activate it
echo " => Creating and activating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip and install required packages, including PyInstaller
echo " => Upgrading pip and installing necessary dependencies..."
venv/bin/pip install --upgrade pip wheel pyinstaller
venv/bin/pip install -r requirements.txt

# Download FFmpeg and extract it to the build directory
echo " => Running PyInstaller to create .app package..."
mkdir build
wget https://evermeet.cx/ffmpeg/ffmpeg-7.1.zip -O build/ffmpeg.zip
unzip build/ffmpeg.zip -d build

# S5: Use PyInstaller to create the .app package with required resources and FFmpeg binary
pyinstaller --windowed \
    --hidden-import="zeroconf._utils.ipaddress" \
    --hidden-import="zeroconf._handlers.answers" \
    --add-data="src/onthespot/gui/qtui/*.ui:onthespot/gui/qtui" \
    --add-data="src/onthespot/resources/icons/*.png:onthespot/resources/icons" \
    --add-data="src/onthespot/resources/themes/*.qss:onthespot/resources/themes" \
    --add-data="src/onthespot/resources/translations/*.qm:onthespot/resources/translations" \
    --add-binary="build/ffmpeg:onthespot/bin/ffmpeg" \
    --paths="src/onthespot" \
    --name="OnTheSpot" \
    --icon="src/onthespot/resources/icons/onthespot.png" \
    src/portable.py

# Set executable permissions for the created .app package
echo " => Setting executable permissions..."
chmod +x dist/OnTheSpot.app

# Create a .dmg file from the .app package
echo " => Creating dmg..."
mkdir -p dist/OnTheSpot
mv dist/OnTheSpot.app dist/OnTheSpot/OnTheSpot.app
ln -s /Applications dist/OnTheSpot
hdiutil create -srcfolder dist/OnTheSpot -format UDZO -o dist/OnTheSpot.dmg

# Clean up temporary files and folders
echo " => Cleaning up temporary files..."
rm -rf __pycache__ build venv *.spec

# Completion message
echo " => Done! .dmg available in 'dist/OnTheSpot.dmg'."
