local _, SentinelMentor = ...
SentinelMentor.DebugTrainerEnabled = false
function SentinelMentor:DebugTrainer(fmt, ...)
    if not SentinelMentor.DebugTrainerEnabled then return end
    SentinelMentor:MSG(("|cff3399ffSentinelMentor Debug:|r " .. fmt):format(...))
end

local _, _, _, tocVersion = GetBuildInfo()
local INTERFACE_VERSION = tonumber(tocVersion) or 0
local FIRST_VERSION_WITHOUT_CLASS_TRAINERS = 50000
function SentinelMentor:HasClassTrainers()
    return INTERFACE_VERSION < FIRST_VERSION_WITHOUT_CLASS_TRAINERS
end

SentinelMentor_Data = SentinelMentor_Data or {}
SentinelMentor_Ignored = SentinelMentor_Ignored or {}
SentinelMentor_IgnoredNames = SentinelMentor_IgnoredNames or {}
SentinelMentor_IgnoredProfessions = SentinelMentor_IgnoredProfessions or {}
SentinelMentor_Character = SentinelMentor_Character or {}
SentinelMentor_Character.collapsedGroups = SentinelMentor_Character.collapsedGroups or {}
SentinelMentor_Character.learnedSpellsPet = SentinelMentor_Character.learnedSpellsPet or {}
if SentinelMentor_Character.showIgnoredInTrainer == nil then SentinelMentor_Character.showIgnoredInTrainer = false end
SentinelMentor_Character.rowHeight = SentinelMentor_Character.rowHeight or 32
SentinelMentor_Character.weaponGrouping = SentinelMentor_Character.weaponGrouping or "weapon"
if SentinelMentor_Character.hideLearnedWeaponSkills == nil then SentinelMentor_Character.hideLearnedWeaponSkills = true end
if SentinelMentor_Character.beastHideLearned == nil then SentinelMentor_Character.beastHideLearned = true end
if SentinelMentor_Character.hideStarterClassTrainers == nil then SentinelMentor_Character.hideStarterClassTrainers = false end
SentinelMentor_PetData = SentinelMentor_PetData or {}
SentinelMentor_PetTrainerData = SentinelMentor_PetTrainerData or {}
SentinelMentor_ProfessionData = SentinelMentor_ProfessionData or {}
SentinelMentor_RecipeData = SentinelMentor_RecipeData or {}
SentinelMentor:SetAddonOutput()
local BEAST_TRAINING_SPELL_ID = 5149
local PET_TRAINER_SKILL_LINE = ""
local trainingSpellInfo = C_Spell.GetSpellInfo(BEAST_TRAINING_SPELL_ID)
if trainingSpellInfo and trainingSpellInfo.name then PET_TRAINER_SKILL_LINE = trainingSpellInfo.name end
local PROFESSION_SKILL_LINES = {}
local PROFESSION_NAME_TO_KEY = {}
local PROFESSION_KEY_TO_NAME = {}
local PROFESSION_SPELLS = {
    ["Alchemy"] = 3101,
    ["Archaeology"] = 78670,
    ["Blacksmithing"] = 9785,
    ["Cooking"] = 18260,
    ["Enchanting"] = 7413,
    ["Engineering"] = 4036,
    ["First Aid"] = 7924,
    ["Fishing"] = 7620,
    ["Herbalism"] = 13614,
    ["Inscription"] = 45357,
    ["Leatherworking"] = 10662,
    ["Mining"] = 2575,
    ["Skinning"] = 10768,
    ["Tailoring"] = 3910,
    ["Jewelcrafting"] = 28897,
}

local RIDING_SPELL_IDS = {
    [33388] = true,
    [33391] = true,
    [34090] = true,
    [34091] = true,
    [54197] = true,
    [90265] = true,
    [90266] = true,
    [90267] = true,
}

