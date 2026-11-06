local _, SentinelMentor = ...
local classFrame = CreateFrame("Frame", "SentinelMentorFrame", UIParent)
classFrame:SetSize(420, 480)
classFrame:SetPoint("CENTER")
classFrame:SetFrameStrata("HIGH")
classFrame:SetFrameLevel(500)
classFrame:Hide()
SentinelMentor.ClassFrame = classFrame

SentinelMentor.RowSpacing = 0.5
SentinelMentor.HeaderExtraGap = 12
SentinelMentor.MinRowHeight, SentinelMentor.MaxRowHeight = 10, 64
local MAX_ICON_SIZE = 64
local COLLAPSE_BUTTON_SIZE = 16
local COLLAPSED_UP = "Interface\\Buttons\\UI-PlusButton-Up"
local COLLAPSED_DOWN = "Interface\\Buttons\\UI-PlusButton-Down"
local EXPANDED_UP = "Interface\\Buttons\\UI-MinusButton-Up"
local EXPANDED_DOWN = "Interface\\Buttons\\UI-MinusButton-Down"
local COLLAPSE_HIGHLIGHT = "Interface\\Buttons\\UI-PlusButton-Hilight"
SentinelMentor.HeaderHeight = 24
SentinelMentor.RowHeight = 32
SentinelMentor.UIColors = {
    AVAILABLE = "|cff4dd97a",
    SOON = "|cff339eff",
    NOTYET = "|cfff0535c",
    TALENT = "|cffebad33",
    KNOWN = "|cff8c92a4",
    IGNORED = "|cff666e7e",
    PET_HEADER = "|cff9d7bff",
    SPELL_NAME = "|cffebeef2",
    DIM_NAME = "|cff8c92a4",
    RANK = "|cff8c92a4",
}

SentinelMentor.PetGroups = {
    {
        label = SentinelMentor:GetPetNameById(688),
        keys = {"Imp"}
    },
    {
        label = SentinelMentor:GetPetNameById(697),
        keys = {"Voidwalker"}
    },
    {
        label = SentinelMentor:GetPetNameById(712),
        keys = {"Succubus", "Incubus"}
    },
    {
        label = SentinelMentor:GetPetNameById(691),
        keys = {"Felhunter"}
    },
    {
        label = SentinelMentor:GetPetNameById(30146),
        keys = {"Felguard"}
    },
}

function SentinelMentor:IsDragonflightUIEnabled()
    return SentinelMentor:IsAddonLoaded("DragonflightUI")
end

function SentinelMentor:IsLeatrixWideProfessionEnabled()
    return SentinelMentor:IsAddonLoaded("Leatrix_Plus") and LeaPlusDB and LeaPlusDB["EnhanceProfessions"] == "On"
end

function SentinelMentor:FlowControls(frame, available, minRowHeight)
    available = available or frame:GetWidth()
    if not available or available <= 0 then return end
    local regions = {frame:GetRegions()}
    local x, y, rowHeight, row = 0, 0, minRowHeight or 0, {}
    local function PlaceRow()
        for _, entry in ipairs(row) do
            entry[1]:ClearAllPoints()
            entry[1]:SetPoint("LEFT", frame, "TOPLEFT", entry[2], -(y + rowHeight / 2))
        end
    end
    for _, child in ipairs(frame.flowOrder or {frame:GetChildren()}) do
        if child:IsShown() then
            local childWidth = math.min(child:GetWidth(), available)
            local extent = childWidth
            for _, region in ipairs(regions) do
                if region.GetStringWidth and region:IsShown() and region:GetNumPoints() > 0 then
                    local _, relative, _, offset = region:GetPoint(1)
                    if relative == child then extent = math.max(extent, childWidth + (offset or 0) + region:GetStringWidth()) end
                end
            end
            if x > 0 and x + extent > available then
                PlaceRow()
                x, y, rowHeight, row = 0, y + rowHeight + 4, minRowHeight or 0, {}
            end
            child:SetWidth(childWidth)
            table.insert(row, {child, x})
            rowHeight = math.max(rowHeight, child:GetHeight())
            x = x + extent + 8
        end
    end
    PlaceRow()
    local height = y + rowHeight
    frame:SetHeight(math.max(1, height))
    return height
end

function SentinelMentor:AddContentBorder(frame, owner)
    owner = owner or frame
    local M = SentinelMentor.Style
    frame.contentBackground = owner:CreateTexture(nil, "BACKGROUND", nil, -8)
    M:ApplyBookBackground(frame.contentBackground)
    frame.contentBackground:SetAllPoints(frame)
    frame.borderFrame = CreateFrame("Frame", nil, owner, "BackdropTemplate")
    frame.borderFrame:SetAllPoints(frame)
    frame.borderFrame:SetBackdrop({edgeFile = M.tex.blank, edgeSize = 1})
    frame.borderFrame:SetBackdropBorderColor(M.colors.border.r, M.colors.border.g, M.colors.border.b, 1)
    M:AccentEdge(frame.borderFrame, "TOP")
end

function SentinelMentor:IsGroupCollapsed(groupKey)
    return groupKey and SentinelMentor_Character and SentinelMentor_Character.collapsedGroups[groupKey] or false
end

local function ToggleGroup(groupKey)
    if not groupKey or not SentinelMentor_Character then return end
    SentinelMentor_Character.collapsedGroups[groupKey] = not SentinelMentor_Character.collapsedGroups[groupKey] or nil
    if SentinelMentor_Refresh then SentinelMentor_Refresh() end
    if SentinelMentor_ProfessionRefresh then SentinelMentor_ProfessionRefresh() end
end

local function GetRowHitButton(rowFrame)
    local hit = rowFrame.hitButton
    if not hit then
        hit = SentinelMentor.CreateDetachedFrame("Button", rowFrame)
        hit.smRow = rowFrame
        local highlight = hit:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture(SentinelMentor.Style.tex.blank)
    highlight:SetVertexColor(1, 1, 1, 0.06)
        highlight:SetBlendMode("ADD")
        highlight:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, 0)
        highlight:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
        hit:SetHighlightTexture(highlight)
        hit:Hide()
        rowFrame.hitButton = hit
    end
    return hit
end

local function GetRowCollapseButton(rowFrame)
    local button = rowFrame.collapseButton
    if not button then
        button = SentinelMentor.CreateDetachedFrame("Button", rowFrame)
        button:SetSize(COLLAPSE_BUTTON_SIZE, COLLAPSE_BUTTON_SIZE)
        button:SetHighlightTexture(COLLAPSE_HIGHLIGHT, "ADD")
        button:Hide()
        rowFrame.collapseButton = button
    end
    return button
end

local function GetRowLocationButton(rowFrame, index)
    rowFrame.locationButtons = rowFrame.locationButtons or {}
    for i = #rowFrame.locationButtons + 1, index do
        local button = SentinelMentor.CreateDetachedFrame("Button", rowFrame)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button.smRow = rowFrame
        button:Hide()
        rowFrame.locationButtons[i] = button
    end
    return rowFrame.locationButtons[index]
end

