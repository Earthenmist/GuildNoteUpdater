local addonName = "GuildNotesUpdater"
local frame = CreateFrame("Frame")

-- Default settings
local defaultSettings = {
    defaultNote = "New recruit - Please update!",
    updateOfficerNote = false,
    minimap = {hide = false}, -- Minimap button visibility
    autoUpdateEnabled = false, -- Auto-Update toggle
    autoUpdateInterval = 10 -- Auto-Update interval in minutes
}

-- ✅ Ensure Saved Variables are Initialized Properly
local function EnsureSavedVariables()
    if type(GuildNotesUpdaterDB) ~= "table" then
        -- ✅ If GuildNotesUpdaterDB is nil or corrupted, reset it to default settings
        print("|cffff0000[GuildNotesUpdater]|r Database was missing or corrupted. Resetting to default settings.")
        GuildNotesUpdaterDB = {}
    end

    -- ✅ Now safely copy default settings
    for k, v in pairs(defaultSettings) do
        if GuildNotesUpdaterDB[k] == nil then
            GuildNotesUpdaterDB[k] = v
        end
    end
end

-- ✅ Define UpdateGuildNotes function before using it
local function UpdateGuildNotes()
    if not IsInGuild() then
        print("|cff00ff00[GuildNotesUpdater]|r You are not in a guild.")
        return
    end

    C_GuildInfo.GuildRoster()

    local noteType = GuildNotesUpdaterDB.updateOfficerNote and "Officer" or "Public"
    local defaultNote = GuildNotesUpdaterDB.defaultNote
    local notesUpdated = 0 -- ✅ Track if any updates were made

    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, publicNote, officerNote = GetGuildRosterInfo(i)

        if GuildNotesUpdaterDB.updateOfficerNote then
            if officerNote == "" or officerNote == nil then
                if CanEditOfficerNote() then
                    GuildRosterSetOfficerNote(i, defaultNote)
                    print("|cff00ff00[GuildNotesUpdater]|r Updated Officer Note for " .. name)
                    notesUpdated = notesUpdated + 1 -- ✅ Count the update
                else
                    print("|cffff0000[GuildNotesUpdater]|r Cannot edit officer notes.")
                    break
                end
            end
        else
            if publicNote == "" or publicNote == nil then
                if CanEditPublicNote() then
                    GuildRosterSetPublicNote(i, defaultNote)
                    print("|cff00ff00[GuildNotesUpdater]|r Updated Public Note for " .. name)
                    notesUpdated = notesUpdated + 1 -- ✅ Count the update
                else
                    print("|cffff0000[GuildNotesUpdater]|r Cannot edit public notes.")
                    break
                end
            end
        end
    end

    -- ✅ Only print this if at least one note was updated
    if notesUpdated > 0 then
        print("|cff00ff00[GuildNotesUpdater]|r Guild note update complete! (" .. notesUpdated .. " notes updated)")
    end
end

-- ✅ Auto-Update Timer Logic (Runs Only If Enabled)
local autoUpdateTimer = nil

local function StartAutoUpdate()
    if autoUpdateTimer then
        autoUpdateTimer:Cancel()
    end

    if GuildNotesUpdaterDB.autoUpdateEnabled then
        print(
            "|cff00ff00[GuildNotesUpdater]|r Auto-Update Enabled! Checking every " ..
                GuildNotesUpdaterDB.autoUpdateInterval .. " minutes."
        )

        autoUpdateTimer =
            C_Timer.NewTicker(
            GuildNotesUpdaterDB.autoUpdateInterval * 60,
            function()
                -- print("|cff00ff00[GuildNotesUpdater]|r Running Auto-Update check...")
                C_GuildInfo.GuildRoster()

                -- ✅ Call UpdateGuildNotes with a delay to allow the guild roster to refresh
                C_Timer.After(
                    2,
                    function()
                        UpdateGuildNotes() -- ✅ No more nil value error!
                    end
                )
            end
        )
    else
        print("|cffff0000[GuildNotesUpdater]|r Auto-Update Disabled.")
    end
end

