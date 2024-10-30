#!/bin/bash

echo "========= OnTheSpot macOS Build Script =========="

# Step 1: Ensure we're in the correct directory
FOLDER_NAME=$(basename "$PWD")
if [ "$FOLDER_NAME" == "scripts" ]; then
    echo "You are in the scripts folder. Changing to the parent directory..."
    cd ..
elif [ "$FOLDER_NAME" != "onthespot" ]; then
    echo "Error: Please ensure you're in the project folder. Current folder is: $FOLDER_NAME"
    exit 1
fi

# Step 2: Clean up previous builds
echo " => Cleaning up previous builds!"
rm -rf ./dist/onthespot_mac.app ./dist/onthespot_mac_ffm.app

# Step 3: Set up virtual environment
echo " => Creating and activating virtual environment..."
python3 -m venv venv || { echo "Failed to create virtual environment"; exit 1; }
source ./venv/bin/activate

# Step 4: Install dependencies
echo " => Upgrading pip and installing necessary dependencies..."
venv/bin/pip install --upgrade pip wheel pyinstaller || { echo "Failed to install core dependencies"; exit 1; }
venv/bin/pip install -r requirements.txt || { echo "Failed to install project dependencies"; exit 1; }

# Step 5: Check for FFmpeg and set build options
if [ -f "ffbin_mac/ffmpeg" ]; then
    echo " => Found 'ffbin_mac' directory and ffmpeg binary. Including FFmpeg in the build."
    FFBIN='--add-binary=ffbin_mac/*:onthespot/bin/ffmpeg'
else
    echo " => FFmpeg binary not found. Building without it."
    FFBIN=""
fi

# Step 6: Run PyInstaller to create the app
echo " => Running PyInstaller to create .app package..."
pyinstaller --windowed \
    --hidden-import="zeroconf._utils.ipaddress" \
    --hidden-import="zeroconf._handlers.answers" \
    --add-data="src/onthespot/gui/qtui/*.ui:onthespot/gui/qtui" \
    --add-data="src/onthespot/resources/icons/*.png:onthespot/resources/icons" \
    --add-data="src/onthespot/resources/themes/*.qss:onthespot/resources/themes" \
    --add-data="src/onthespot/resources/translations/*.qm:onthespot/resources/translations" \
    $FFBIN \
    --paths="src/onthespot" \
    --name="OnTheSpot" \
    --icon="src/onthespot/resources/icons/onthespot.png" \
    src/portable.py || { echo "PyInstaller build failed"; exit 1; }

# Step 7: Move output to dist directory and verify .app package
echo " => Moving .app package to 'dist' directory..."
mv ./dist/OnTheSpot.app ./dist/onthespot_mac.app
chmod +x ./dist/onthespot_mac.app

# Step 8: Clean up temporary files
echo " => Cleaning up temporary files..."
rm -rf __pycache__ build venv *.spec

echo " => Done! .app package available in 'dist/onthespot_mac.app'."
