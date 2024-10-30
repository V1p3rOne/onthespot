#!/bin/bash

echo "========= OnTheSpot Linux Build Script ========="

# Step 1: Ensure we’re in the correct project directory
FOLDER_NAME=$(basename "$PWD")
if [ "$FOLDER_NAME" == "scripts" ]; then
    echo "You are in the scripts folder. Changing to the parent directory..."
    cd ..
elif [ "$FOLDER_NAME" != "onthespot" ]; then
    echo "Error: Please ensure you're in the project directory. Current folder is: $FOLDER_NAME"
    exit 1
fi

# Step 2: Clean up previous builds
echo " => Cleaning up previous builds!"
rm -f ./dist/onthespot_linux ./dist/onthespot_linux_ffm

# Step 3: Set up virtual environment
echo " => Creating and activating virtual environment..."
python3 -m venv venv || { echo "Failed to create virtual environment"; exit 1; }
source ./venv/bin/activate

# Step 4: Install dependencies
echo " => Upgrading pip and installing necessary dependencies..."
venv/bin/pip install --upgrade pip wheel pyinstaller || { echo "Failed to install core dependencies"; exit 1; }
venv/bin/pip install -r requirements.txt || { echo "Failed to install project dependencies"; exit 1; }

# Step 5: Check for FFmpeg and set build options
if [ -f "ffbin_nix/ffmpeg" ]; then
    echo " => Found 'ffbin_nix' directory and ffmpeg binary. Including FFmpeg in the build."
    FFBIN="--add-binary=ffbin_nix/*:onthespot/bin/ffmpeg"
    NAME="onthespot_linux_ffm"
else
    echo " => FFmpeg binary not found. Building without it."
    FFBIN=""
    NAME="onthespot_linux"
fi

# Step 6: Run PyInstaller
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
    src/portable.py || { echo "PyInstaller build failed"; exit 1; }

# Step 7: Verify output and package it
if [ -f "./dist/$NAME" ]; then
    echo " => Packaging executable as tar.gz archive..."
    cd dist
    tar -czvf onthespot_linux.tar.gz $NAME || { echo "Error: Failed to create tar.gz archive"; exit 1; }
    chmod +x onthespot_linux.tar.gz
    echo " => Archive created at 'dist/onthespot_linux.tar.gz'"
else
    echo "Error: Expected output file $NAME not found."
    exit 1
fi

# Step 8: Clean up temporary files
echo " => Cleaning up temporary files..."
cd ..
rm -rf __pycache__ build venv *.spec

echo " => Done! Packaged tar.gz is available in 'dist/onthespot_linux.tar.gz'."
