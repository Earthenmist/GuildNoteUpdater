📜 Changelog – Version 1.2.3  
  
📅 Release Date: 16-01-2026  
🎯 Expansion: The War Within / Midnight Pre-Patch  
  
🛠️ Fixes & Improvements  
🔁 Auto-Update Persistence Fix  
  
Fixed an issue where Auto-Update could appear to disable itself during normal play while not in an instance.  
The auto-update toggle is now fully persistent across login, zoning, and guild roster refreshes.  
Temporary loss of guild data (e.g. during UI refreshes or transitions) no longer clears or unticks the saved setting.  
  
🧠 Improved Guild State Handling  
  
Auto-Update will pause safely if the guild context is temporarily unavailable, without modifying saved preferences.  
When valid guild data returns, auto-update resumes automatically and silently if it was previously enabled.  
Prevents false “paused” states caused by brief guild API inconsistencies.  
  
⚠️ Notes  
  
Fully compatible with Midnight  
No configuration reset required  
Safe to update mid-session  
  
🚀 Thank you for using Guild Notes Updater!  
If you encounter issues or have feature requests, please share them via GitHub.  
