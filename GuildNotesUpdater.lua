local addonName = "GuildNotesUpdater"
local frame = CreateFrame("Frame")

-- ================================
-- Defaults (expanded for Midnight)
-- ================================
local defaultSettings = {
    defaultNote = "New recruit - Please update!",
    updateOfficerNote = false,
    minimap = { hide = false },
    autoUpdateEnabled = false,
    autoUpdateInterval = 10, -- minutes
    -- NEW: Behavior controls for instances/raids
    pauseInInstances = true,  -- pause auto checks while in any instance (party/raid/pvp/arena/scenario)
    muteInInstances  = true,  -- suppress chat prints while in any instance
}

-- Utility: shallow copy defaults where missing
local function EnsureSavedVariables()
    if type(GuildNotesUpdaterDB) ~= "table" then
        GuildNotesUpdaterDB = {}
        print("|cffff0000[GuildNotesUpdater]|r Database was missing or corrupted. Resetting to default settings.")
    end
    for k, v in pairs(defaultSettings) do
        if GuildNotesUpdaterDB[k] == nil then
            GuildNotesUpdaterDB[k] = v
        end
    end
end

-- ================================
-- Instance / chat control helpers
-- ================================
local function IsInAnyInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end
    -- Consider all non-"none" instance types as instances we should respect
    return instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena" or instanceType == "scenario"
end

-- Centralized print that respects mute rules
local function GNU_Print(msg, force)
    if force then
        print(msg)
        return
    end
    if GuildNotesUpdaterDB and GuildNotesUpdaterDB.muteInInstances and IsInAnyInstance() then
        -- muted in instances
        return
    end
    print(msg)
end

-- ================================
-- Core updater
-- ================================
local function UpdateGuildNotes()
    -- Respect pause rule inside instances
    if GuildNotesUpdaterDB.pauseInInstances and IsInAnyInstance() then
        return -- silently skip while in instances (no chat spam)
    end

    if not IsInGuild() then
        GNU_Print("|cff00ff00[GuildNotesUpdater]|r You are not in a guild.")
        return
    end

    C_GuildInfo.GuildRoster()

    local noteType = GuildNotesUpdaterDB.updateOfficerNote and "Officer" or "Public"
    local defaultNote = GuildNotesUpdaterDB.defaultNote
    local notesUpdated = 0

    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, publicNote, officerNote = GetGuildRosterInfo(i)

        if GuildNotesUpdaterDB.updateOfficerNote then
            if officerNote == "" or officerNote == nil then
                if CanEditOfficerNote() then
                    GuildRosterSetOfficerNote(i, defaultNote)
                    GNU_Print("|cff00ff00[GuildNotesUpdater]|r Updated Officer Note for " .. name)
                    notesUpdated = notesUpdated + 1
                else
                    GNU_Print("|cffff0000[GuildNotesUpdater]|r Cannot edit officer notes.")
                    break
                end
            end
        else
            if publicNote == "" or publicNote == nil then
                if CanEditPublicNote() then
                    GuildRosterSetPublicNote(i, defaultNote)
                    GNU_Print("|cff00ff00[GuildNotesUpdater]|r Updated Public Note for " .. name)
                    notesUpdated = notesUpdated + 1
                else
                    GNU_Print("|cffff0000[GuildNotesUpdater]|r Cannot edit public notes.")
                    break
                end
            end
        end
    end

    if notesUpdated > 0 then
        GNU_Print("|cff00ff00[GuildNotesUpdater]|r Guild note update complete! (" .. notesUpdated .. " notes updated)")
    end
end

-- ================================
-- Auto update ticker with instance-awareness
-- ================================
local autoUpdateTimer
local function StopAutoUpdate()
    if autoUpdateTimer then
        autoUpdateTimer:Cancel()
        autoUpdateTimer = nil
    end
end

local function StartAutoUpdate()
    StopAutoUpdate()

    if not GuildNotesUpdaterDB.autoUpdateEnabled then
        GNU_Print("|cffff0000[GuildNotesUpdater]|r Auto-Update Disabled.")
        return
    end

    -- If we're configured to pause in instances and currently in one, don't start the ticker yet
    if GuildNotesUpdaterDB.pauseInInstances and IsInAnyInstance() then
        GNU_Print("|cff00ff00[GuildNotesUpdater]|r Auto-Update paused in instance.")
        return
    end

    GNU_Print("|cff00ff00[GuildNotesUpdater]|r Auto-Update Enabled! Checking every " .. GuildNotesUpdaterDB.autoUpdateInterval .. " minutes.")

    autoUpdateTimer = C_Timer.NewTicker(GuildNotesUpdaterDB.autoUpdateInterval * 60, function()
        -- Avoid work if we zone into an instance mid-tick
        if GuildNotesUpdaterDB.pauseInInstances and IsInAnyInstance() then
            return
        end

        C_GuildInfo.GuildRoster()
        C_Timer.After(2, UpdateGuildNotes)
    end)
