-- Page under Options > AddOns > Dungeon Journal: a short landing page (big
-- title, version, how to reach the options) with a red "Open Options" button
-- that opens the journal's own options panel, like other addons do.
local _, SM = ...
SM.DJ = SM.DJ or {}
local SMJ = SM.DJ

local function L(key, ...)
    if SMJ and SMJ.L then return SMJ.L(key, ...) end
    return key
end

local function Version()
    local getter = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if getter then
        local ok, version = pcall(getter, "SentinelMentorJournal", "Version")
        if ok and version then return tostring(version) end
    end
    return ""
end

local panel = CreateFrame("Frame", "SentinelMentorJournalOptionsPanel")
panel.name = "Dungeon Journal"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
title:SetPoint("CENTER", panel, "CENTER", 22, 120)
do
    local font, _, flags = title:GetFont()
    if font then title:SetFont(font, 64, flags) end
end
title:SetText("Dungeon Journal")
title:SetTextColor(1.00, 0.82, 0.00)

local icon = panel:CreateTexture(nil, "ARTWORK")
icon:SetSize(60, 60)
icon:SetPoint("RIGHT", title, "LEFT", -14, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
version:SetPoint("TOP", title, "BOTTOM", -22, -26)

local access = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
access:SetPoint("TOP", version, "BOTTOM", 0, -14)

local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
open:SetSize(300, 44)
open:SetPoint("TOP", access, "BOTTOM", 0, -30)
open:SetNormalFontObject("GameFontNormalHuge")
open:SetHighlightFontObject("GameFontHighlightHuge")
open:SetScript("OnClick", function()
    if SMJ and SMJ.ToggleSettingsPanel then
        local p = _G.SentinelMentorJournalSettings
        if not (p and p:IsShown()) then SMJ.ToggleSettingsPanel() end
    end
end)

-- The page is already "shown" when the game first displays it, so OnShow
-- alone left it blank the first time: fill it in right away and at login too.
local function Refresh()
    version:SetText(L("OPT_VERSION", Version()))
    access:SetText(L("OPT_ACCESS", "/smj options"))
    open:SetText(L("OPT_OPEN_OPTIONS"))
end
Refresh()
panel:SetScript("OnShow", Refresh)
panel:RegisterEvent("PLAYER_LOGIN")
panel:SetScript("OnEvent", Refresh)

local function RegisterPanel()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Dungeon Journal")
        category.ID = "DungeonJournal"
        Settings.RegisterAddOnCategory(category)
        SMJ.OptionsCategory = category
        return
    end
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

RegisterPanel()
