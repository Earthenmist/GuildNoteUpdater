## :jigsaw: Addon Updates (2026-01-16)

**Guild Notes Updater** — v1.2.3  

**Changes:**  
• Improved guild state handling so Auto-Update pauses safely if guild context is temporarily unavailable.  
• Auto-Update now resumes automatically and silently when valid guild data returns (if previously enabled).  
• Prevents false “paused” states caused by brief guild API inconsistencies.

**Fixes:**  
• Fixed an issue where Auto-Update could appear to disable itself during normal play while not in an instance.  
• Auto-Update is now fully persistent across login, zoning, and guild roster refreshes.  
• Temporary loss of guild data no longer clears or unticks the saved setting.

**Known issues:**  
• None currently known.
