local ADDON_NAME, SM = ...
SM.DJ = SM.DJ or {}
local SMJ = SM.DJ
local L = SMJ._J.L
local DB = SMJ._J.DB
local ApplyLocaleFontTree = SMJ._J.ApplyLocaleFontTree
local portraitResolver = SMJ._J.portraitResolver
local portraitResolveQueue = SMJ._J.portraitResolveQueue
local itemTooltipQualityCache = SMJ._J.itemTooltipQualityCache
local CurrentDungeon = SMJ._J.CurrentDungeon
local questDataRequests = SMJ._J.questDataRequests
local RefreshAll = SMJ._J.RefreshAll
local RefreshHomeDungeonCards = SMJ._J.RefreshHomeDungeonCards
local RefreshLoot = SMJ._J.RefreshLoot
local RefreshQuestList = SMJ._J.RefreshQuestList
local RefreshQuestDetail = SMJ._J.RefreshQuestDetail
local SelectDungeon = SMJ._J.SelectDungeon
local ApplySelectedLanguage = SMJ._J.ApplySelectedLanguage
local ScanEncounterJournal = SMJ._J.ScanEncounterJournal
local CreateItemTooltip = SMJ._J.CreateItemTooltip
local CreateMainFrame = SMJ._J.CreateMainFrame
local function PositionMinimap()
    if not SMJ._J.minimapButton or not Minimap or SMJ._minimapUsingLibDBIcon then return end

    local angle = math.rad(SentinelMentorJournalDB.minimapAngle or 225)
    local radius = (
        math.max(Minimap:GetWidth() or 140, Minimap:GetHeight() or 140) * 0.5
    ) + 8

    SMJ._J.minimapButton:ClearAllPoints()
    SMJ._J.minimapButton:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(angle) * radius,
        math.sin(angle) * radius
    )
end

local function ToggleJournal()
    if SMJ._J.frame:IsShown() then
        SMJ._J.frame:Hide()
    else
        SMJ._J.frame:Show()
    end
end

SMJ.ToggleJournal = ToggleJournal
_G.SentinelMentorJournal_Toggle = function()
    if SMJ.ToggleJournal then
        SMJ.ToggleJournal()
    end
end

local function HideMinimapButton()
    SentinelMentorJournalDB.minimapHidden = true
    SentinelMentorJournalDB.minimap = SentinelMentorJournalDB.minimap or {}
    SentinelMentorJournalDB.minimap.hide = true

    if SMJ._minimapUsingLibDBIcon and SMJ._minimapIconLib then
        SMJ._minimapIconLib:Hide("SentinelMentor")
    elseif SMJ._J.minimapButton then
        SMJ._J.minimapButton:Hide()
    end

    print("|cffd8a83cDungeonJournal|r " .. L("MINIMAP_HIDDEN"))
end