local WEAPON_SKILL_SPELL_IDS = {
    [196] = true,
    [197] = true,
    [198] = true,
    [199] = true,
    [200] = true,
    [201] = true,
    [202] = true,
    [227] = true,
    [264] = true,
    [266] = true,
    [1180] = true,
    [2567] = true,
    [5011] = true,
    [15590] = true,
}

for key, spellID in pairs(PROFESSION_SPELLS) do
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo and spellInfo.name then
        PROFESSION_SKILL_LINES[spellInfo.name] = true
        PROFESSION_NAME_TO_KEY[spellInfo.name] = key
        PROFESSION_KEY_TO_NAME[key] = spellInfo.name
    end
end

function SentinelMentor:GetProfessionName(key)
    return PROFESSION_KEY_TO_NAME[key]
end

function SentinelMentor:GetProfessionKey(name)
    return PROFESSION_NAME_TO_KEY[name]
end

function SentinelMentor:GetProfessionIcon(key)
    local spellInfo = PROFESSION_SPELLS[key] and C_Spell.GetSpellInfo(PROFESSION_SPELLS[key])
    return spellInfo and spellInfo.iconID
end

function SentinelMentor:DetectTrainerProfession()
    if not GetNumTrainerServices or not GetTrainerServiceSkillLine then return nil end
    for i = 1, GetNumTrainerServices() do
        local skillLine = GetTrainerServiceSkillLine(i)
        if skillLine and PROFESSION_SKILL_LINES[skillLine] then return PROFESSION_NAME_TO_KEY[skillLine] or skillLine, skillLine end
    end
    return nil
end

function SentinelMentor:IsPetTrainerSkillLine(skillLine)
    return skillLine == PET_TRAINER_SKILL_LINE
end

function SentinelMentor:IsRidingSpell(spellID)
    return RIDING_SPELL_IDS[spellID] == true
end

function SentinelMentor:IsWeaponSkillSpell(spellID)
    return WEAPON_SKILL_SPELL_IDS[spellID] == true
end

local function RemoveNonClassSpells(spells)
    if type(spells) ~= "table" then return end
    for spellID in pairs(spells) do
        if SentinelMentor:IsRidingSpell(spellID) or SentinelMentor:IsWeaponSkillSpell(spellID) then spells[spellID] = nil end
    end
end

function SentinelMentor:RemoveNonClassSpellsFromClassData()
    for _, levels in pairs(SentinelMentor_Data) do
        if type(levels) == "table" then
            for _, spells in pairs(levels) do RemoveNonClassSpells(spells) end
        end
    end
end

SentinelMentor.ScanTooltip = CreateFrame("GameTooltip", "SentinelMentorScanTooltip", nil, "GameTooltipTemplate")
SentinelMentor.ScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
function SentinelMentor:IsSaneSpellID(spellID)
    return type(spellID) == "number" and spellID > 0 and spellID < 2000000
end

function SentinelMentor:GetSpellInfo(spell)
    if GetSpellInfo then return GetSpellInfo(spell) end
    if spell == nil or not C_Spell or not C_Spell.GetSpellInfo then return nil end
    local info = C_Spell.GetSpellInfo(spell)
    if not info then return nil end
    local subText = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(info.spellID)
    return info.name, subText, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
end

function SentinelMentor:GetTooltipSpellID(tooltip)
    if tooltip.GetSpell then
        local _, spellID = tooltip:GetSpell()
        return spellID
    end

    if TooltipUtil and TooltipUtil.GetDisplayedSpell then
        local _, spellID = TooltipUtil.GetDisplayedSpell(tooltip)
        return spellID
    end
end

local SERVICE_TYPES = {
    available = true,
    unavailable = true,
    used = true
}

