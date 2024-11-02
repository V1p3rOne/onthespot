@echo off

REM Set current directory to the project root if running from scripts folder
set FOLDER_NAME=%cd%
for %%F in ("%cd%") do set FOLDER_NAME=%%~nxF
if /i "%FOLDER_NAME%"=="scripts" (
    echo You are in the scripts folder. Changing to the parent directory...
    cd ..
)

echo ========= OnTheSpot Windows Build Script =========

REM Clean up previous builds
echo =^> Cleaning up previous builds...
del /F /Q dist\OnTheSpot.exe 2>nul

REM Create virtual environment
echo =^> Creating virtual environment...
"%SystemDrive%\hostedtoolcache\windows\Python\3.10.11\x64\python.exe" -m venv venvwin

REM Activate virtual environment
echo =^> Activating virtual environment...
call venvwin\Scripts\activate.bat

REM Upgrade pip and install dependencies
echo =^> Installing dependencies via pip...
python -m pip install --upgrade pip wheel pyinstaller
pip install -r requirements.txt

REM Download FFmpeg binary
echo =^> Downloading FFmpeg binary...
mkdir build
curl -L -o build\ffmpeg.zip https://github.com/GyanD/codexffmpeg/releases/download/7.1/ffmpeg-7.1-essentials_build.zip
powershell -Command "Expand-Archive -Path build\ffmpeg.zip -DestinationPath build\ffmpeg"

REM Run PyInstaller to create the executable
echo =^> Running PyInstaller to create .exe package...
pyinstaller --onefile --noconsole --noconfirm ^
    --hidden-import="zeroconf._utils.ipaddress" ^
    --hidden-import="zeroconf._handlers.answers" ^
    --add-data="src/onthespot/resources/translations/*.qm;onthespot/resources/translations" ^
    --add-data="src/onthespot/resources/themes/*.qss;onthespot/resources/themes" ^
    --add-data="src/onthespot/gui/qtui/*.ui;onthespot/gui/qtui" ^
    --add-data="src/onthespot/resources/icons/*.png;onthespot/resources/icons" ^
    --add-binary="build/ffmpeg/ffmpeg-7.1-essentials_build/bin/ffmpeg.exe;onthespot/bin/ffmpeg" ^
    --paths="src/onthespot" ^
    --name="OnTheSpot" ^
    --icon="src/onthespot/resources/icons/onthespot.png" ^
    src\portable.py

REM Clean up temporary files
echo =^> Cleaning up temporary files...
del /F /Q *.spec 2>nul
rmdir /s /q build __pycache__ venvwin 2>nul

echo =^> Done! Executable available as 'dist\OnTheSpot.exe'.