local function UpdateCollapseButton(rowFrame, elementData, anchor)
    if not elementData.groupKey then
        if rowFrame.collapseButton then rowFrame.collapseButton:Hide() end
        return nil
    end

    local button = GetRowCollapseButton(rowFrame)
    button:ClearAllPoints()
    button:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
    local atlas = elementData.collapsed and "common-button-list-plus" or "common-button-list-minus"
    local pushedAtlas = atlas
    if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)) then
        atlas = elementData.collapsed and "ui-questtrackerbutton-secondary-expand" or "ui-questtrackerbutton-secondary-collapse"
        pushedAtlas = atlas .. "-pressed"
    end
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) and button.SetNormalAtlas then
        button:SetNormalAtlas(atlas)
        button:SetPushedAtlas(pushedAtlas)
        button:SetHighlightAtlas(atlas, "ADD")
        button:GetHighlightTexture():SetAlpha(0.4)
        local info = C_Texture.GetAtlasInfo(atlas)
        local scale = (COLLAPSE_BUTTON_SIZE - 3) / math.max(info.width or 1, info.height or 1, 1)
        for _, texture in ipairs({button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture()}) do
            texture:ClearAllPoints()
            texture:SetPoint("CENTER")
            texture:SetSize((info.width or 1) * scale, (info.height or 1) * scale)
        end
    else
        button:SetNormalTexture(elementData.collapsed and COLLAPSED_UP or EXPANDED_UP)
        button:SetPushedTexture(elementData.collapsed and COLLAPSED_DOWN or EXPANDED_DOWN)
        button:SetHighlightTexture(COLLAPSE_HIGHLIGHT, "ADD")
        button:GetHighlightTexture():SetAlpha(1)
    end
    button:SetScript("OnClick", function() ToggleGroup(elementData.groupKey) end)
    button:Show()
    return button
end

local function GetLevelDiffColorCode(level)
    if GetQuestDifficultyColor then
        local r, g, b = GetQuestDifficultyColor(level)
        if type(r) == "table" then r, g, b = r.r, r.g, r.b end
        if r then return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255) end
    end
    return SentinelMentor.UIColors.RANK
end

local function SetFontSize(fontString, size)
    fontString:SetFont(SentinelMentor.Style.font.normal, size, "OUTLINE")
end

local function AddModernTalent(configID, entryID, isLearned, names, learned)
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo or not entryInfo.definitionID then return end
    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    if not definitionInfo then return end
    local talentName = definitionInfo.overrideName or SentinelMentor:GetSpellInfo(definitionInfo.spellID)
    if not talentName then return end
    names[talentName] = true
    if isLearned then learned[talentName] = true end
end

local function ReadModernTalentNode(configID, nodeID, names, learned)
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo then return end
    local committedEntries = {}
    for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks or {}) do
        committedEntries[entryID] = true
    end

    for _, entryID in ipairs(nodeInfo.entryIDs or {}) do
        AddModernTalent(configID, entryID, committedEntries[entryID], names, learned)
    end
end

local function GetModernTalentNameSet()
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID or not C_Traits or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes or not C_Traits.GetNodeInfo or not C_Traits.GetEntryInfo or not C_Traits.GetDefinitionInfo then return end
    local configID = C_ClassTalents.GetActiveConfigID()
    local configInfo = configID and C_Traits.GetConfigInfo(configID)
    if not configInfo then return end
    local names, learned = {}, {}
    for _, treeID in ipairs(configInfo.treeIDs or {}) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
            ReadModernTalentNode(configID, nodeID, names, learned)
        end
    end
    if next(names) then return names, learned end
end

function SentinelMentor:GetTalentNameSet()
    local names, learned = GetModernTalentNameSet()
    if names then return names, learned end
    names, learned = {}, {}

    if GetNumTalentTabs and GetNumTalents and GetTalentInfo then
        for tab = 1, GetNumTalentTabs() do
            for i = 1, GetNumTalents(tab) do
                local talentName, _, _, _, rank = GetTalentInfo(tab, i)
                if talentName then
                    names[talentName] = true
                    if (rank or 0) > 0 then learned[talentName] = true end
                end
            end
        end
    end
    return names, learned
end

function SentinelMentor:GetPlayerFaction()
    return UnitFactionGroup and UnitFactionGroup("player")
end

function SentinelMentor:GetPlayerRace()
    if not UnitRace then return nil end
    local _, englishRace = UnitRace("player")
    return englishRace
end

local function IsReqSpellKnown(spellID)
    if not IsPlayerSpell or type(spellID) ~= "number" then return false end
    local ok, known = pcall(IsPlayerSpell, spellID)
    return ok and known or false
end

function SentinelMentor:RequiresUnknownTalent(entry, talentNames, learnedTalents)
    if not entry.requires then return false end
    for _, reqSpellID in ipairs(entry.requires) do
        local reqName = SentinelMentor:GetSpellInfo(reqSpellID)
        if reqName and talentNames[reqName] and not learnedTalents[reqName] and not IsReqSpellKnown(reqSpellID) then return true end
    end
    return false
end

local function FormatCost(copper)
    if not copper or copper == 0 then return "kostenlos" end
    return GetMoneyString(copper, true)
end

local function GetCostColumnWidth(fontString, column, fontSize)
    local width = column.widths[fontSize]
    if width then return width end
    width = 0
    for _, cost in ipairs(column.costs) do
        fontString:SetText(type(cost) == "string" and cost or GetMoneyString(cost, true))
        width = math.max(width, fontString:GetStringWidth())
    end

    width = math.ceil(width)
    column.widths[fontSize] = width
    return width
end

local function FitRowLevel(rowFrame)
    local full, short = rowFrame.levelFull, rowFrame.levelShort
    if not full then return end
    local levelFS, nameFS, costFS = rowFrame.levelFS, rowFrame.nameFS, rowFrame.costFS
    levelFS:SetText(full)
    if not short then return end
    local available = (rowFrame:GetWidth() or 0) - rowFrame.levelNameLeft - 8
    if costFS:IsShown() then available = available - costFS:GetWidth() - 12 end
    if nameFS:GetUnboundedStringWidth() + levelFS:GetUnboundedStringWidth() > available then levelFS:SetText(short) end
end

local function GetLocalizedRankText(spellID, rankNum, hasRealRank)
    local subtext = GetSpellSubtext and spellID and GetSpellSubtext(spellID)
    if subtext and subtext ~= "" then return subtext end
    if hasRealRank and rankNum then return (_G.RANK or "Rank") .. " " .. rankNum end
    return nil
end

local function GetLocalizedPassiveText(spellID)
    if not spellID then return nil end
    local passive
    if C_Spell and C_Spell.IsSpellPassive then
        passive = C_Spell.IsSpellPassive(spellID)
    elseif IsSpellPassive then
        passive = IsSpellPassive(spellID)
    elseif IsPassiveSpell then
        passive = IsPassiveSpell(spellID)
    end
    if not passive then return nil end
    return _G.SPELL_PASSIVE or _G.PASSIVE or "Passive"
end

