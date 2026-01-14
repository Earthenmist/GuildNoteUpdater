📜 Changelog – Version 1.2.2  
  
📅 Release Date: 14-01-2026  
🎯 Expansion: The War Within / Midnight Pre-Patch  
  
🛠️ Fixes & Improvements  
🔕 Auto-Update Chat Spam Fixed  
  
Resolved an issue where “Auto-Update Enabled” messages were repeatedly printed during:
  
Hearthstone usage  
Zone changes  
Loading screens  
  
The message now only appears:  

Once per login session  
When auto-update is manually enabled  
When the update interval is changed  
  
🔒 Guild-Only Auto-Update Enforcement  
  
Auto-Update now requires guild membership  
Auto-update is automatically disabled if the player is not in a guild  
The Enable Auto-Update checkbox is greyed out while unguilded  
The Run Now button is also disabled while unguilded  
Existing settings are preserved and automatically restored once the player rejoins a guild  
  
🧠 Improved State Handling  
  
Fixed an issue where zoning or hearthstoning could temporarily unset the auto-update toggle  
Guild status is now validated safely without wiping saved settings during transitions  
Auto-update restarts silently when appropriate instead of re-announcing  
  
⚠️ Notes  
  
Fully compatible with Midnight  
No configuration reset required  
Safe to update mid-session  
  
🚀 Thank you for using Guild Notes Updater! If you encounter issues or have feature requests, please share them via our GitHub. 🚀  
