@echo off

echo ========= OnTheSpot Windows Build Script =========

REM Check the current folder and change directory if necessary
set FOLDER_NAME=%cd%
for %%F in ("%cd%") do set FOLDER_NAME=%%~nxF
if /i "%FOLDER_NAME%"=="scripts" (
    echo You are in the scripts folder. Changing to the parent directory...
    cd ..
) else if /i not "%FOLDER_NAME%"=="onthespot" (
    echo Error: Please ensure you are inside the project folder. Current folder is: %FOLDER_NAME%
    timeout /t 10 >nul
    exit /b 1
)

REM Clean up previous builds
echo =^> Cleaning up previous builds...
del /F /Q /A dist\onthespot_win_executable.exe 2>nul

REM Set up virtual environment
echo =^> Creating virtual environment...
python -m venv venvwin || (
    echo Error: Failed to create virtual environment. Exiting...
    timeout /t 10 >nul
    exit /b 1
)

REM Activate virtual environment
echo =^> Activating virtual environment...
call venvwin\Scripts\activate.bat || (
    echo Error: Failed to activate virtual environment. Exiting...
    timeout /t 10 >nul
    exit /b 1
)

REM Install dependencies
echo =^> Installing dependencies via pip...
for %%P in (pip wheel pyinstaller) do (
    python -m pip show %%P >nul || python -m pip install --upgrade %%P || (
        echo Error: Failed to install %%P. Exiting...
        timeout /t 10 >nul
        exit /b 1
    )
)
pip install -r requirements.txt || (
    echo Error: Failed to install project dependencies. Exiting...
    timeout /t 10 >nul
    exit /b 1
)

REM Download and set up FFmpeg if available
echo =^> Downloading FFmpeg binary...
mkdir build
curl -L https://github.com/GyanD/codexffmpeg/releases/download/7.1/ffmpeg-7.1-essentials_build.zip -o build\ffmpeg.zip || (
    echo Error: Failed to download FFmpeg. Exiting...
    timeout /t 10 >nul
    exit /b 1
)

powershell -Command "Expand-Archive -Path build\ffmpeg.zip -DestinationPath build\ffmpeg" || (
    echo Error: Failed to extract FFmpeg. Exiting...
    timeout /t 10 >nul
    exit /b 1
)

mkdir ffbin_win
set FFMPEG_DIR=
for /d %%D in ("build\ffmpeg\*") do set FFMPEG_DIR=%%D
if defined FFMPEG_DIR (
    xcopy /Y "%FFMPEG_DIR%\bin\ffmpeg.exe" ffbin_win\ >nul 2>&1 || (
        echo Error: Failed to copy FFmpeg binary. Exiting...
        timeout /t 10 >nul
        exit /b 1
    )
) else (
    echo Error: FFmpeg directory not found. Proceeding without it.
)

REM Build with or without FFmpeg
if exist ffbin_win\ffmpeg.exe (
    echo =^> FFmpeg found, building with FFmpeg support...
    pyinstaller --onefile --noconsole --noconfirm ^
        --hidden-import="zeroconf._utils.ipaddress" ^
        --hidden-import="zeroconf._handlers.answers" ^
        --add-data="src/onthespot/resources/translations/*.qm;onthespot/resources/translations" ^
        --add-data="src/onthespot/resources/themes/*.qss;onthespot/resources/themes" ^
        --add-data="src/onthespot/gui/qtui/*.ui;onthespot/gui/qtui" ^
        --add-data="src/onthespot/resources/icons/*.png;onthespot/resources/icons" ^
        --add-binary="ffbin_win/ffmpeg.exe;onthespot/bin/ffmpeg" ^
        --paths="src/onthespot" ^
        --name="onthespot_win_executable" ^
        --icon="src/onthespot/resources/icons/onthespot.png" ^
        src\portable.py || (
        echo Error: PyInstaller build with FFmpeg failed. Exiting...
        timeout /t 10 >nul
        exit /b 1
    )
) else (
    echo =^> FFmpeg not found, building without FFmpeg support...
    pyinstaller --onefile --noconsole --noconfirm ^
        --hidden-import="zeroconf._utils.ipaddress" ^
        --hidden-import="zeroconf._handlers.answers" ^
        --add-data="src/onthespot/resources/translations/*.qm;onthespot/resources/translations" ^
        --add-data="src/onthespot/resources/themes/*.qss;onthespot/resources/themes" ^
        --add-data="src/onthespot/gui/qtui/*.ui;onthespot/gui/qtui" ^
        --add-data="src/onthespot/resources/icons/*.png;onthespot/resources/icons" ^
        --paths="src/onthespot" ^
        --name="onthespot_win_executable" ^
        --icon="src/onthespot/resources/icons/onthespot.png" ^
        src\portable.py || (
        echo Error: PyInstaller build without FFmpeg failed. Exiting...
        timeout /t 10 >nul
        exit /b 1
    )
)

REM Clean up unnecessary files
echo =^> Cleaning up temporary files...
del /F /Q onthespot_win.spec 2>nul
rmdir /s /q build __pycache__ ffbin_win venvwin 2>nul

echo =^> Done! Executable available as 'dist/onthespot_win_executable.exe'.