-- Right-clicking the minimap button asks first: many players hid it by accident.
SMJ.HideMinimapButton = HideMinimapButton
SMJ.ConfirmHideMinimapButton = function()
    if not StaticPopupDialogs or not StaticPopup_Show then
        HideMinimapButton()
        return
    end
    StaticPopupDialogs["SENTINELMENTORJOURNAL_HIDE_MINIMAP"] = {
        text = L("MINIMAP_HIDE_CONFIRM"),
        button1 = YES or "Yes",
        button2 = NO or "No",
        OnAccept = function() HideMinimapButton() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("SENTINELMENTORJOURNAL_HIDE_MINIMAP")
end

function SMJ.ShowMinimapButton()
    SentinelMentorJournalDB.minimapHidden = false
    SentinelMentorJournalDB.minimap = SentinelMentorJournalDB.minimap or {}
    SentinelMentorJournalDB.minimap.hide = false

    if SMJ._minimapUsingLibDBIcon and SMJ._minimapIconLib then
        SMJ._minimapIconLib:Show("SentinelMentor")
        SMJ._J.minimapButton = _G["LibDBIcon10_SentinelMentorJournal"] or SMJ._J.minimapButton
    elseif SMJ._J.minimapButton then
        SMJ._J.minimapButton:Show()
        PositionMinimap()
    end
end

function SMJ.SetupLibDBIconMinimap()
    if not _G.LibStub then return false end

    local ldb = _G.LibStub("LibDataBroker-1.1", true)
    local iconLib = _G.LibStub("LibDBIcon-1.0", true)
    if not ldb or not iconLib then return false end

    SentinelMentorJournalDB.minimap = SentinelMentorJournalDB.minimap or {}
    local db = SentinelMentorJournalDB.minimap

    -- Migrate the old position once. LibDBIcon stores the same angular value in
    -- minimapPos, while the previous SMJ button used minimapAngle.
    if db.minimapPos == nil then
        db.minimapPos = SentinelMentorJournalDB.minimapAngle or 225
    end
    db.hide = SentinelMentorJournalDB.minimapHidden and true or false

    local object = ldb:GetDataObjectByName("SentinelMentor")
    if not object then
        object = ldb:NewDataObject("SentinelMentor", {
            type = "launcher",
            text = "DungeonJournal",
            icon = "Interface\\Icons\\INV_Misc_Book_09",
            OnClick = function(_, button)
                if button == "LeftButton" then
                    ToggleJournal()
                elseif button == "RightButton" then
                    if SMJ.ToggleSettingsPanel then SMJ.ToggleSettingsPanel() else SMJ.ConfirmHideMinimapButton() end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("DungeonJournal", 1, 0.82, 0.25)
                tooltip:AddLine(L("MINIMAP_LEFT"), 1, 1, 1)
                tooltip:AddLine(L("MINIMAP_DRAG"), 0.8, 0.8, 0.8)
                tooltip:AddLine(L("MINIMAP_OPTIONS"), 0.8, 0.8, 0.8)
            end,
        })
    end

    SMJ._minimapDataObject = object
    SMJ._minimapIconLib = iconLib

    if not iconLib:IsRegistered("SentinelMentor") then
        iconLib:Register("SentinelMentor", object, db)
    end

    SMJ._J.minimapButton = _G["LibDBIcon10_SentinelMentorJournal"]
    if SMJ._J.minimapButton then
        -- These fields are present on a normal LibDBIcon button and are also
        -- useful to minimap-button collectors that inspect the SMJ._J.frame directly.
        SMJ._J.minimapButton.dataObject = object
        SMJ._J.minimapButton.db = db
    end

    SMJ._minimapUsingLibDBIcon = true

    if db.hide then
        iconLib:Hide("SentinelMentor")
    else
        iconLib:Show("SentinelMentor")
    end

    return true
end

-- While RPG Mode is on the minimap book turns white: the same book icon,
-- desaturated, with a brightening copy added on top (no extra image needed,
-- so it stays a crisp book at minimap size).
SMJ.UpdateMinimapIcon = function()
    local rpg = SMJ.IsRPGMode and SMJ.IsRPGMode() or false
    local book = "Interface\\Icons\\INV_Misc_Book_09"
    if SMJ._minimapDataObject and SMJ._minimapDataObject.icon ~= book then SMJ._minimapDataObject.icon = book end
    local button = _G["LibDBIcon10_SentinelMentorJournal"]
    local icon = button and button.icon
    if not icon or not icon.SetDesaturated then return end
    icon:SetDesaturated(rpg)
    if not button.fdjWhite then
        local w = button:CreateTexture(nil, "ARTWORK", nil, 7)
        w:SetTexture(book)
        w:SetDesaturated(true)
        w:SetBlendMode("ADD")
        w:SetAlpha(0.6)
        button.fdjWhite = w
    end
    local w = button.fdjWhite
    w:ClearAllPoints()
    w:SetAllPoints(icon)
    if icon.GetTexCoord then w:SetTexCoord(icon:GetTexCoord()) end
    w:SetShown(rpg)
end

function SMJ.CreateFallbackMinimap()
    SMJ._minimapUsingLibDBIcon = false

    SMJ._J.minimapButton = _G["LibDBIcon10_SentinelMentorJournal"]
        or CreateFrame("Button", "LibDBIcon10_SentinelMentorJournal", Minimap)

    SMJ._J.minimapButton:SetParent(Minimap)
    SMJ._J.minimapButton:SetSize(31, 31)
    SMJ._J.minimapButton:SetFrameStrata("MEDIUM")
    SMJ._J.minimapButton:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    SMJ._J.minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    SMJ._J.minimapButton:RegisterForDrag("LeftButton")

    -- Match the public shape of a normal LibDBIcon button as closely as possible
    -- for collectors even when no shared LibDBIcon library is available.
    SentinelMentorJournalDB.minimap = SentinelMentorJournalDB.minimap or {}
    SMJ._J.minimapButton.db = SentinelMentorJournalDB.minimap
    SMJ._J.minimapButton.dataObject = SMJ._J.minimapButton.dataObject or {
        type = "launcher",
        text = "DungeonJournal",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
    }

    if not SMJ._J.minimapButton.fdjInitialized then
        local bg = SMJ._J.minimapButton:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
        bg:SetSize(20, 20)
        bg:SetPoint("CENTER")

        local icon = SMJ._J.minimapButton:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
        icon:SetSize(20, 20)
        icon:SetPoint("CENTER")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        SMJ._J.minimapButton.icon = icon

        local border = SMJ._J.minimapButton:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetSize(54, 54)
        border:SetPoint("TOPLEFT", -1, 1)
        SMJ._J.minimapButton.border = border

        SMJ._J.minimapButton:SetScript("OnClick", function(_, button)
            if button == "LeftButton" then
                ToggleJournal()
            elseif button == "RightButton" then
                if SMJ.ToggleSettingsPanel then SMJ.ToggleSettingsPanel() else SMJ.ConfirmHideMinimapButton() end
            end
        end)

        SMJ._J.minimapButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("DungeonJournal", 1, 0.82, 0.25)
            GameTooltip:AddLine(L("MINIMAP_LEFT"), 1, 1, 1)
            GameTooltip:AddLine(L("MINIMAP_DRAG"), 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L("MINIMAP_OPTIONS"), 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)

        SMJ._J.minimapButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        SMJ._J.minimapButton:SetScript("OnDragStart", function(self)
            self:SetScript("OnUpdate", function()
                local mx, my = Minimap:GetCenter()
                if not mx or not my then return end

                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                x, y = x / scale, y / scale

                SentinelMentorJournalDB.minimapAngle =
                    math.deg(math.atan2(y - my, x - mx))

                PositionMinimap()
            end)
        end)

        SMJ._J.minimapButton:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
        end)

        SMJ._J.minimapButton.fdjInitialized = true
    end

    PositionMinimap()

    if SentinelMentorJournalDB.minimapHidden then
        SMJ._J.minimapButton:Hide()
    else
        SMJ._J.minimapButton:Show()
    end
