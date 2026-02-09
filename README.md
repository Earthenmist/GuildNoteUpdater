# Guild Notes Updater

**Guild Notes Updater** is a simple World of Warcraft addon that helps guild officers automatically fill **blank guild notes** with a predefined message.

It supports both **Public Notes** and **Officer Notes**, includes a small configuration UI, and provides a minimap button + slash commands for quick access.

## ✨ Features
- Automatically fills blank **Public** or **Officer** notes with your custom message
- Simple UI to configure:
  - Default note text
  - Note type (Public or Officer)
- Minimap button for quick access (can be toggled on/off)
- Tooltip support for clarity on what the **Update Notes** button will change
- Right-click minimap button to hide/show it (can be restored via `/gnotes minimap`)
- Persistent saved settings between sessions
- Slash commands for quick access

## 🗺️ How to Use
### Opening the Addon Settings
You can open the settings window by:
- Clicking the minimap button
- Typing `/guildnotes` or `/gnotes`

### Customising Notes
1. Open the settings window
2. Enter a default note (example: `New recruit - Please update!`)
3. Choose whether to update **Public** or **Officer** Notes
4. Click **Save**

### Updating Guild Notes
1. Click the **Update Notes** button
2. The addon will fill in any blank notes with your preset message
3. The tooltip will show whether you're updating Public or Officer Notes

### Minimap Button
- Left-click: open settings
- Right-click: toggle minimap button visibility
- If hidden: use `/gnotes minimap` to restore it

## 💬 Slash Commands
| Command | Function |
|--------|----------|
| `/guildnotes` or `/gnotes` | Opens the settings window |
| `/gnotes minimap` | Toggles the minimap button on/off |

## 📦 Install
### CurseForge
- Install via the CurseForge app or download the latest release.

### Manual
1. Download the latest release `.zip`.
2. Extract into: `World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure the folder name is `GuildNotesUpdater` (not nested).
4. Relaunch the game.

## 🧩 Compatibility
- **Game:** Retail
- **Dependencies:** LibDataBroker, LibDBIcon (embedded)

## 💬 Support & Community
For bug reports, feature requests, release notes, and beta builds, join the official Discord:

**LanniOfAlonsus • Addon Hub**  
https://discord.gg/U8mKfHpeeP

## 📜 License
All Rights Reserved.

## ❤️ Credits
- **Author:** LanniOfAlonsus  
- Libraries: LibDataBroker, LibDBIcon
