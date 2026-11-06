local _, SentinelMentor = ...
local exportFrame
local exportBox
local function SortNumberKeys(data)
    local keys = {}
    for key in pairs(data or {}) do
        if type(key) == "number" then table.insert(keys, key) end
    end
    table.sort(keys)
    return keys
end

local function BuildLevelExport(levelData)
    local lines = {}
    for _, level in ipairs(SortNumberKeys(levelData)) do
        local spells = levelData[level]
        for _, spellID in ipairs(SortNumberKeys(spells)) do
            local entry = spells[spellID]
            local cost = type(entry) == "table" and entry.cost or entry
            local rank = type(entry) == "table" and entry.rank or nil
            local requires = type(entry) == "table" and entry.requires or nil
            local requirementText = ""
            if type(requires) == "table" then
                local requirementIDs = {}
                for _, requiredSpellID in ipairs(requires) do
                    table.insert(requirementIDs, tostring(requiredSpellID))
                end
                requirementText = table.concat(requirementIDs, "|")
            end
            table.insert(lines, table.concat({level, spellID, cost or 0, rank or "", requirementText}, ";"))
        end
    end
    return table.concat(lines, "\n"), #lines
end

local function BuildClassExport(classToken)
    local classData = SentinelMentor_Data and SentinelMentor_Data[classToken]
    return BuildLevelExport(classData)
end

local function BuildRequirementText(requires)
    if type(requires) ~= "table" then return "" end
    local requirementIDs = {}
    for _, requiredSpellID in ipairs(requires) do
        table.insert(requirementIDs, tostring(requiredSpellID))
    end
    return table.concat(requirementIDs, "|")
end

local function SanitizeExportText(value)
    return tostring(value or ""):gsub("[;\r\n]", " ")
end

local function BuildProfessionExport()
    local sections = {}
    local totalCount = 0
    local professionKeys = {}
    for professionKey in pairs(SentinelMentor_ProfessionData or {}) do
        table.insert(professionKeys, professionKey)
    end
    table.sort(professionKeys)

    for _, professionKey in ipairs(professionKeys) do
        local lines = {}
        local professionData = SentinelMentor_ProfessionData[professionKey]
        for _, skillReq in ipairs(SortNumberKeys(professionData)) do
            local recipes = {}
            for name, entry in pairs(professionData[skillReq] or {}) do
                table.insert(recipes, {name = name, entry = entry})
            end
            table.sort(recipes, function(left, right)
                local leftID = tonumber(left.entry and left.entry.spellID) or math.huge
                local rightID = tonumber(right.entry and right.entry.spellID) or math.huge
                if leftID ~= rightID then return leftID < rightID end
                return tostring(left.name) < tostring(right.name)
            end)
            for _, recipe in ipairs(recipes) do
                local entry = recipe.entry or {}
                table.insert(lines, table.concat({
                    skillReq,
                    entry.spellID or "",
                    entry.cost or 0,
                    entry.icon or "",
                    entry.rankRow and 1 or "",
                    BuildRequirementText(entry.requires),
                    SanitizeExportText(entry.faction),
                    SanitizeExportText(entry.race),
                    SanitizeExportText(recipe.name)
                }, ";"))
            end
        end
        if #lines > 0 then
            table.insert(sections, ("[%s]\n%s"):format(professionKey, table.concat(lines, "\n")))
            totalCount = totalCount + #lines
        end
    end
    return table.concat(sections, "\n\n"), totalCount
end

local WARLOCK_PETS = {
    {token = "Imp", spellID = 688},
    {token = "Voidwalker", spellID = 697},
    {token = "Succubus", spellID = 712},
    {token = "Incubus", spellID = 101822},
    {token = "Felhunter", spellID = 691},
    {token = "Felguard", spellID = 30146}
}

local function MergePetData(token, localizedName)
    local merged = {}
    local keys = {token}
    if localizedName and localizedName ~= token then table.insert(keys, localizedName) end
    for _, key in ipairs(keys) do
        local levels = SentinelMentor_PetData and SentinelMentor_PetData[key]
        for level, spells in pairs(levels or {}) do
            merged[level] = merged[level] or {}
            for spellID, entry in pairs(spells) do
                merged[level][spellID] = entry
            end
        end
    end
    return merged
end

local function BuildWarlockPetExport()
    local sections = {}
    local count = 0
    for _, pet in ipairs(WARLOCK_PETS) do
        local localizedName = SentinelMentor:GetPetNameById(pet.spellID)
        local text, petCount = BuildLevelExport(MergePetData(pet.token, localizedName))
        if petCount > 0 then
            table.insert(sections, ("[%s]\n%s"):format(pet.token, text))
            count = count + petCount
        end
    end
    return table.concat(sections, "\n\n"), count
end