function SentinelMentor:GetTrainerServiceInfo(i)
    local name, second, third, fourth, fifth, category = GetTrainerServiceInfo(i)
    if SERVICE_TYPES[second] then
        local levelReq = fourth or 0
        if levelReq == 0 and GetTrainerServiceLevelReq then levelReq = GetTrainerServiceLevelReq(i) or 0 end
        return name, fifth, second, levelReq, third, category
    end

    local levelReq = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i) or 0
    local icon = GetTrainerServiceIcon and GetTrainerServiceIcon(i)
    return name, second, third, levelReq, icon, nil
end

function SentinelMentor:GetSpellIDForService(i)
    local scanTooltip = SentinelMentor.ScanTooltip
    local spellID
    if scanTooltip.GetSpell then
        scanTooltip:ClearLines()
        scanTooltip:SetTrainerService(i)
        spellID = SentinelMentor:GetTooltipSpellID(scanTooltip)
    elseif C_TooltipInfo and C_TooltipInfo.GetTrainerService then
        local tooltipData = C_TooltipInfo.GetTrainerService(i)
        if tooltipData and tooltipData.type == Enum.TooltipDataType.Spell then spellID = tooltipData.id end
    end

    if not spellID then
        local name = GetTrainerServiceInfo(i)
        if name then
            local _, _, _, _, _, _, foundSpellID = SentinelMentor:GetSpellInfo(name)
            if type(foundSpellID) == "number" and foundSpellID > 0 then spellID = foundSpellID end
        end
    end
    return spellID
end

function SentinelMentor:GetSpellLevelLearned(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellLevelLearned then
        local level = C_Spell.GetSpellLevelLearned(spellID)
        if level and level > 0 then return level end
    end

    if GetSpellLevelLearned then
        local level = GetSpellLevelLearned(spellID)
        if level and level > 0 then return level end
    end
end

function SentinelMentor:GetSkillReqForService(i)
    if not GetTrainerServiceSkillReq then return 0 end
    local _, skillReq = GetTrainerServiceSkillReq(i)
    return skillReq or 0
end

function SentinelMentor:ExpandAllTrainerHeaders()
    if not GetNumTrainerServices or not GetTrainerServiceInfo or not ExpandTrainerSkillLine then return end
    local i = 1
    while i <= GetNumTrainerServices() do
        local _, _, category, expanded = GetTrainerServiceInfo(i)
        if category == "header" and not expanded then ExpandTrainerSkillLine(i) end
        i = i + 1
    end
end

function SentinelMentor:EnsurePath(class, level)
    SentinelMentor_Data[class] = SentinelMentor_Data[class] or {}
    SentinelMentor_Data[class][level] = SentinelMentor_Data[class][level] or {}
    return SentinelMentor_Data[class][level]
end

function SentinelMentor:EnsurePetTrainerPath(class, level)
    SentinelMentor_PetTrainerData[class] = SentinelMentor_PetTrainerData[class] or {}
    SentinelMentor_PetTrainerData[class][level] = SentinelMentor_PetTrainerData[class][level] or {}
    return SentinelMentor_PetTrainerData[class][level]
end

function SentinelMentor:EnsureProfessionPath(profession, skillReq)
    SentinelMentor_ProfessionData[profession] = SentinelMentor_ProfessionData[profession] or {}
    SentinelMentor_ProfessionData[profession][skillReq] = SentinelMentor_ProfessionData[profession][skillReq] or {}
    return SentinelMentor_ProfessionData[profession][skillReq]
end

function SentinelMentor:EnsureRecipePath(profession, skillReq)
    SentinelMentor_RecipeData[profession] = SentinelMentor_RecipeData[profession] or {}
    SentinelMentor_RecipeData[profession][skillReq] = SentinelMentor_RecipeData[profession][skillReq] or {}
    return SentinelMentor_RecipeData[profession][skillReq]
end

function SentinelMentor:EnsurePetPath(pet, level)
    SentinelMentor_PetData[pet] = SentinelMentor_PetData[pet] or {}
    SentinelMentor_PetData[pet][level] = SentinelMentor_PetData[pet][level] or {}
    return SentinelMentor_PetData[pet][level]
end
