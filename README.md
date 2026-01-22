# 🚀 Professional Roblox Boilerplate

This is a powerful, feature-based project structure using Rojo, Wally, and a custom auto-generating project tree.

## 🛠️ Setup (After Downloading)

If you just cloned or downloaded this project, follow these steps to get started:

1. **Run Setup**: Double-click the `setup.bat` file. This will automatically:

    - Install all required tools via **Rokit**.
    - Install dependencies via **NPM** and **Wally**.
    - Generate the initial `default.project.json`.

2. **Start Development**:
    - Run `npm run watch:rojo` in your terminal to keep the project tree updated.
    - Open Roblox Studio and connect the Rojo plugin.

## 📁 Project Structure

- **src/core**: Reusable utility modules and base classes.
- **src/features**: Self-contained game systems (e.g., Admin, Combat).
- **src/game**: Game-specific configurations and logic.
- **tools/genFeatureTree.js**: Automatically manages your `default.project.json` based on the files in `src/`.

## ⚙️ Tools Used

- [Rojo](https://rojo.space/) - Sync project to Roblox Studio.
- [Wally](https://wally.run/) - Package management.
- [Rokit](https://github.com/rojo-rbx/rokit) - Toolchain management.
