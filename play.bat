@echo off
setlocal
cd /d "%~dp0"
set "GROVE_ENGINE=.tools\Godot_v4.7-stable_win64.exe"
if not exist "%GROVE_ENGINE%" (
 echo Downloading Godot 4.7 Standard once from the official server...
 powershell -NoProfile -Command "$ErrorActionPreference='Stop'; New-Item -ItemType Directory -Force '.tools' | Out-Null; Invoke-WebRequest -UseBasicParsing -Uri 'https://downloads.godotengine.org/?flavor=stable&platform=windows.64&slug=win64.exe.zip&version=4.7' -OutFile '.tools/engine.zip'; Expand-Archive -LiteralPath '.tools/engine.zip' -DestinationPath '.tools' -Force; Remove-Item -LiteralPath '.tools/engine.zip'"
 if errorlevel 1 goto failed
)
if not exist "%GROVE_ENGINE%" goto failed
echo Importing assets...
"%GROVE_ENGINE%" --headless --path . --editor --import --quit > .tools\import.log 2>&1
if errorlevel 1 goto failed
findstr /C:"SCRIPT ERROR:" /C:"Parse Error:" .tools\import.log >nul
if not errorlevel 1 goto failed
echo Checking game rules...
"%GROVE_ENGINE%" --headless --path . -- --self-test > .tools\test.log 2>&1
if errorlevel 1 goto failed
findstr /C:"SELF TEST PASS:" .tools\test.log >nul
if errorlevel 1 goto failed
echo Starting Grovebound...
"%GROVE_ENGINE%" --path .
exit /b %errorlevel%
:failed
echo Setup or validation failed. See .tools\import.log and .tools\test.log.
pause
exit /b 1