end

function SMJ.CreateMinimap()
    -- Prefer the real shared LibDataBroker/LibDBIcon libraries when another
    -- enabled addon (including Leatrix Plus) provides them. This makes SMJ a
    -- genuinely registered LibDBIcon launcher instead of only imitating the
    -- SMJ._J.frame name, which is required by collectors that use the library registry.
    if SMJ.SetupLibDBIconMinimap() then
        return
    end

    -- Keep a standalone fallback so SMJ still has a minimap button when no
    -- broker/icon library exists in the user's addon set.
    SMJ.CreateFallbackMinimap()
end

-- ============================================================
-- COMMANDS / EVENTS
-- ============================================================

SLASH_SENTINELMENTORJOURNAL1 = "/smj"
SLASH_SENTINELMENTORJOURNAL2 = nil

SlashCmdList.SENTINELMENTORJOURNAL = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "lang" or msg == "language" then
        local active = SMJ.GetLanguage and SMJ.GetLanguage() or "enUS"
        local saved = SentinelMentorJournalDB.language or "auto"
        local display = saved == "auto" and L("LANGUAGE_AUTO", active) or active
        print("|cffd8a83cDungeonJournal|r " .. L("LANGUAGE_CURRENT", display))
        print("|cffd8a83cDungeonJournal|r " .. L("LANGUAGE_HELP"))
        return
    end

    local langArg = msg:match("^lang%s+(%S+)$") or msg:match("^language%s+(%S+)$")
    if langArg then
        ApplySelectedLanguage(langArg)
        local active, saved = SMJ.SetLanguage(langArg)
        local display = saved == "auto" and L("LANGUAGE_AUTO", active) or active
        print("|cffd8a83cDungeonJournal|r " .. L("LANGUAGE_SET", display))
        return
    end

    if msg:match("^wing") then
        local wing = SMJ.ScarletWingFromWord and SMJ.ScarletWingFromWord(msg:match("^wing%s+(%S+)") or "")
        if wing and SMJ.SetScarletWing and SMJ.SetScarletWing(wing) then
            print("|cffffd100Dungeon Journal|r " .. wing)
        else
            print("|cffffd100Dungeon Journal|r /smj wing graveyard  |  /smj wing library")
        end
        return
    end
    if msg == "options" or msg == "settings" or msg == "config" then
        if SMJ.ToggleSettingsPanel then SMJ.ToggleSettingsPanel() end
        return
    end
    if msg == "newids" then
        if SMJ.PrintLearnedItemIDs then SMJ.PrintLearnedItemIDs() end
        return
    end
    if msg == "itemtip" then
        local on = SMJ.ToggleItemSourceStrip and SMJ.ToggleItemSourceStrip()
        print("|cffffd100Dungeon Journal|r item source on tooltips: " .. (on and "ON" or "OFF"))
        return
    end
    if msg == "worldmap" then
        local on = SMJ.ToggleWorldMapOverlay and SMJ.ToggleWorldMapOverlay()
        print("|cffd8a83cDungeonJournal|r " .. L("WM_DUNGEON_MAP") .. " (M): " .. (on and "ON" or "OFF"))
        return
    end

    if msg:match("^scale") then
        local value = tonumber(msg:match("^scale%s+([%d%.]+)"))
        local scale = SMJ.SetJournalScale and SMJ.SetJournalScale(value or 1)
        print("|cffd8a83cDungeonJournal|r scale: " .. tostring(scale))
        return
    end

    if msg == "minimap" then
        SMJ.ShowMinimapButton()
        return
    end

    if msg == "rfc" or msg == "ragefire" or msg == "ragefirechasm" then
        SMJ._J.frame:Show()
        SelectDungeon("Ragefire Chasm")
        return
    end

    if msg == "hall" or msg == "hot" then
        SMJ._J.frame:Show()
        SelectDungeon("Hall of Thanes")
        return
    end

    if msg == "dm" or msg == "vc" or msg == "deadmines" then
        SMJ._J.frame:Show()
        SelectDungeon("The Deadmines")
        return
    end

    if msg == "ruins" or msg == "rol" or msg == "lordaeron" then
        SMJ._J.frame:Show()
        SelectDungeon("Ruins of Lordaeron")
        return
    end

    if msg == "wc" or msg == "wailing" or msg == "wailingcaverns" then
        SMJ._J.frame:Show()
        SelectDungeon("Wailing Caverns")
        return
    end

    if msg == "sfk" or msg == "shadowfang" or msg == "shadowfangkeep" then
        SMJ._J.frame:Show()
        SelectDungeon("Shadowfang Keep")
        return
    end

    if msg == "bfd" or msg == "blackfathom" or msg == "blackfathomdeeps" or msg == "blackfathomdepths" then
        SMJ._J.frame:Show()
        SelectDungeon("Blackfathom Deeps")
        return
    end

    -- Shortcuts for the dungeons added later (/smj smlib, /smj gnomer, ...).
    do
        local shortcuts = {
            stocks = "The Stockade", stockade = "The Stockade", stockades = "The Stockade",
            gnomer = "Gnomeregan", gnomeregan = "Gnomeregan",
            rfk = "Razorfen Kraul", kraul = "Razorfen Kraul", razorfenkraul = "Razorfen Kraul",
            dala = "City of Dalaran", dal = "City of Dalaran", dalaran = "City of Dalaran", cityofdalaran = "City of Dalaran",
            exca = "Excavation Site: Wetlands", excavation = "Excavation Site: Wetlands", wetlands = "Excavation Site: Wetlands",
            smgy = "Scarlet Monastery: Graveyard", gy = "Scarlet Monastery: Graveyard", graveyard = "Scarlet Monastery: Graveyard",
            smlib = "Scarlet Monastery: Library", lib = "Scarlet Monastery: Library", library = "Scarlet Monastery: Library",
            smarm = "Scarlet Monastery: Armory", arm = "Scarlet Monastery: Armory", armory = "Scarlet Monastery: Armory",
            smcath = "Scarlet Monastery: Cathedral", cath = "Scarlet Monastery: Cathedral", cathedral = "Scarlet Monastery: Cathedral",
            rfd = "Razorfen Downs", downs = "Razorfen Downs", razorfendowns = "Razorfen Downs",
            ulda = "Uldaman", uld = "Uldaman", uldaman = "Uldaman",
            zf = "Zul'Farrak", zulfarrak = "Zul'Farrak",
            st = "Sunken Temple", sunken = "Sunken Temple", sunkentemple = "Sunken Temple",
            scholo = "Scholomance", scholomance = "Scholomance", mara = "Maraudon", maraudon = "Maraudon",
            brd = "Blackrock Depths", depths = "Blackrock Depths", blackrockdepths = "Blackrock Depths",
            ubrs = "Upper Blackrock Spire", upperspire = "Upper Blackrock Spire",
            lbrs = "Lower Blackrock Spire", lowerspire = "Lower Blackrock Spire",
            dme = "Dire Maul: East", dmeast = "Dire Maul: East", dmw = "Dire Maul: West", dmwest = "Dire Maul: West",
            dmn = "Dire Maul: North", dmnorth = "Dire Maul: North", tribute = "Dire Maul: North",
            strat = "Stratholme: Living", stratlive = "Stratholme: Living", stratliving = "Stratholme: Living",
            stratud = "Stratholme: Undead", stratundead = "Stratholme: Undead", baron = "Stratholme: Undead",
        }
        local key = msg:gsub("[%s:%-']", "")
        local target = shortcuts[key]
        if target and DB[target] then
            SMJ._J.frame:Show()
            SelectDungeon(target)
            return
        end
    end

    ToggleJournal()
