@echo off
setlocal
cd /d "%~dp0"
set "GROVE_ENGINE=.tools\Godot_v4.7-stable_win64.exe"
set "GROVE_CONSOLE=.tools\Godot_v4.7-stable_win64_console.exe"
set "GROVE_STAGE=Create tools directory"
set "GROVE_LOG="
if not exist .tools mkdir .tools
if not exist .tools goto failed
if not exist "%GROVE_ENGINE%" goto download
if not exist "%GROVE_CONSOLE%" goto download
goto validate
:download
set "GROVE_STAGE=Download Godot 4.7"
set "GROVE_LOG=.tools\download.log"
echo [1/4] Downloading Godot 4.7 from the official server. This is needed only once.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri 'https://downloads.godotengine.org/?flavor=stable&platform=windows.64&slug=win64.exe.zip&version=4.7' -OutFile '.tools/engine.zip'; Expand-Archive -LiteralPath '.tools/engine.zip' -DestinationPath '.tools' -Force; Remove-Item -LiteralPath '.tools/engine.zip'" > "%GROVE_LOG%" 2>&1
if errorlevel 1 goto failed
if not exist "%GROVE_ENGINE%" goto failed
if not exist "%GROVE_CONSOLE%" goto failed
:validate
set "GROVE_STAGE=Import game assets"
set "GROVE_LOG=.tools\import.log"
echo [2/4] Importing assets...
"%GROVE_CONSOLE%" --headless --path . --editor --import --quit > "%GROVE_LOG%" 2>&1
if errorlevel 1 goto failed
findstr /C:"SCRIPT ERROR:" /C:"Parse Error:" "%GROVE_LOG%" >nul
if not errorlevel 1 goto failed
set "GROVE_STAGE=Check game rules"
set "GROVE_LOG=.tools\test.log"
echo [3/4] Checking game rules...
"%GROVE_CONSOLE%" --headless --path . -- --self-test > "%GROVE_LOG%" 2>&1
if errorlevel 1 goto failed
findstr /C:"SELF TEST PASS:" "%GROVE_LOG%" >nul
if errorlevel 1 goto failed
if /I "%~1"=="--check-only" (
 type "%GROVE_LOG%"
 exit /b 0
)
set "GROVE_STAGE=Start game"
set "GROVE_LOG=.tools\game.log"
echo [4/4] Starting Grovebound...
start "" /wait "%GROVE_ENGINE%" --path . --log-file .tools/game.log
if errorlevel 1 goto failed
exit /b 0
:failed
echo.
echo FAILED AT: %GROVE_STAGE%
if defined GROVE_LOG if exist "%GROVE_LOG%" type "%GROVE_LOG%"
echo.
echo Please send a screenshot of the messages above.
if /I "%~1"=="--check-only" exit /b 1
pause
exit /b 1