function SentinelMentor:EntryMatchesSearch(entry, search)
    if not search or search == "" then return true end
    if entry.name and entry.name:lower():find(search, 1, true) then return true end
    if entry.level and tostring(entry.level):find(search, 1, true) then return true end
    if entry.levelReq and tostring(entry.levelReq):find(search, 1, true) then return true end
    if entry.source and entry.source:lower():find(search, 1, true) then return true end
    for _, location in ipairs(entry.sourceLocations or {}) do
        if location.npcName and location.npcName:lower():find(search, 1, true) then return true end
        if location.questName and location.questName:lower():find(search, 1, true) then return true end
        if location.zoneName and location.zoneName:lower():find(search, 1, true) then return true end
    end
    return false
end

function SentinelMentor:SortEntries(list)
    table.sort(list, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.key < b.key
    end)
end

function SentinelMentor:OpenWorldMapAt(uiMapID)
    if not WorldMapFrame then return end
    if WorldMapFrame.HandleUserActionOpenSelf then
        if C_Map.OpenWorldMap then
            C_Map.OpenWorldMap(uiMapID)
        elseif OpenWorldMap then
            OpenWorldMap(uiMapID)
        end
        return
    end
    if not WorldMapFrame:IsShown() then
        if ToggleWorldMap then ToggleWorldMap() elseif ShowUIPanel then ShowUIPanel(WorldMapFrame) else WorldMapFrame:Show() end
    end
    if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(uiMapID) end
end

function SentinelMentor:SetMapWaypoint(location)
    if not location or not location.uiMapID or not location.x or not location.y then return false end
    if SentinelMentor:HasWaypointSupport() and SentinelMentor:SetTrackedWaypoint(location.uiMapID, location.x / 100, location.y / 100) then
        if not (InCombatLockdown and InCombatLockdown()) then SentinelMentor:OpenWorldMapAt(location.uiMapID) end
        return true
    end

    if TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(location.uiMapID, location.x / 100, location.y / 100, {
            title = location.questName or location.npcName or location.name,
            persistent = false,
            minimap = true,
            world = true,
            crazy = true,
        })
        return true
    end

    return false
end

SentinelMentor:EnableWaypointFallback(function() return SentinelMentor_Character end)
local ignoreMenuFrame
local ignoreMenuEntry
local function IgnoreMenu_Initialize(sel, level, rootDescription, entry)
    entry = entry or ignoreMenuEntry
    if not entry then return end
    local function CreateInfo()
        return rootDescription and {} or UIDropDownMenu_CreateInfo()
    end

    local function AddButton(info)
        if rootDescription then
            if info.isTitle then
                rootDescription:CreateTitle(info.text)
            else
                rootDescription:CreateButton(info.text, info.func)
            end
        else
            UIDropDownMenu_AddButton(info, level)
        end
    end

    local professionKey = entry.professionKey
    local isProfessionSpell = professionKey ~= nil

    local rankSubtext = GetLocalizedRankText(entry.spellID, entry.rankNum, entry.hasRealRank)
    local rankText = rankSubtext and (" " .. rankSubtext) or ""
    local info = CreateInfo()
    info.text = entry.name .. rankText
    info.isTitle = true
    info.notCheckable = true
    AddButton(info)
    if isProfessionSpell then
        local spellIgnored = SentinelMentor_IsProfessionSpellIgnored and SentinelMentor_IsProfessionSpellIgnored(entry.spellID, professionKey)
        info = CreateInfo()
        local isRecipeView = entry.isProfessionRecipe
        if isRecipeView then
            info.text = spellIgnored and SentinelMentor:Trans("LID_STOPIGNORINGTHISRECIPE") or SentinelMentor:Trans("LID_IGNORINGTHISRECIPE")
        else
            info.text = spellIgnored and SentinelMentor:Trans("LID_STOPIGNORINGTHISSKILL") or SentinelMentor:Trans("LID_IGNORINGTHISSKILL")
        end

        info.notCheckable = true
        info.func = function()
            SentinelMentor_ToggleIgnoreProfessionSpell(entry.spellID, professionKey)
            SentinelMentor_ProfessionRefresh()
        end

        AddButton(info)
    else
        local spellIgnored = SentinelMentor_IsSpellIgnored and SentinelMentor_IsSpellIgnored(entry.spellID)
        local nameIgnored = SentinelMentor_IsNameIgnored and SentinelMentor_IsNameIgnored(entry.name)
        info = CreateInfo()
        info.text = spellIgnored and SentinelMentor:Trans("LID_STOPIGNORINGTHISRANK") or SentinelMentor:Trans("LID_IGNORINGTHISRANK")
        info.notCheckable = true
        info.func = function()
            SentinelMentor_ToggleIgnoreSpell(entry.spellID)
            SentinelMentor_Refresh()
        end

        AddButton(info)
        info = CreateInfo()
        info.text = nameIgnored and SentinelMentor:Trans("LID_STOPIGNOREINGALLRANKS") or SentinelMentor:Trans("LID_IGNOREALLRANKS")
        info.notCheckable = true
        info.func = function()
            SentinelMentor_ToggleIgnoreName(entry.name)
            SentinelMentor_Refresh()
        end

        AddButton(info)
    end

    info = CreateInfo()
    info.text = SentinelMentor:Trans("LID_CANCEL")
    info.notCheckable = true
    AddButton(info)
end

if not (MenuUtil and MenuUtil.CreateContextMenu) then
    ignoreMenuFrame = CreateFrame("Frame", "SentinelMentorIgnoreMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(ignoreMenuFrame, IgnoreMenu_Initialize, "MENU")
end
function SentinelMentor:ShowIgnoreMenu(anchor, entry)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchor, function(owner, rootDescription)
            IgnoreMenu_Initialize(owner, nil, rootDescription, entry)
        end)
        return
    end

    ignoreMenuEntry = entry
    ToggleDropDownMenu(1, nil, ignoreMenuFrame, "cursor", 0, 0)
    if DropDownList1 then
        DropDownList1:SetFrameStrata("TOOLTIP")
        DropDownList1:SetFrameLevel(600)
    end
end

local pendingSpellTooltipExtra
local function AddSpellTooltipExtra(tooltip, spellID)
    local extra = pendingSpellTooltipExtra
    if not extra or tooltip ~= GameTooltip then return false end
    if SentinelMentor:IsSecret(spellID) then return false end
    if spellID ~= extra.spellID then return false end
    if extra.showCost then
        local canAfford = not extra.cost or extra.cost == 0 or (GetMoney() or 0) >= extra.cost
        local costColor = canAfford and "|cffffffff" or "|cffff3333"
        if not extra.priceEntry or extra.priceEntry.baseCost == nil then tooltip:AddLine(SentinelMentor:Trans("LID_COSTS") .. ": " .. costColor .. FormatCost(extra.cost) .. "|r", 1, 1, 1) end
        if extra.priceEntry then SentinelMentor.Pricing.AddTooltip(tooltip, extra.priceEntry) end
        tooltip:AddLine(SentinelMentor:Trans("LID_OWNGOLD") .. ": " .. GetMoneyString(GetMoney() or 0, true), 1, 1, 1)
    end

    if extra.source then tooltip:AddLine(SentinelMentor:Trans("LID_SOURCE") .. ": " .. extra.source, 0.9, 0.9, 0.9, true) end
    return true
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, tooltipData)
        if not pendingSpellTooltipExtra then return end
        AddSpellTooltipExtra(tooltip, tooltipData and tooltipData.id or SentinelMentor:GetTooltipSpellID(tooltip))
    end)