end

SMJ.events = SMJ.events or CreateFrame("Frame")
SMJ.events:RegisterEvent("PLAYER_LOGIN")
SMJ.events:RegisterEvent("PLAYER_LEAVING_WORLD")
SMJ.events:RegisterEvent("PLAYER_ENTERING_WORLD")
SMJ.events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
SMJ.events:RegisterEvent("QUEST_LOG_UPDATE")
SMJ.events:RegisterEvent("QUEST_TURNED_IN")
SMJ.events:RegisterEvent("QUEST_ACCEPTED")
SMJ.events:RegisterEvent("QUEST_REMOVED")
SMJ.events:RegisterEvent("QUEST_DATA_LOAD_RESULT")
SMJ.events:RegisterEvent("PLAYER_LEVEL_UP")
SMJ.events:RegisterEvent("GET_ITEM_INFO_RECEIVED")

-- Coalesce event bursts and refresh on the next SMJ._J.frame, outside API callbacks.
SMJ.questRefreshPending = false
SMJ.questRefreshWorker = SMJ.questRefreshWorker or CreateFrame("Frame")
SMJ.questRefreshWorker:Hide()
function SMJ.ScheduleQuestRefresh()
    if SMJ.questRefreshPending then return end
    SMJ.questRefreshPending = true
    SMJ.questRefreshWorker:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        self:Hide()
        SMJ.questRefreshPending = false
        if SMJ._J.frame and SMJ._J.frame:IsShown() then
            if SMJ._J.frame.currentView == "home" then
                RefreshHomeDungeonCards()
            elseif SMJ._J.selectedMode == "quests" then
                RefreshQuestList()
                RefreshQuestDetail()
            end
        end
    end)
    SMJ.questRefreshWorker:Show()
