#!/bin/bash

# Starting message for the Linux build process
echo "========= OnTheSpot Linux Build Script ========="

# Clean up any previous build artifacts
echo " => Cleaning up previous builds!"
rm -f ./dist/onthespot_linux ./dist/onthespot_linux_ffm

# Set up a virtual environment and activate it
echo " => Creating and activating virtual environment..."
python3 -m venv venv
source ./venv/bin/activate

# Upgrade pip and install necessary dependencies
echo " => Upgrading pip and installing necessary dependencies..."
venv/bin/pip install --upgrade pip wheel pyinstaller
venv/bin/pip install -r requirements.txt

# Check if FFmpeg binary is available and set build options accordingly
FFBIN=""
NAME="onthespot-gui"  # Default build name
if [ -f "ffbin_nix/ffmpeg" ]; then
    echo " => Found 'ffbin_nix' directory and ffmpeg binary. Including FFmpeg in the build."
    FFBIN="--add-binary=ffbin_nix/*:onthespot/bin/ffmpeg"  # Add FFmpeg to the build if available
    NAME="onthespot-gui-ffm"  # Adjust the name to indicate FFmpeg inclusion
fi

# Run PyInstaller to create a standalone executable with required resources
echo " => Running PyInstaller to create executable..."
pyinstaller --onefile \
    --hidden-import="zeroconf._utils.ipaddress" \
    --hidden-import="zeroconf._handlers.answers" \
    --add-data="src/onthespot/gui/qtui/*.ui:onthespot/gui/qtui" \
    --add-data="src/onthespot/resources/icons/*.png:onthespot/resources/icons" \
    --add-data="src/onthespot/resources/themes/*.qss:onthespot/resources/themes" \
    --add-data="src/onthespot/resources/translations/*.qm:onthespot/resources/translations" \
    $FFBIN \
    --paths="src/onthespot" \
    --name=$NAME \
    --icon="src/onthespot/resources/icons/onthespot.png" \
    src/portable.py

# Package the executable as a compressed tar.gz archive for distribution
echo " => Packaging executable as tar.gz archive..."
cd dist
tar -czvf OnTheSpot.tar.gz $NAME  # Archive the executable
cd ..

# Clean up temporary files and folders created during the build
echo " => Cleaning up temporary files..."
rm -rf __pycache__ build venv *.spec

# Completion message indicating the archive location
echo " => Done! Packaged tar.gz is available in 'dist/OnTheSpot.tar.gz'."