elseif GameTooltip:HasScript("OnTooltipSetSpell") then
    GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip)
        if AddSpellTooltipExtra(tooltip, SentinelMentor:GetTooltipSpellID(tooltip)) then tooltip:Show() end
    end)
end
function SentinelMentor.CreateDetachedFrame(frameType, parent, template)
    local frame = CreateFrame(frameType, nil, nil, template)
    frame:SetParent(parent)
    return frame
end

function SentinelMentor.RunDetached(frame, func)
    local parent = frame:GetParent()
    if not parent or parent == UIParent or frame.compendiumHost then
        func()
        return
    end

    local strata, level = frame:GetFrameStrata(), frame:GetFrameLevel()
    frame:SetParent(UIParent)
    func()
    frame:SetParent(parent)
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(level)
end

function SentinelMentor.SmartNavClick(frame)
    if frame:IsObjectType("EditBox") then
        frame:SetFocus()
        return
    end

    local onMouseDown = frame:GetScript("OnMouseDown")
    if onMouseDown then onMouseDown(frame, "LeftButton") end
    if frame:IsObjectType("Button") and frame:GetScript("OnClick") then
        frame:Click("LeftButton")
    else
        local onMouseUp = frame:GetScript("OnMouseUp")
        if onMouseUp then onMouseUp(frame, "LeftButton") end
    end
end

function SentinelMentor.IsGamepadNavActive()
    return SmartNavigation ~= nil and SmartNavigation.enabled == true
end

function SentinelMentor:PrepareGamepadNavigation(root, gamepad)
    if gamepad == nil then gamepad = SentinelMentor.IsGamepadNavActive() end
    if root:IsObjectType("Button") or root:IsObjectType("EditBox") or root:GetScript("OnMouseUp") or root:GetScript("OnMouseDown") then root.smGamepadClick = true end
    local onEnter, onLeave = root:GetScript("OnEnter"), root:GetScript("OnLeave")
    if gamepad then
        if onEnter or onLeave then
            root.smOnEnter, root.smOnLeave, root.smFocusStripped = onEnter, onLeave, true
            root:SetScript("OnEnter", nil)
            root:SetScript("OnLeave", nil)
        end
    elseif root.smFocusStripped and not onEnter and not onLeave then
        root:SetScript("OnEnter", root.smOnEnter)
        root:SetScript("OnLeave", root.smOnLeave)
        root.smFocusStripped = nil
    end

    for _, child in ipairs({root:GetChildren()}) do
        self:PrepareGamepadNavigation(child, gamepad)
    end
end

SentinelMentor.GamepadRowTargetWidth = 24
SentinelMentor.GamepadRowInset = 10
function SentinelMentor:ApplyRowInteraction(rowFrame)
    local gamepad = SentinelMentor.IsGamepadNavActive()
    local onEnter, onLeave, onMouseUp = rowFrame:GetScript("OnEnter"), rowFrame:GetScript("OnLeave"), rowFrame:GetScript("OnMouseUp")
    rowFrame:SetScript("OnEnter", nil)
    rowFrame:SetScript("OnLeave", nil)
    rowFrame:SetScript("OnMouseUp", nil)
    rowFrame:EnableMouse(false)
    rowFrame.smStandIns = rowFrame.smStandIns or {}
    for _, standIn in pairs(rowFrame.smStandIns) do
        standIn:Hide()
    end

    local locationClick
    if gamepad then
        for _, button in ipairs(rowFrame.locationButtons or {}) do
            if button:IsShown() then locationClick = locationClick or button:GetScript("OnClick") end
        end

        local button = rowFrame.collapseButton
        if button and button:IsShown() then
            local source = button:GetNormalTexture()
            local standIn = rowFrame.smStandIns[button]
            if not standIn then
                standIn = rowFrame:CreateTexture(nil, "OVERLAY")
                standIn:SetAllPoints(button)
                rowFrame.smStandIns[button] = standIn
            end

            standIn:SetTexture(source and source:GetTexture())
            if source then standIn:SetTexCoord(source:GetTexCoord()) end
            standIn:Show()
            button:Hide()
        end

        if rowFrame.icon:IsShown() then
            local point, relativeTo, relativePoint, x, y = rowFrame.icon:GetPoint(1)
            if point then rowFrame.icon:SetPoint(point, relativeTo, relativePoint, x + SentinelMentor.GamepadRowInset, y) end
        end
    end

    if not (onEnter or onMouseUp or locationClick) then
        if rowFrame.hitButton then rowFrame.hitButton:Hide() end
        return
    end

    local hit = GetRowHitButton(rowFrame)
    hit:SetFrameLevel(rowFrame:GetFrameLevel())
    hit:ClearAllPoints()
    hit:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, 0)
    hit:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 0, 0)
    if gamepad then
        hit:SetWidth(SentinelMentor.GamepadRowTargetWidth)
    else
        hit:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", 0, 0)
        hit:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    end

    hit:GetHighlightTexture():SetAlpha(gamepad and 1 or 0)
    hit.smFocusStripped, hit.smOnEnter, hit.smOnLeave = nil, nil, nil
    hit:SetScript("OnEnter", onEnter and function() onEnter(rowFrame) end or nil)
    hit:SetScript("OnLeave", onLeave and function() onLeave(rowFrame) end or nil)
    hit:SetScript("OnMouseUp", function(_, button)
        if onMouseUp then onMouseUp(rowFrame, button) end
        if locationClick and button == "LeftButton" then locationClick() end
    end)

    hit:EnableMouse(true)
    hit:Show()
end

local function IsCardableEntry(elementData)
    return elementData and elementData.entry ~= nil and not elementData.isHeader and not elementData.initRow and not elementData.isClassTrainer and not elementData.isNearestTrainer and not elementData.isWeaponSkill
end

function SentinelMentor:CompactItems(items)
    local out, pending = {}, nil
    local function flush()
        if pending then
            table.insert(out, pending)
            pending = nil
        end
    end
    for _, elementData in ipairs(items) do
        if IsCardableEntry(elementData) then
            if pending and #pending.spells < 2 then
                table.insert(pending.spells, elementData)
            else
                flush()
                pending = {isCardRow = true, spells = {elementData}, rowDepth = elementData.rowDepth or 0}
            end
        else
            flush()
            table.insert(out, elementData)
        end
    end
    flush()
    return out
end