local function CreateExportFrame()
    local frame = SentinelMentor:CreateUIWindowFrame("SentinelMentorExportFrame", UIParent)
    frame:SetSize(720, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.Title = frame.TitleText

    local scrollHolder = SentinelMentor.Style:Scroll(frame, 660, 430)
    scrollHolder:SetPoint("TOPLEFT", 24, -50)
    scrollHolder:SetPoint("BOTTOMRIGHT", -40, 24)
    local scrollFrame = scrollHolder.scroll

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(SentinelMentor.Style.font.normal, 12, "")
    editBox:SetWidth(630)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    scrollFrame:SetScrollChild(editBox)

    exportFrame = frame
    exportBox = editBox
end

local function ShowExport(title, text, count)
    if not exportFrame then CreateExportFrame() end
    local lineCount = text == "" and 1 or select(2, text:gsub("\n", "\n")) + 1
    exportFrame.Title:SetText(title)
    exportBox:SetText(text)
    exportBox:SetHeight(math.max(440, lineCount * 14 + 12))
    exportFrame:Show()
    exportBox:SetFocus()
    exportBox:HighlightText()
end

function SentinelMentor:ShowClassExport()
    local localizedClass, classToken = UnitClass("player")
    if not classToken then
        SentinelMentor:MSG(SentinelMentor:Trans("LID_CLASSUNKNOWN"))
        return
    end

    local text, count = BuildClassExport(classToken)
    ShowExport(("SentinelMentor: %s (%s)"):format(localizedClass or classToken, SentinelMentor:Trans("LID_ENTRIESCOUNT"):format(count)), text, count)
    if count == 0 then SentinelMentor:MSG(SentinelMentor:Trans("LID_NOCLASSDATA")) end
end

function SentinelMentor:ShowPetExport()
    local localizedClass, classToken = UnitClass("player")
    local text, count
    if classToken == "HUNTER" then
        text, count = BuildLevelExport(SentinelMentor_PetTrainerData and SentinelMentor_PetTrainerData.HUNTER)
    elseif classToken == "WARLOCK" then
        text, count = BuildWarlockPetExport()
    else
        SentinelMentor:MSG(SentinelMentor:Trans("LID_PETEXPORTONLY"))
        return
    end

    ShowExport(("SentinelMentor %s: %s (%s)"):format(SentinelMentor:Trans("LID_PETTRAINING"), localizedClass or classToken, SentinelMentor:Trans("LID_ENTRIESCOUNT"):format(count)), text, count)
    if count == 0 then SentinelMentor:MSG(SentinelMentor:Trans("LID_NOPETDATA")) end
end

function SentinelMentor:ShowProfessionExport()
    local text, count = BuildProfessionExport()
    ShowExport(("SentinelMentor %s (%s)"):format(SentinelMentor:Trans("LID_PROFESSIONS"), SentinelMentor:Trans("LID_ENTRIESCOUNT"):format(count)), text, count)
    if count == 0 then SentinelMentor:MSG(SentinelMentor:Trans("LID_NOPROFESSIONDATA")) end
end

function SentinelMentor:EnableTrainerDebugFilters()
    if not GetTrainerServiceTypeFilter or not SetTrainerServiceTypeFilter then return false end
    local changed = false
    for _, filter in ipairs({"available", "unavailable", "used"}) do
        if not GetTrainerServiceTypeFilter(filter) then
            SetTrainerServiceTypeFilter(filter, true)
            changed = true
        end
    end
    return changed
end

SLASH_SENTINELMENTORDUMP1 = "/tsdump"
SLASH_SENTINELMENTORDUMP2 = "/sentinelmentordump"
SlashCmdList.SENTINELMENTORDUMP = function()
    SentinelMentor:ShowClassExport()
end

SLASH_SENTINELMENTORPETDUMP1 = "/tspetdump"
SLASH_SENTINELMENTORPETDUMP2 = "/sentinelmentorpetdump"
SlashCmdList.SENTINELMENTORPETDUMP = function()
    SentinelMentor:ShowPetExport()
end

SLASH_SENTINELMENTORPROFDUMP1 = "/tsprofdump"
SLASH_SENTINELMENTORPROFDUMP2 = "/sentinelmentorprofdump"
SlashCmdList.SENTINELMENTORPROFDUMP = function()
    SentinelMentor:ShowProfessionExport()
end

SLASH_SENTINELMENTORDEBUG1 = "/tsdebug"
SlashCmdList.SENTINELMENTORDEBUG = function(input)
    input = tostring(input or ""):lower():match("^%s*(.-)%s*$")
    if input == "on" then
        SentinelMentor.DebugTrainerEnabled = true
    elseif input == "off" then
        SentinelMentor.DebugTrainerEnabled = false
    else
        SentinelMentor.DebugTrainerEnabled = not SentinelMentor.DebugTrainerEnabled
    end

    if SentinelMentor.DebugTrainerEnabled then
        SentinelMentor:EnableTrainerDebugFilters()
        SentinelMentor:MSG(SentinelMentor:Trans("LID_TRAINERDEBUGON"))
        if ClassTrainerFrame and ClassTrainerFrame:IsShown() then
            C_Timer.After(0.1, function() SentinelMentor:CaptureTrainer() end)
        end
    else
        SentinelMentor:MSG(SentinelMentor:Trans("LID_TRAINERDEBUGOFF"))
    end
end