end

-- ================================
-- Retail Settings Panel (Blizzard Options)
-- ================================
local optionsPanel, optionsCategory
local function CreateOptionsPanel()
    if optionsPanel then return end

    optionsPanel = CreateFrame("Frame")
    optionsPanel.name = "Guild Notes Updater"

    -- Register with Retail Settings UI
    if Settings and Settings.RegisterCanvasLayoutCategory then
        optionsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(optionsCategory)
    elseif InterfaceOptions_AddCategory then
        -- Fallback (shouldn't be needed on retail, but safe)
        InterfaceOptions_AddCategory(optionsPanel)
    end

    -- Title
    local title = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Guild Notes Updater")

    -- Default Note label + editbox
    local noteLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noteLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    noteLabel:SetText("Default Note:")

    local editBox = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetSize(280, 30)
    editBox:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -6)
    editBox:SetText(GuildNotesUpdaterDB.defaultNote or defaultSettings.defaultNote)

    -- Use Officer Note
    local officerCheck = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
    officerCheck.text:SetText("Use Officer Note")
    officerCheck:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", -4, -10)
    officerCheck:SetChecked(GuildNotesUpdaterDB.updateOfficerNote)

    -- Auto-Update toggle
    local autoCheck = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
    autoCheck.text:SetText("Enable Auto-Update")
    autoCheck:SetPoint("TOPLEFT", officerCheck, "BOTTOMLEFT", 0, -8)
    autoCheck:SetChecked(GuildNotesUpdaterDB.autoUpdateEnabled)

    -- Interval dropdown
    local intervalDrop = CreateFrame("Frame", "GuildNotesUpdater_AutoIntervalDrop", optionsPanel, "UIDropDownMenuTemplate")
    intervalDrop:SetPoint("TOPLEFT", autoCheck, "BOTTOMLEFT", -10, -6)

    local intervals = {5, 10, 15, 30}
    local function SetInterval(value)
        GuildNotesUpdaterDB.autoUpdateInterval = value
        UIDropDownMenu_SetText(intervalDrop, value .. " min")
        StartAutoUpdate()
    end
    UIDropDownMenu_Initialize(intervalDrop, function()
        for _, v in ipairs(intervals) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v .. " min"
            info.func = function() SetInterval(v) end
            info.checked = (GuildNotesUpdaterDB.autoUpdateInterval == v)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(intervalDrop, GuildNotesUpdaterDB.autoUpdateInterval .. " min")

    -- Pause in instances
    local pauseCheck = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
    pauseCheck.text:SetText("Pause Auto-Update in Instances")
    pauseCheck:SetPoint("TOPLEFT", intervalDrop, "BOTTOMLEFT", 16, -6)
    pauseCheck:SetChecked(GuildNotesUpdaterDB.pauseInInstances)

    -- Mute in instances
    local muteCheck = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
    muteCheck.text:SetText("Mute Chat Prints in Instances")
    muteCheck:SetPoint("TOPLEFT", pauseCheck, "BOTTOMLEFT", 0, -6)
    muteCheck:SetChecked(GuildNotesUpdaterDB.muteInInstances)

    -- Apply/Save style: Settings panel auto-saves when changed; we'll save on focus lost / clicks
    editBox:SetScript("OnEditFocusLost", function()
        GuildNotesUpdaterDB.defaultNote = editBox:GetText()
    end)
    officerCheck:SetScript("OnClick", function(self)
        GuildNotesUpdaterDB.updateOfficerNote = self:GetChecked()
    end)
    autoCheck:SetScript("OnClick", function(self)
        GuildNotesUpdaterDB.autoUpdateEnabled = self:GetChecked()
        StartAutoUpdate()
    end)
    pauseCheck:SetScript("OnClick", function(self)
        GuildNotesUpdaterDB.pauseInInstances = self:GetChecked()
        StartAutoUpdate()
    end)
    muteCheck:SetScript("OnClick", function(self)
        GuildNotesUpdaterDB.muteInInstances = self:GetChecked()
    end)

    -- Status line
    local status = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("TOPLEFT", muteCheck, "BOTTOMLEFT", 4, -12)
    local function RefreshStatus()
        local active = GuildNotesUpdaterDB.autoUpdateEnabled and not (GuildNotesUpdaterDB.pauseInInstances and IsInAnyInstance())
        status:SetText("Status: " .. (active and "|cff20ff20Active|r" or "|cffff4040Paused|r"))
    end
    C_Timer.NewTicker(1.0, RefreshStatus)
    RefreshStatus()
end

local function OpenOptions()
    if not optionsPanel then CreateOptionsPanel() end
    if Settings and Settings.OpenToCategory and optionsCategory and optionsCategory.GetID then
        pcall(function() Settings.OpenToCategory(optionsCategory:GetID()) end)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    end
end

-- ================================
-- Minimap button (LDB / DBIcon)
-- ================================
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local GuildNotesUpdaterLDB = LDB:NewDataObject("GuildNotesUpdater", {
    type = "launcher",
    text = "Guild Note Updater",
    icon = "Interface\\Icons\\INV_Scroll_11",
    OnClick = function(_, button)
        if button == "LeftButton" then
            OpenOptions()
        elseif button == "RightButton" then
            GuildNotesUpdaterDB.minimap.hide = not GuildNotesUpdaterDB.minimap.hide
            if GuildNotesUpdaterDB.minimap.hide then
                LDBIcon:Hide("GuildNotesUpdater")
                GNU_Print("|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again.", true)
            else
                LDBIcon:Show("GuildNotesUpdater")
                GNU_Print("|cff00ff00[GuildNotesUpdater]|r Minimap button shown.", true)
            end
        end
    end,
    OnTooltipShow = function(t)
        t:AddLine("Guild Note Updater")
        t:AddLine("|cffffff00Left Click:|r Open Settings")
        t:AddLine("|cffffff00Right Click:|r Toggle Minimap Icon")
    end
})

-- ================================
-- Events & slash commands
-- ================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- detect instance transitions reliably

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        EnsureSavedVariables()

        LDBIcon:Register("GuildNotesUpdater", GuildNotesUpdaterLDB, GuildNotesUpdaterDB.minimap)
        if GuildNotesUpdaterDB.minimap.hide then
            LDBIcon:Hide("GuildNotesUpdater")
        end

        SLASH_GUILDNOTE1 = "/guildnotes"
        SLASH_GUILDNOTE2 = "/gnotes"
        SlashCmdList["GUILDNOTE"] = function(msg)
            msg = (msg or ""):lower()
            if msg == "minimap" then
                GuildNotesUpdaterDB.minimap.hide = not GuildNotesUpdaterDB.minimap.hide
                if GuildNotesUpdaterDB.minimap.hide then
                    LDBIcon:Hide("GuildNotesUpdater")
                    GNU_Print("|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again.", true)
                else
                    LDBIcon:Show("GuildNotesUpdater")
                    GNU_Print("|cff00ff00[GuildNotesUpdater]|r Minimap button shown.", true)
                end
            elseif msg == "auto" then
                GuildNotesUpdaterDB.autoUpdateEnabled = not GuildNotesUpdaterDB.autoUpdateEnabled
                StartAutoUpdate()
                GNU_Print("|cff00ff00[GuildNotesUpdater]|r Auto-Update is now " ..
                    (GuildNotesUpdaterDB.autoUpdateEnabled and "Enabled" or "Disabled") .. ".", true)
            elseif msg == "pause" then
                GuildNotesUpdaterDB.pauseInInstances = not GuildNotesUpdaterDB.pauseInInstances
                GNU_Print("|cff00ff00[GuildNotesUpdater]|r Pause in instances: " ..
                    (GuildNotesUpdaterDB.pauseInInstances and "ON" or "OFF"), true)
                StartAutoUpdate()
            elseif msg == "mute" then
                GuildNotesUpdaterDB.muteInInstances = not GuildNotesUpdaterDB.muteInInstances
                GNU_Print("|cff00ff00[GuildNotesUpdater]|r Mute in instances: " ..
                    (GuildNotesUpdaterDB.muteInInstances and "ON" or "OFF"), true)
            else
                OpenOptions()
            end
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if GuildNotesUpdaterDB.autoUpdateEnabled then
            if GuildNotesUpdaterDB.pauseInInstances and IsInAnyInstance() then
                StopAutoUpdate()
                GNU_Print("|cff00ff00[GuildNotesUpdater]|r Auto-Update paused in instance.")
            else
                StartAutoUpdate()
            end
        end
    end
end)
