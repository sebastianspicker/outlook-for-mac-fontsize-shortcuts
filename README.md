# Outlook Text Display Size Controller with Hammerspoon

A Hammerspoon-based tool to quickly adjust the “Text display size” in both **New Outlook** and **Legacy Outlook** for Mac.  
Provides global hotkeys, a menubar dropdown, notifications & canvas overlays, external JSON configuration, i18n, accessibility checks, retry logic, and toggle-cycle state.

> **Notice:** This repository is provided **as is** and is **no longer maintained**. It may stop working with future Outlook for Mac updates, as it relies on UI automation (accessibility APIs) that can change when Microsoft updates the application. Use at your own discretion.

## Problem Statement

- **Outlook for Mac (Legacy)** only offers a coarse slider under **Outlook → Preferences… → Fonts** with three positions (Standard, Large, Larger).  
- **New Outlook for Mac** replaces the slider with “+” / “–” buttons under **Personal Settings → General → Text display size**.  
- Switching text size manually is slow and cumbersome, especially for power users who want instant shortcuts.

## Solution Overview

This project uses [Hammerspoon](https://www.hammerspoon.org/) to automate UI interactions:

1. **Detect** whether Outlook is Legacy or New edition.  
2. **Focus** or launch the Outlook app.  
3. **Open** the correct menu (`Settings…` vs. `Preferences…`).  
4. **Wait** for the window to appear (with configurable timeouts & retries).  
5. **Legacy**: Locate the slider and increment/decrement its value.  
6. **New**: Select the **General** tile, then click “+” / “–” buttons.  
7. **Close** the window.  
8. **Display** visual feedback via notifications (banners) and a canvas overlay.  
9. **Bind** three hotkeys:  
   - **Ctrl+Alt+Cmd+G** → Increase  
   - **Ctrl+Alt+Cmd+K** → Decrease  
   - **Ctrl+Alt+Cmd+T** → Toggle (cycles between increase/decrease)  
10. **Provide** a menubar dropdown for mouse-driven control.  
11. **Allow** external JSON overrides for all configurable parameters.

## Features

- **Legacy & New Outlook support**  
- **Global hotkeys** for increase, decrease, toggle  
- **Menubar dropdown** for GUI control  
- **Visual feedback**: macOS notifications + canvas overlay  
- **External JSON config** (`~/.hammerspoon/outlook-font.json`)  
- **i18n**: English, German, French, Spanish UI text matching  
- **Accessibility health-check** with helpful instructions  
- **Dynamic timeouts** and **retry logic**  
- **Modular** Lua code for easy maintenance  

## Prerequisites

- macOS (tested on Ventura, Sonoma)  
- Outlook for Mac (Legacy or New) installed and signed in  
- [Hammerspoon](https://www.hammerspoon.org/) installed  
  ```bash
  brew install hammerspoon
  ```
- Accessibility permissions for Hammerspoon:
  System Settings → Privacy & Security → Accessibility → Enable Hammerspoon

## Installation

1. Clone this repo (or copy files into `~/.hammerspoon/`):
   ```bash
   git clone <repo-url>
   cd outlook-for-mac-fontsize-shortcuts

   cp outlook-font.lua ~/.hammerspoon/outlook-font.lua
   cp -R outlook_font  ~/.hammerspoon/outlook_font
   cp init.lua         ~/.hammerspoon/init.lua
   ```

2. (Optional) Create or edit JSON config (JSONC-style `//` and `/* */` comments are allowed):
```bash
cp outlook-font.json ~/.hammerspoon/outlook-font.json
```

3. Reload Hammerspoon:
- Press Ctrl+Alt+Cmd+R
- Or click the menubar icon → Reload Config

## Quickstart
1. Copy `init.lua`, `outlook-font.lua`, and `outlook_font/` into `~/.hammerspoon/`.
2. Reload Hammerspoon.
3. Use the hotkeys or the menubar dropdown to change text size.
 

## Configuration

All defaults are defined in `outlook-font.lua`. You may override any key by editing `~/.hammerspoon/outlook-font.json`. Example:

```jsonc
{
  // Application names
  "appNames": ["Outlook", "Microsoft Outlook"],

  // Menus to open New Outlook vs. Legacy
  "settingsMenu":    ["Outlook", "Settings…"],
  "preferencesMenu": ["Outlook", "Preferences…"],

  // Header titles (i18n)
  "headerLabels": ["Personal Settings", "Persönliche Einstellungen"],

  // Text-display labels (i18n)
  "labelTexts": ["Text display size", "Größe der Textanzeige"],

  // Timing overrides (seconds)
  "delays": {
    "activate": 0.1,
    "waitInterval": 0.05,
    "timeout": 3
  },

  // Retry logic
  "retry": {
    "attempts": 2,
    "interval": 0.2
  }
}
```

## Usage
- Hotkeys:
  - Ctrl+Alt+Cmd+G → Increase text size
  - Ctrl+Alt+Cmd+K → Decrease text size
  - Ctrl+Alt+Cmd+T → Toggle (cycles between increase/decrease)
- Menubar:
  Click the 🔤 icon, then choose:
  - Smaller Text Size
  - Larger Text Size
  - Toggle Text Size
  - Reload Hammerspoon Config
Each action will show a brief notification and a canvas overlay in the center of your screen.

## Troubleshooting
- No hotkeys?
  - Ensure Hammerspoon is running and has Accessibility permission.
  - Check for binding conflicts in other apps.
- Menu icon missing?
- Verify your `init.lua` is loaded without errors (Hammerspoon console).
  - Slider/buttons not working?
  - Use macOS Accessibility Inspector to confirm UI roles and labels.
  - Adjust delays in JSON if Outlook is slow.
- JSON overrides not applied?
  - Ensure `~/.hammerspoon/outlook-font.json` is valid JSON (or JSONC with comments).
  - Restart or reload Hammerspoon after editing.

## Security
- This project automates UI interactions only and does not access message content.
- If you discover a security issue, open a GitHub issue with minimal repro steps and avoid including secrets or personal data.

## Testing
```bash
make test
```

## Development

Tooling:

```bash
brew install lua luarocks stylua
make tools
```

Quality gates:

```bash
make fmt
make lint
make test
```