function SentinelMentor:ApplyRowStripe(rowFrame, elementData)
    if not rowFrame.smStripe then
        rowFrame.smStripe = rowFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    end

    local index = rowFrame.GetElementDataIndex and rowFrame:GetElementDataIndex()
    if elementData.isHeader or not index then
        rowFrame.smStripe:Hide()
        return
    end

    rowFrame.smStripe:ClearAllPoints()
    rowFrame.smStripe:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", (elementData.rowDepth or 0) * 16, 0)
    rowFrame.smStripe:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)

    rowFrame.smStripe:SetColorTexture(1, 1, 1, index % 2 == 1 and 0.03 or 0.06)
    rowFrame.smStripe:Show()
end

function SentinelMentor:InitScrollRow(rowFrame, elementData, rowHeight)
    rowFrame.smFocusStripped, rowFrame.smOnEnter, rowFrame.smOnLeave = nil, nil, nil
    local Colors = SentinelMentor.UIColors
    if not rowFrame.icon then
        local categoryBackground = SentinelMentor.CreateDetachedFrame("Frame", rowFrame, "BackdropTemplate")
        categoryBackground:SetAllPoints()
        categoryBackground:SetFrameLevel(math.max(0, rowFrame:GetFrameLevel() - 1))
        categoryBackground:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = {
                left = 2,
                right = 2,
                top = 2,
                bottom = 2
            }
        })

        local smc = SentinelMentor.Style.colors
        categoryBackground:SetBackdropColor(smc.bgInset.r, smc.bgInset.g, smc.bgInset.b, 0.95)
        categoryBackground:SetBackdropBorderColor(smc.border.r, smc.border.g, smc.border.b, 1)
        categoryBackground:EnableMouse(false)
        categoryBackground:Hide()
        local accentBar = categoryBackground:CreateTexture(nil, "OVERLAY")
        accentBar:SetPoint("TOPLEFT", categoryBackground, "TOPLEFT", 0, -1)
        accentBar:SetPoint("BOTTOMLEFT", categoryBackground, "BOTTOMLEFT", 0, 1)
        accentBar:SetWidth(2)
        accentBar:SetTexture(SentinelMentor.Style.tex.blank)
        accentBar:SetVertexColor(smc.accent.r, smc.accent.g, smc.accent.b, 0.9)
        rowFrame.categoryBackground = categoryBackground
        GetRowHitButton(rowFrame)
        GetRowCollapseButton(rowFrame)
        GetRowLocationButton(rowFrame, 3)
        local icon = rowFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        rowFrame.icon = icon
        local nameFS = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameFS:SetJustifyH("LEFT")
        nameFS:SetWordWrap(false)
        rowFrame.nameFS = nameFS
        local levelFS = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        levelFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        levelFS:SetJustifyH("RIGHT")
        rowFrame.levelFS = levelFS
        local countFS = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countFS:SetJustifyH("CENTER")
        countFS:SetWordWrap(false)
        rowFrame.countFS = countFS
        local costFS = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        costFS:SetJustifyH("RIGHT")
        costFS:SetWordWrap(false)
        rowFrame.costFS = costFS
        local sourceFS = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sourceFS:SetJustifyH("RIGHT")
        sourceFS:SetWordWrap(false)
        rowFrame.sourceFS = sourceFS
        rowFrame:HookScript("OnSizeChanged", FitRowLevel)
    end

    local icon, nameFS, levelFS = rowFrame.icon, rowFrame.nameFS, rowFrame.levelFS
    local countFS, costFS, sourceFS = rowFrame.countFS, rowFrame.costFS, rowFrame.sourceFS
    local iconSize = math.max(8, math.min(MAX_ICON_SIZE, (rowFrame:GetHeight() or SentinelMentor.RowHeight) - 4))
    local fontSize = math.max(8, math.min(14, (rowHeight or SentinelMentor.RowHeight) - 4))
    SetFontSize(nameFS, fontSize)
    SetFontSize(levelFS, fontSize)
    icon:SetSize(iconSize, iconSize)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
    rowFrame:EnableMouse(false)
    rowFrame:SetScript("OnEnter", nil)
    rowFrame:SetScript("OnLeave", nil)
    rowFrame:SetScript("OnMouseUp", nil)
    if rowFrame.collapseButton then rowFrame.collapseButton:Hide() end
    if rowFrame.locationButtons then
        for _, button in ipairs(rowFrame.locationButtons) do
            button:Hide()
        end
    end
    if rowFrame.cards then
        for _, card in ipairs(rowFrame.cards) do
            card:Hide()
        end
    end

    rowFrame.categoryBackground:Hide()
    icon:Show()
    icon:SetTexture(nil)
    nameFS:ClearAllPoints()
    nameFS:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    nameFS:SetPoint("RIGHT", levelFS, "LEFT", -4, 0)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetText("")
    levelFS:ClearAllPoints()
    levelFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    levelFS:SetText("")
    rowFrame.levelFull, rowFrame.levelShort = nil, nil
    countFS:Hide()
    countFS:SetText("")
    costFS:Hide()
    costFS:SetWidth(0)
    costFS:SetText("")
    sourceFS:Hide()
    sourceFS:SetText("")
    if elementData.isHeader then
        local categoryInset = math.max(0, ((rowFrame:GetHeight() or SentinelMentor.HeaderHeight) - SentinelMentor.HeaderHeight) / 2)
        rowFrame.categoryBackground:ClearAllPoints()
        rowFrame.categoryBackground:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", (elementData.headerDepth or 0) * 16, -categoryInset)
        rowFrame.categoryBackground:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, categoryInset)
        rowFrame.categoryBackground:Show()
        icon:Hide()
        SetFontSize(nameFS, fontSize)
        local textInset = elementData.groupKey and (COLLAPSE_BUTTON_SIZE + 6) or 4
        local rightAnchor, rightPoint, rightGap = rowFrame.categoryBackground, "RIGHT", -4
        if elementData.totalCost ~= nil then
            local canAfford = elementData.totalCost == 0 or (GetMoney() or 0) >= elementData.totalCost
            local costColor = canAfford and "|cffffffff" or "|cffff3333"
            SetFontSize(costFS, fontSize)
            costFS:ClearAllPoints()
            costFS:SetPoint("RIGHT", rowFrame.categoryBackground, "RIGHT", -4, 0)
            costFS:SetText(costColor .. SentinelMentor.Pricing.Text(elementData.baseCost, elementData.totalCost, elementData.baseCostEstimated, costColor) .. "|r")
            costFS:SetWidth(math.ceil(costFS:GetUnboundedStringWidth()) + 2)
            costFS:Show()
            rightAnchor, rightPoint, rightGap = costFS, "LEFT", -12
        end

        if elementData.spellCount then
            local singular = elementData.countKind == "skill" and (_G.SKILL or "Skill") or (_G.SPELL or "Spell")
            local plural = elementData.countKind == "skill" and (_G.SKILLS or "Skills") or (_G.SPELLS or "Spells")
            local countLabel = elementData.spellCount == 1 and singular or plural
            SetFontSize(countFS, fontSize)
            countFS:ClearAllPoints()
            countFS:SetPoint("RIGHT", rightAnchor, rightPoint, rightGap, 0)
            countFS:SetText(elementData.color .. elementData.spellCount .. " " .. countLabel .. "|r")
            countFS:SetWidth(math.ceil(countFS:GetUnboundedStringWidth()) + 2)
            countFS:Show()
            rightAnchor, rightPoint, rightGap = countFS, "LEFT", -10
        end

        nameFS:ClearAllPoints()
        nameFS:SetPoint("TOPLEFT", rowFrame.categoryBackground, "TOPLEFT", textInset, 0)
        nameFS:SetPoint("BOTTOMLEFT", rowFrame.categoryBackground, "BOTTOMLEFT", textInset, 0)
        nameFS:SetPoint("RIGHT", rightAnchor, rightPoint, rightGap, 0)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetJustifyV("MIDDLE")
        UpdateCollapseButton(rowFrame, elementData, nameFS)
        local prefix = elementData.prefixText and (Colors.PET_HEADER .. "[" .. elementData.prefixText .. "] |r") or ""
        nameFS:SetText(prefix .. elementData.color .. elementData.text .. "|r")

        if elementData.totalCost or elementData.groupKey then
            rowFrame:EnableMouse(true)
            rowFrame:SetScript("OnEnter", function(sel)
                if not elementData.totalCost then return end
                GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
                GameTooltip:AddLine(elementData.text)
                local canAfford = elementData.totalCost == 0 or (GetMoney() or 0) >= elementData.totalCost
                local costColor = canAfford and "|cffffffff" or "|cffff3333"
                if elementData.baseCost == nil then GameTooltip:AddLine(SentinelMentor:Trans("LID_TOTALCOST") .. ": " .. costColor .. FormatCost(elementData.totalCost) .. "|r", 1, 1, 1) end
                SentinelMentor.Pricing.AddTooltip(GameTooltip, {cost = elementData.totalCost, baseCost = elementData.baseCost, baseCostEstimated = elementData.baseCostEstimated, priceFaction = elementData.priceFaction, priceDiscount = elementData.priceDiscount, priceEligible = elementData.priceEligible})
                GameTooltip:AddLine(SentinelMentor:Trans("LID_OWNGOLD") .. ": " .. GetMoneyString(GetMoney() or 0, true), 1, 1, 1)
                GameTooltip:Show()
            end)

            rowFrame:SetScript("OnLeave", GameTooltip_Hide)
            rowFrame:SetScript("OnMouseUp", function(sel, button) if button == "LeftButton" and elementData.groupKey then ToggleGroup(elementData.groupKey) end end)
        end
    elseif elementData.initRow then
        elementData.initRow(rowFrame, elementData, icon, nameFS, levelFS)
    elseif elementData.isClassTrainer then
        local entry = elementData.entry
        if elementData.rowDepth and elementData.rowDepth > 0 then
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", rowFrame, "LEFT", 4 + (elementData.rowDepth * 16), 0)
        end
        if entry.displayID and SetPortraitTextureFromCreatureDisplayID then
            SetPortraitTextureFromCreatureDisplayID(icon, entry.displayID)
        else
            icon:SetTexture(entry.icon or SentinelMentor:GetAddonIcon())
        end
        local nameColor = entry.starter and "|cffff8c00" or SentinelMentor.UIColors.SPELL_NAME
        local petLabel = entry.petLabel and ("  |cff9d9d9d<" .. entry.petLabel .. ">|r") or ""
        nameFS:SetText(nameColor .. entry.name .. "|r" .. petLabel)
        local starterLabel = entry.starter and "|cffff8c00≤ 6|r  " or ""
        levelFS:SetText(starterLabel .. ("%.1f, %.1f"):format(entry.location.x, entry.location.y))
        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.name)
            if entry.petLabel then GameTooltip:AddLine("<" .. entry.petLabel .. ">", 0.62, 0.62, 0.62) end
            GameTooltip:AddLine(entry.zoneName, 1, 1, 1)
            GameTooltip:AddLine(("%s: %.1f, %.1f"):format(SentinelMentor:Trans("LID_COORDINATES"), entry.location.x, entry.location.y), 1, 0.82, 0)
            if entry.starter then GameTooltip:AddLine(SentinelMentor:Trans("LID_TRAINS_THROUGH_LEVEL_6"), 1, 0.5, 0.2) end
            GameTooltip:AddLine(SentinelMentor:Trans("LID_LEFTCLICK_SETWAYPOINT"), 0.2, 1, 0.2)
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", GameTooltip_Hide)
        rowFrame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then SentinelMentor:SetClassTrainerWaypoint(entry) end
        end)
    elseif elementData.isNearestTrainer then
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", rowFrame, "LEFT", 4 + ((elementData.rowDepth or 0) * 16), 0)
        icon:SetTexture(elementData.icon or 134269)
        local title = SentinelMentor:Trans("LID_NEARESTPROFTRAINER"):format(elementData.rankName)
        nameFS:SetText("|cff33ff99" .. title .. "|r")
        local nearest = elementData.nearest
        levelFS:SetText(nearest and (nearest.name .. "  |cff9d9d9d" .. nearest.zoneName .. "|r") or "|cff9d9d9d-|r")
        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetText(title)
            GameTooltip:AddLine(SentinelMentor:Trans("LID_NEARESTPROFTRAINER_DESC"), 1, 1, 1, true)
            if nearest then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(nearest.name)
                if nearest.petLabel then GameTooltip:AddLine("<" .. nearest.petLabel .. ">", 0.62, 0.62, 0.62) end
                GameTooltip:AddLine(nearest.zoneName, 1, 1, 1)
                GameTooltip:AddLine(("%s: %.1f, %.1f"):format(SentinelMentor:Trans("LID_COORDINATES"), nearest.location.x, nearest.location.y), 1, 0.82, 0)
            end
            GameTooltip:AddLine(SentinelMentor:Trans("LID_LEFTCLICK_SETWAYPOINT"), 0.2, 1, 0.2)
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", GameTooltip_Hide)
        rowFrame:SetScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton" then return end
            local current = elementData.findNearest and elementData.findNearest() or nearest
            SentinelMentor.TrainerLocations.SetNearestWaypoint(current, "LID_NOPROFTRAINER")
        end)
    elseif elementData.isWeaponSkill then
        local entry = elementData.entry
        if elementData.rowDepth and elementData.rowDepth > 0 then
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", rowFrame, "LEFT", 4 + (elementData.rowDepth * 16), 0)
        end

        icon:SetTexture(entry.icon)
        nameFS:SetText(elementData.color .. entry.name .. "|r")
        nameFS:ClearAllPoints()
        nameFS:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        nameFS:SetPoint("RIGHT", rowFrame, "CENTER", -6, 0)
        local levelText = entry.level > 1 and (elementData.color .. SentinelMentor:Trans("LID_LVL") .. " " .. entry.level .. "|r  ") or ""
        if elementData.showCost and entry.cost then
            local canAfford = entry.cost == 0 or (GetMoney() or 0) >= entry.cost
            local costColor = canAfford and "|cffffffff" or "|cffff3333"
            levelFS:SetText(levelText .. costColor .. GetMoneyString(entry.cost, true) .. "|r")
        else
            levelFS:SetText(levelText)
        end

        local locationSize = math.max(12, math.min(24, (rowFrame:GetHeight() or SentinelMentor.RowHeight) - 4))
        for index, location in ipairs(entry.locations) do
            local locationInfo = location
            local button = GetRowLocationButton(rowFrame, index)
            button:ClearAllPoints()
            button:SetPoint("LEFT", rowFrame, "CENTER", (index - 1) * (locationSize + 3), 0)
            button:SetSize(locationSize, locationSize)
            button.icon:SetTexture(location.icon)
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button:SetScript("OnEnter", function(sel)
                GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
                GameTooltip:SetText(locationInfo.npcName or locationInfo.name)
                GameTooltip:AddLine(locationInfo.name, 1, 1, 1)
                if locationInfo.x and locationInfo.y then
                    GameTooltip:AddLine(("%s: %.1f, %.1f"):format(SentinelMentor:Trans("LID_COORDINATES"), locationInfo.x, locationInfo.y), 1, 0.82, 0)
                    GameTooltip:AddLine(SentinelMentor:Trans("LID_LEFTCLICK_SETWAYPOINT"), 0.2, 1, 0.2)
                end
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", GameTooltip_Hide)
            button:SetScript("OnClick", function()
                SentinelMentor:SetWeaponTrainerWaypoint(locationInfo)
            end)
            button:Show()
        end

        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(entry.spellID)
            GameTooltip:Show()
        end)

        rowFrame:SetScript("OnLeave", GameTooltip_Hide)
    elseif elementData.isCardRow then
        icon:Hide()
        local halfW = math.floor(((rowFrame:GetWidth() or 400) - 14) / 2)
        for i = 1, 2 do
            local card = rowFrame.cards and rowFrame.cards[i]
            if not card then
                card = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
                card:SetFrameLevel(rowFrame:GetFrameLevel() + 4)
                SentinelMentor.Style:Template(card, "inset")
                card.icon = card:CreateTexture(nil, "ARTWORK")
                card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                card.icon:SetPoint("LEFT", card, "LEFT", 4, 0)
                card.edge = card:CreateTexture(nil, "BORDER")
                card.edge:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -1)
                card.edge:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 1)
                card.edge:SetWidth(2)
                card.edge:SetTexture(SentinelMentor.Style.tex.blank)
                card.name = card:CreateFontString(nil, "OVERLAY")
                card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 6, 1)
                card.name:SetPoint("RIGHT", card, "RIGHT", -4, 0)
                card.name:SetJustifyH("LEFT")
                card.name:SetWordWrap(false)
                card.meta = card:CreateFontString(nil, "OVERLAY")
                card.meta:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 6, -1)
                card.meta:SetPoint("RIGHT", card, "RIGHT", -4, 0)
                card.meta:SetJustifyH("LEFT")
                card.meta:SetWordWrap(false)
                card:RegisterForClicks("AnyUp")
                rowFrame.cards = rowFrame.cards or {}
                rowFrame.cards[i] = card
            end

            local e = elementData.spells[i]
            if e and e.entry then
                local entry = e.entry
                local x0 = 4 + (i - 1) * (halfW + 6)
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", x0, -2)
                card:SetSize(halfW, (rowFrame:GetHeight() or rowHeight or 32) - 4)
                local iconSz = math.max(8, card:GetHeight() - 8)
                card.icon:SetSize(iconSz, iconSz)
                card.icon:SetTexture(entry.icon)
                local hex = e.color and e.color:match("|cff(%x%x%x%x%x%x)")
                if hex then
                    card.edge:SetVertexColor(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, 1)
                else
                    card.edge:SetVertexColor(0.15, 0.19, 0.30, 1)
                end

                local rankSubtext = GetLocalizedRankText(entry.spellID, entry.rankNum, entry.hasRealRank)
                local passiveSubtext = GetLocalizedPassiveText(entry.spellID)
                local sub = {}
                if rankSubtext then table.insert(sub, rankSubtext) end
                if passiveSubtext and passiveSubtext ~= rankSubtext then table.insert(sub, passiveSubtext) end
                local rankText = #sub > 0 and (" " .. Colors.RANK .. "(" .. table.concat(sub, ") (") .. ")|r") or ""
                local nameColor = e.dimName and Colors.DIM_NAME or Colors.SPELL_NAME
                card.name:SetFont(SentinelMentor.Style.font.normal, math.max(8, fontSize - 1), "OUTLINE")
                card.name:SetText(nameColor .. entry.name .. "|r" .. rankText)
                local metaParts = {}
                if e.showLevel and entry.level then
                    table.insert(metaParts, GetLevelDiffColorCode(entry.level) .. "Lvl " .. entry.level .. "|r")
                end
                if entry.baseCost ~= nil or (entry.cost and entry.cost > 0) then
                    local costColor = e.dimName and Colors.DIM_NAME or ((GetMoney() or 0) >= entry.cost and "|cffffffff" or "|cffff3333")
                    table.insert(metaParts, costColor .. SentinelMentor.Pricing.Text(entry.baseCost, entry.cost, entry.baseCostEstimated, costColor) .. "|r")
                end
                if entry.isProfessionRecipe and entry.source then
                    table.insert(metaParts, "|cff8c92a4" .. entry.source .. "|r")
                end
                card.meta:SetFont(SentinelMentor.Style.font.normal, math.max(8, fontSize - 2), "OUTLINE")
                card.meta:SetText(table.concat(metaParts, "  |cff555c6a·|r  "))
                card:SetScript("OnEnter", function(sel)
                    GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
                    local showCost = e.showCostTooltip and entry.cost ~= nil
                    if entry.spellID then
                        pendingSpellTooltipExtra = {
                            spellID = entry.spellID,
                            showCost = showCost,
                            cost = entry.cost,
                            priceEntry = entry,
                            source = entry.source,
                        }
                        GameTooltip:SetSpellByID(entry.spellID)
                    else
                        pendingSpellTooltipExtra = nil
                        GameTooltip:SetText(entry.name)
                        if showCost then
                            local canAfford = not entry.cost or entry.cost == 0 or (GetMoney() or 0) >= entry.cost
                            local costColor = canAfford and "|cffffffff" or "|cffff3333"
                            if entry.baseCost == nil then GameTooltip:AddLine(SentinelMentor:Trans("LID_COSTS") .. ": " .. costColor .. FormatCost(entry.cost) .. "|r", 1, 1, 1) end
                            SentinelMentor.Pricing.AddTooltip(GameTooltip, entry)
                            GameTooltip:AddLine(SentinelMentor:Trans("LID_OWNGOLD") .. ": " .. GetMoneyString(GetMoney() or 0, true), 1, 1, 1)
                        end
                        if entry.source then GameTooltip:AddLine(SentinelMentor:Trans("LID_SOURCE") .. ": " .. entry.source, 0.9, 0.9, 0.9, true) end
                    end
                    GameTooltip:Show()
                end)
                card:SetScript("OnLeave", function(sel)
                    pendingSpellTooltipExtra = nil
                    GameTooltip_Hide(sel)
                end)
                card:SetScript("OnMouseUp", function(sel, button) if button == "RightButton" then SentinelMentor:ShowIgnoreMenu(sel, entry) end end)
                card:Show()
            else
                card:Hide()
            end
        end
    else
        local entry = elementData.entry
        if elementData.rowDepth and elementData.rowDepth > 0 then
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", rowFrame, "LEFT", 4 + (elementData.rowDepth * 16), 0)
        end
        icon:SetTexture(entry.icon)
        local rankSubtext = GetLocalizedRankText(entry.spellID, entry.rankNum, entry.hasRealRank)
        local passiveSubtext = GetLocalizedPassiveText(entry.spellID)
        local subtexts = {}
        if rankSubtext then table.insert(subtexts, rankSubtext) end
        if passiveSubtext and passiveSubtext ~= rankSubtext then table.insert(subtexts, passiveSubtext) end
        local rankText = #subtexts > 0 and (" " .. Colors.RANK .. "(" .. table.concat(subtexts, ") (") .. ")|r") or ""
        local nameColor = elementData.dimName and Colors.DIM_NAME or Colors.SPELL_NAME
        nameFS:SetText(nameColor .. entry.name .. "|r" .. rankText)
        if elementData.showLevel then
            if elementData.levelLabel then
                local levelPrefix = entry.levelReq and (SentinelMentor:Trans("LID_LVL") .. " " .. entry.levelReq .. " ") or ""
                rowFrame.levelFull = Colors.RANK .. levelPrefix .. elementData.levelLabel .. " " .. entry.level .. "|r"
            else
                rowFrame.levelFull = GetLevelDiffColorCode(entry.level) .. "Level " .. entry.level .. "|r"
                rowFrame.levelShort = GetLevelDiffColorCode(entry.level) .. entry.level .. "|r"
            end
            levelFS:SetText(rowFrame.levelFull)
        end

        if elementData.costColumn then
            SetFontSize(costFS, fontSize)
            costFS:ClearAllPoints()
            costFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
            costFS:Show()
            costFS:SetWidth(GetCostColumnWidth(costFS, elementData.costColumn, fontSize))
            if entry.baseCost ~= nil or (entry.cost and entry.cost > 0) then
                local costColor = elementData.dimName and Colors.DIM_NAME or ((GetMoney() or 0) >= entry.cost and "|cffffffff" or "|cffff3333")
                costFS:SetText(costColor .. SentinelMentor.Pricing.Text(entry.baseCost, entry.cost, entry.baseCostEstimated, costColor) .. "|r")
            else
                costFS:SetText("")
            end

            levelFS:ClearAllPoints()
            levelFS:SetPoint("RIGHT", costFS, "LEFT", -12, 0)
        end

        if entry.isProfessionRecipe and entry.source then
            SetFontSize(sourceFS, fontSize)
            sourceFS:ClearAllPoints()
            sourceFS:SetPoint("RIGHT", levelFS, "LEFT", -8, 0)
            sourceFS:SetWidth(math.max(80, math.min(150, (rowFrame:GetWidth() or 420) * 0.32)))
            sourceFS:SetText("|cffaaaaaa" .. entry.source .. "|r")
            sourceFS:Show()
            nameFS:ClearAllPoints()
            nameFS:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            nameFS:SetPoint("RIGHT", sourceFS, "LEFT", -8, 0)
        end

        local locations = entry.isProfessionRecipe and entry.sourceLocations
        if locations and #locations > 0 then
            local locationSize = math.max(12, math.min(20, (rowFrame:GetHeight() or SentinelMentor.RowHeight) - 4))
            local shown = math.min(3, #locations)
            for index = 1, shown do
                local locationInfo = locations[index]
                local button = GetRowLocationButton(rowFrame, index)
                button:ClearAllPoints()
                button:SetPoint("RIGHT", levelFS, "LEFT", -6 - ((index - 1) * (locationSize + 3)), 0)
                button:SetSize(locationSize, locationSize)
                if locationInfo.questID then
                    button.icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
                    button.icon:SetTexCoord(0, 1, 0, 1)
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
                    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end

                button:SetScript("OnEnter", function(sel)
                    GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
                    GameTooltip:SetText(locationInfo.questName or locationInfo.npcName or SentinelMentor:Trans("LID_SOURCE"))
                    if locationInfo.questName and locationInfo.npcName then GameTooltip:AddLine(locationInfo.npcName, 1, 0.82, 0) end
                    GameTooltip:AddLine(locationInfo.zoneName or (C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(locationInfo.uiMapID)) or tostring(locationInfo.uiMapID), 1, 1, 1)
                    GameTooltip:AddLine(("%s: %.1f, %.1f"):format(SentinelMentor:Trans("LID_COORDINATES"), locationInfo.x, locationInfo.y), 1, 0.82, 0)
                    GameTooltip:AddLine(SentinelMentor:Trans("LID_LEFTCLICK_SETWAYPOINT"), 0.2, 1, 0.2)
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", GameTooltip_Hide)
                button:SetScript("OnClick", function() SentinelMentor:SetMapWaypoint(locationInfo) end)
                button:Show()
            end

            sourceFS:ClearAllPoints()
            sourceFS:SetPoint("RIGHT", rowFrame.locationButtons[shown], "LEFT", -5, 0)
        end

        if sourceFS:IsShown() then rowFrame.levelShort = nil end
        rowFrame.levelNameLeft = 4 + (elementData.rowDepth or 0) * 16 + iconSize + 6
        FitRowLevel(rowFrame)

        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            local showCost = elementData.showCostTooltip and entry.cost ~= nil
            if entry.spellID then
                pendingSpellTooltipExtra = {
                    spellID = entry.spellID,
                    showCost = showCost,
                    cost = entry.cost,
                    priceEntry = entry,
                    source = entry.source,
                }

                GameTooltip:SetSpellByID(entry.spellID)
            else
                pendingSpellTooltipExtra = nil
                GameTooltip:SetText(entry.name)
                if showCost then
                    local canAfford = not entry.cost or entry.cost == 0 or (GetMoney() or 0) >= entry.cost
                    local costColor = canAfford and "|cffffffff" or "|cffff3333"
                    if entry.baseCost == nil then GameTooltip:AddLine(SentinelMentor:Trans("LID_COSTS") .. ": " .. costColor .. FormatCost(entry.cost) .. "|r", 1, 1, 1) end
                    SentinelMentor.Pricing.AddTooltip(GameTooltip, entry)
                    GameTooltip:AddLine(SentinelMentor:Trans("LID_OWNGOLD") .. ": " .. GetMoneyString(GetMoney() or 0, true), 1, 1, 1)
                end

                if entry.source then GameTooltip:AddLine(SentinelMentor:Trans("LID_SOURCE") .. ": " .. entry.source, 0.9, 0.9, 0.9, true) end
            end

            GameTooltip:Show()
        end)

        rowFrame:SetScript("OnLeave", function(sel)
            pendingSpellTooltipExtra = nil
            GameTooltip_Hide(sel)
        end)

        rowFrame:SetScript("OnMouseUp", function(sel, button) if button == "RightButton" then SentinelMentor:ShowIgnoreMenu(sel, entry) end end)
    end
end
