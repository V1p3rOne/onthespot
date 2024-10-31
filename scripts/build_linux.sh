#!/bin/bash

echo "========= OnTheSpot Linux Build Script ========="


echo " => Cleaning up previous builds!"
rm -f ./dist/onthespot_linux ./dist/onthespot_linux_ffm


echo " => Creating and activating virtual environment..."
python3 -m venv venv
source ./venv/bin/activate


echo " => Upgrading pip and installing necessary dependencies..."
venv/bin/pip install --upgrade pip wheel pyinstaller
venv/bin/pip install -r requirements.txt

FFBIN=""
NAME="onthespot-gui"
if [ -f "ffbin_nix/ffmpeg" ]; then
    echo " => Found 'ffbin_nix' directory and ffmpeg binary. Including FFmpeg in the build."
    FFBIN="--add-binary=ffbin_nix/*:onthespot/bin/ffmpeg"
    NAME="onthespot-gui-ffm"
fi


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

if [ -f "./dist/$NAME" ]; then
    echo " => Packaging executable as tar.gz archive..."
    cd dist
    tar -czvf onthespot_linux.tar.gz $NAME
    echo " => Archive created at 'dist/onthespot_linux.tar.gz'"
else
    echo "Error: Expected output file $NAME not found."
    exit 1
fi


echo " => Cleaning up temporary files..."
cd ..
rm -rf __pycache__ build venv *.spec


echo " => Done! Packaged tar.gz is available in 'dist/onthespot_linux.tar.gz'."