@echo off
setlocal
cd /d "%~dp0"
where git >nul 2>nul
if errorlevel 1 (
 echo Git is required. Install Git for Windows once, or use GitHub Desktop to update.
 goto failed
)
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
 echo This folder is not a Git clone. Clone the repository once before using this launcher.
 goto failed
)
for /f "delims=" %%A in ('git status --porcelain --untracked-files^=no') do (
 echo You have local changes. Commit or stash them before updating.
 goto failed
)
echo Updating game files...
git pull --ff-only
if errorlevel 1 goto failed
call "%~dp0play.bat"
exit /b %errorlevel%
:failed
pause
exit /b 1