-- Function to create the settings frame
local function CreateSettingsFrame()
    if GuildNotesUpdaterFrame then
        return
    end

    local frame = CreateFrame("Frame", "GuildNotesUpdaterFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(320, 280)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("Guild Notes Updater")

    -- Allow closing the window with Escape
    tinsert(UISpecialFrames, "GuildNotesUpdaterFrame")

    -- Edit Box for Default Note
    frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.editBox:SetSize(200, 30)
    frame.editBox:SetPoint("TOP", frame, "TOP", 0, -40)
    frame.editBox:SetAutoFocus(false)
    frame.editBox:SetText(GuildNotesUpdaterDB.defaultNote or defaultSettings.defaultNote)

    -- Checkbox for Note Type
    frame.dropDown = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.dropDown:SetPoint("TOPLEFT", frame.editBox, "BOTTOMLEFT", -5, -10)
    frame.dropDown.text:SetText("Use Officer Note")
    frame.dropDown:SetChecked(GuildNotesUpdaterDB.updateOfficerNote)

    -- ✅ Checkbox for Auto-Update
    frame.autoUpdateCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.autoUpdateCheck:SetPoint("TOPLEFT", frame.dropDown, "BOTTOMLEFT", 0, -10)
    frame.autoUpdateCheck.text:SetText("Enable Auto-Update")
    frame.autoUpdateCheck:SetChecked(GuildNotesUpdaterDB.autoUpdateEnabled)

    -- ✅ Dropdown for Auto-Update Interval
    frame.autoUpdateDropdown = CreateFrame("Frame", "AutoUpdateIntervalDropdown", frame, "UIDropDownMenuTemplate")
    frame.autoUpdateDropdown:SetPoint("TOPLEFT", frame.autoUpdateCheck, "BOTTOMLEFT", -10, -5)

    local intervals = {5, 10, 15, 30}
    local function SetInterval(self, arg1)
        GuildNotesUpdaterDB.autoUpdateInterval = arg1
        UIDropDownMenu_SetText(frame.autoUpdateDropdown, arg1 .. " min")
        StartAutoUpdate()
    end

    UIDropDownMenu_Initialize(
        frame.autoUpdateDropdown,
        function(self, level, menuList)
            for _, interval in ipairs(intervals) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = interval .. " min"
                info.arg1 = interval
                info.func = SetInterval
                info.checked = (GuildNotesUpdaterDB.autoUpdateInterval == interval)
                UIDropDownMenu_AddButton(info)
            end
        end
    )

    UIDropDownMenu_SetText(frame.autoUpdateDropdown, GuildNotesUpdaterDB.autoUpdateInterval .. " min")

    -- Save Button
    frame.saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.saveButton:SetSize(100, 25)
    frame.saveButton:SetPoint("BOTTOM", frame, "BOTTOM", -60, 10)
    frame.saveButton:SetText("Save")
    frame.saveButton:SetScript(
        "OnClick",
        function()
            GuildNotesUpdaterDB.defaultNote = frame.editBox:GetText()
            GuildNotesUpdaterDB.updateOfficerNote = frame.dropDown:GetChecked()
            GuildNotesUpdaterDB.autoUpdateEnabled = frame.autoUpdateCheck:GetChecked()
            StartAutoUpdate()
            print("|cff00ff00[GuildNotesUpdater]|r Settings saved!")
        end
    )

    -- Apply Button (Update Notes)
    frame.applyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.applyButton:SetSize(100, 25)
    frame.applyButton:SetPoint("BOTTOM", frame, "BOTTOM", 60, 10)
    frame.applyButton:SetText("Update Notes")

    frame.applyButton:SetScript(
        "OnClick",
        function()
            UpdateGuildNotes()
        end
    )

    -- ✅ Function to update the tooltip text dynamically
    local function UpdateTooltip()
        GameTooltip:SetOwner(frame.applyButton, "ANCHOR_RIGHT")
        if frame.dropDown:GetChecked() then
            GameTooltip:SetText("Only updates blank Officer Notes.", 1, 1, 1, true)
        else
            GameTooltip:SetText("Only updates blank Public Notes.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end

    -- ✅ Add Tooltip on Hover
    frame.applyButton:SetScript(
        "OnEnter",
        function()
            UpdateTooltip()
        end
    )

    frame.applyButton:SetScript(
        "OnLeave",
        function()
            GameTooltip:Hide()
        end
    )

    -- ✅ Update tooltip dynamically when the checkbox is toggled
    frame.dropDown:SetScript(
        "OnClick",
        function(self)
            GuildNotesUpdaterDB.updateOfficerNote = self:GetChecked()
            UpdateTooltip() -- Ensure the tooltip updates instantly when checkbox changes
        end
    )

    frame:Hide()
end

-- Function to open the settings window
local function OpenSettingsWindow()
    if not GuildNotesUpdaterFrame then
        CreateSettingsFrame()
    end
    GuildNotesUpdaterFrame:Show()
end

-- Minimap Button using LibDataBroker & LibDBIcon
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local GuildNotesUpdaterLDB =
    LDB:NewDataObject(
    "GuildNotesUpdater",
    {
        type = "launcher",
        text = "Guild Note Updater",
        icon = "Interface\\Icons\\INV_Scroll_11", -- Scroll Icon
        OnClick = function(_, button)
            if button == "LeftButton" then
                OpenSettingsWindow()
            elseif button == "RightButton" then
                GuildNotesUpdaterDB.minimap.hide = not GuildNotesUpdaterDB.minimap.hide
                if GuildNotesUpdaterDB.minimap.hide then
                    LDBIcon:Hide("GuildNotesUpdater")
                    print(
                        "|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again."
                    )
                else
                    LDBIcon:Show("GuildNotesUpdater")
                    print("|cff00ff00[GuildNotesUpdater]|r Minimap button shown.")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Guild Note Updater")
            tooltip:AddLine("|cffffff00Left Click:|r Open Settings")
            tooltip:AddLine("|cffffff00Right Click:|r Toggle Minimap Icon")
        end
    }
)

-- Register slash commands after ADDON_LOADED
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- ✅ Ensure Auto-Update starts after login
frame:SetScript(
    "OnEvent",
    function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            -- ✅ Auto-Update starts automatically when entering the world
            EnsureSavedVariables() -- ✅ This will no longer be nil!

            -- Register minimap button after variables are loaded
            LDBIcon:Register("GuildNotesUpdater", GuildNotesUpdaterLDB, GuildNotesUpdaterDB.minimap)
            if GuildNotesUpdaterDB.minimap.hide then
                LDBIcon:Hide("GuildNotesUpdater")
            end

            -- ✅ Register Slash Commands
            SLASH_GUILDNOTE1 = "/guildnotes"
            SLASH_GUILDNOTE2 = "/gnotes"
            SlashCmdList["GUILDNOTE"] = function(msg)
                if msg == "minimap" then
                    GuildNotesUpdaterDB.minimap.hide = not GuildNotesUpdaterDB.minimap.hide
                    if GuildNotesUpdaterDB.minimap.hide then
                        LDBIcon:Hide("GuildNotesUpdater")
                        print(
                            "|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again."
                        )
                    else
                        LDBIcon:Show("GuildNotesUpdater")
                        print("|cff00ff00[GuildNotesUpdater]|r Minimap button shown.")
                    end
                elseif msg == "auto" then
                    GuildNotesUpdaterDB.autoUpdateEnabled = not GuildNotesUpdaterDB.autoUpdateEnabled
                    StartAutoUpdate()
                    print(
                        "|cff00ff00[GuildNotesUpdater]|r Auto-Update is now " ..
                            (GuildNotesUpdaterDB.autoUpdateEnabled and "Enabled" or "Disabled") .. "."
                    )
                else
                    OpenSettingsWindow()
                end
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            if GuildNotesUpdaterDB.autoUpdateEnabled then
                -- print("|cff00ff00[GuildNotesUpdater]|r Auto-Update is enabled. Resuming updates every " .. GuildNotesUpdaterDB.autoUpdateInterval .. " minutes.")
                StartAutoUpdate()
            end
        end
    end
)