end

SMJ.events:SetScript("OnEvent", function(_, event, arg1, arg2)
    local questID, success = arg1, arg2
    if event == "PLAYER_LOGIN" then
        -- SavedVariables load after this file runs, so the display-ID cache
        -- captured at load time was a throwaway table. Rebind it to the real
        -- saved table so resolved portraits persist between sessions.
        SentinelMentorJournalDB.displayIDs = SentinelMentorJournalDB.displayIDs or {}
        if SMJ._J.displayIDCache ~= SentinelMentorJournalDB.displayIDs then
            for k, v in pairs(SMJ._J.displayIDCache) do
                if SentinelMentorJournalDB.displayIDs[k] == nil then SentinelMentorJournalDB.displayIDs[k] = v end
            end
            SMJ._J.displayIDCache = SentinelMentorJournalDB.displayIDs
        end
        if UnitFactionGroup then
            local playerFaction = UnitFactionGroup("player")
            if playerFaction == "Horde" then
                SMJ._J.selectedQuestFaction = "Horde"
            elseif playerFaction == "Alliance" then
                SMJ._J.selectedQuestFaction = "Alliance"
            end
            SentinelMentorJournalDB.questFaction = SMJ._J.selectedQuestFaction
        end

        ScanEncounterJournal()
        CreateItemTooltip()
        CreateMainFrame()
        SMJ.CreateMinimap()

        -- Boss portraits use journal data or numeric NPC-ID display resolution; no live unit-string parsing.

        RefreshAll()

        local addonVersion
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            addonVersion = C_AddOns.GetAddOnMetadata("SentinelMentor", "Version")
        elseif GetAddOnMetadata then
            addonVersion = GetAddOnMetadata("SentinelMentor", "Version")
        end
        addonVersion = (addonVersion and tostring(addonVersion)) or "1.7.0"
        print("|cffd8a83cDungeon Journal by Exehn|r |cffffffffv" .. addonVersion .. "|r")
        return
    end

    if event == "PLAYER_LEAVING_WORLD" then
        -- No portrait work during zoning: the warm-up and the lookups wait.
        SMJ.portraitZoning = true
        SMJ.portraitZoneSerial = (SMJ.portraitZoneSerial or 0) + 1
        return
    end

    if event == "QUEST_DATA_LOAD_RESULT" then
        if not questDataRequests[questID] then return end
        questDataRequests[questID] = success == false
            and {state = "failed", retryAt = (GetTime and GetTime() or 0) + 30}
            or {state = "loaded"}
        SMJ.ScheduleQuestRefresh()
        return
    end

    if event == "GET_ITEM_INFO_RECEIVED" then
        if itemTooltipQualityCache and questID then
            itemTooltipQualityCache[questID] = nil
        end
        if SMJ._J.frame and SMJ._J.frame:IsShown() then
            if SMJ._J.selectedMode == "bosses" then
                RefreshLoot()
            elseif SMJ._J.selectedMode == "quests" then
                RefreshQuestDetail()
                ApplyLocaleFontTree(SMJ._J.frame)
            end
            -- Forever custom-item metadata may become available after the
            -- search dropdown was already built. Refresh it in-place so names
            -- and icons update without making the player retype the query.
            if SMJ._J.frame.RefreshSearchResults and SMJ._J.frame.searchEditBox
                and SMJ._J.frame.searchResultsFrame and SMJ._J.frame.searchResultsFrame:IsShown() then
                SMJ._J.frame.RefreshSearchResults(SMJ._J.frame.searchEditBox:GetText() or "", true)
            end
        end
        return
    end

    if event == "QUEST_LOG_UPDATE"
        or event == "QUEST_TURNED_IN"
        or event == "QUEST_ACCEPTED"
        or event == "QUEST_REMOVED"
        or event == "PLAYER_LEVEL_UP"
    then
        SMJ.ScheduleQuestRefresh()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Keep the loading transition clean: no hidden tooltip scans and no
        -- model work synchronously on PLAYER_ENTERING_WORLD. Select the
        -- current dungeon immediately, but refresh visible UI only after the
        -- world has settled.
        local current = CurrentDungeon()
        if current and DB[current] then
            SMJ._J.selectedDungeon = current
            SentinelMentorJournalDB.lastDungeon = current
            if SMJ._J.selectedBoss > #DB[current].bosses then
                SMJ._J.selectedBoss = 1
                SentinelMentorJournalDB.lastBoss = 1
            end
        end

        if C_Timer and type(C_Timer.After) == "function" then
            C_Timer.After(2.25, function()
                if SMJ._J.frame and SMJ._J.frame:IsShown() then
                    RefreshAll()
                end
            end)
            -- Portrait work resumes once the world has settled; the first
            -- time, the warm-up starts a few seconds later.
            local serial = SMJ.portraitZoneSerial
            C_Timer.After(2, function()
                if SMJ.portraitZoneSerial ~= serial then return end
                SMJ.portraitZoning = false
                if portraitResolver and #portraitResolveQueue > 0 then portraitResolver:Show() end
            end)
            if not SMJ.portraitsPrewarmed then
                C_Timer.After(6, function()
                    if SMJ.PrewarmBossPortraits then pcall(SMJ.PrewarmBossPortraits) end
                end)
            end
        end
        return
    end

    local current = CurrentDungeon()

    if current and DB[current] then
        SMJ._J.selectedDungeon = current
        SentinelMentorJournalDB.lastDungeon = current

        if SMJ._J.selectedBoss > #DB[current].bosses then
            SMJ._J.selectedBoss = 1
            SentinelMentorJournalDB.lastBoss = 1
        end

        if SMJ._J.frame and SMJ._J.frame:IsShown() then
            RefreshAll()
        end
    end
end)
