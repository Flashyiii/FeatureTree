@echo off
echo 🚀 Initializing Project...

:: Install Toolchain Manager (Rokit)
if exist rokit.toml (
    echo 📦 Installing Rokit tools...
    rokit install
)

:: Install NPM dependencies
if exist package.json (
    echo 📦 Installing NPM packages...
    call npm install
)

:: Install Wally dependencies
if exist wally.toml (
    echo 📦 Installing Wally packages...
    :: Check if wally is installed via rokit, otherwise use global
    rokit run wally install 2>nul || wally install
)

:: Generate initial project structure
if exist tools/genFeatureTree.js (
    echo 🛠️  Generating Rojo project...
    node tools/genFeatureTree.js
)

echo.
set /p DECOUPLE="❓ Do you want to disconnect this project from the Boilerplate repository? (y/n): "
if /i "%DECOUPLE%"=="y" (
    if exist .git (
        echo ✂️  Disconnecting from Git...
        rmdir /s /q .git
        echo ✅ Disconnected! You can now run 'git init' to start a new history.
    )
)

echo.
echo ✅ Setup Complete! You can now run 'npm run watch:rojo' or open Studio.
pause
