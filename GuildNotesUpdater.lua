local addonName = "GuildNotesUpdater"
local frame = CreateFrame("Frame")

-- Default settings
local defaultSettings = {
    defaultNote = "New recruit - Please update!",
    updateOfficerNote = false,
    minimap = { hide = false } -- Minimap button visibility
}

-- ✅ Define UpdateGuildNotes function before using it
local function UpdateGuildNotes()
    if not IsInGuild() then
        print("|cff00ff00[GuildNotesUpdater]|r You are not in a guild.")
        return
    end

    C_GuildInfo.GuildRoster()

    local noteType = GuildNotesUpdaterDB.updateOfficerNote and "Officer" or "Public"
    local defaultNote = GuildNotesUpdaterDB.defaultNote

    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, publicNote, officerNote = GetGuildRosterInfo(i)

        if GuildNotesUpdaterDB.updateOfficerNote then
            if officerNote == "" or officerNote == nil then
                if CanEditOfficerNote() then
                    GuildRosterSetOfficerNote(i, defaultNote)
                    print("|cff00ff00[GuildNotesUpdater]|r Updated Officer Note for " .. name)
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
                else
                    print("|cffff0000[GuildNotesUpdater]|r Cannot edit public notes.")
                    break
                end
            end
        end
    end

    print("|cff00ff00[GuildNotesUpdater]|r Guild note update complete!")
end

-- Function to create the settings frame
local function CreateSettingsFrame()
    if GuildNotesUpdaterFrame then return end

    local frame = CreateFrame("Frame", "GuildNotesUpdaterFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(320, 180)
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

    -- Save Button
    frame.saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.saveButton:SetSize(100, 25)
    frame.saveButton:SetPoint("BOTTOM", frame, "BOTTOM", -60, 10)
    frame.saveButton:SetText("Save")
    frame.saveButton:SetScript("OnClick", function()
        GuildNotesUpdaterDB.defaultNote = frame.editBox:GetText()
        GuildNotesUpdaterDB.updateOfficerNote = frame.dropDown:GetChecked()
        print("|cff00ff00[GuildNotesUpdater]|r Settings saved!")
    end)

-- Apply Button (Update Notes)
frame.applyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
frame.applyButton:SetSize(100, 25)
frame.applyButton:SetPoint("BOTTOM", frame, "BOTTOM", 60, 10)
frame.applyButton:SetText("Update Notes")

frame.applyButton:SetScript("OnClick", function()
    UpdateGuildNotes()
end)

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
frame.applyButton:SetScript("OnEnter", function()
    UpdateTooltip()
end)

frame.applyButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ✅ Update tooltip dynamically when the checkbox is toggled
frame.dropDown:SetScript("OnClick", function(self)
    GuildNotesUpdaterDB.updateOfficerNote = self:GetChecked()
    UpdateTooltip() -- Ensure the tooltip updates instantly when checkbox changes
end)


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

local GuildNotesUpdaterLDB = LDB:NewDataObject("GuildNotesUpdater", {
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
                print("|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again.")
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
    end,
})

-- Register slash commands after ADDON_LOADED
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Ensure GuildNotesUpdaterDB exists
        if not GuildNotesUpdaterDB then
            GuildNotesUpdaterDB = CopyTable(defaultSettings)
        else
            for k, v in pairs(defaultSettings) do
                if GuildNotesUpdaterDB[k] == nil then
                    GuildNotesUpdaterDB[k] = v
                end
            end
        end

        -- Register minimap button after variables are loaded
        LDBIcon:Register("GuildNotesUpdater", GuildNotesUpdaterLDB, GuildNotesUpdaterDB.minimap)

        -- Hide minimap button if saved setting is hidden
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
                    print("|cffFF0000[GuildNotesUpdater]|r Minimap button hidden. Type |cffffff00/gnotes minimap|r to show it again.")
                else
                    LDBIcon:Show("GuildNotesUpdater")
                    print("|cff00ff00[GuildNotesUpdater]|r Minimap button shown.")
                end
            else
                OpenSettingsWindow()
            end
        end
    end
end)
