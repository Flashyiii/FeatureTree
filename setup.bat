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
    rokit run wally install
)

:: Generate initial project structure
if exist tools/genFeatureTree.js (
    echo 🛠️  Generating Rojo project...
    node tools/genFeatureTree.js
)

echo.
echo ✅ Setup Complete! You can now run 'npm run watch:rojo' or open Studio.
pause
