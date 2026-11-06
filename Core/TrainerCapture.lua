local _, SentinelMentor = ...
local function ResolveTalentSpellIDByName(name)
    if not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo or not GetTalentLink then return nil end
    for tab = 1, GetNumTalentTabs() do
        for i = 1, GetNumTalents(tab) do
            local talentName = GetTalentInfo(tab, i)
            if talentName == name then
                local link = GetTalentLink(tab, i)
                if link then
                    local scanTooltip = SentinelMentor.ScanTooltip
                    scanTooltip:ClearLines()
                    scanTooltip:SetHyperlink(link)
                    local spellID = SentinelMentor:GetTooltipSpellID(scanTooltip)
                    if SentinelMentor:IsSaneSpellID(spellID) then return spellID end
                end
                return nil
            end
        end
    end
end

local function ResolveRequirementSpellID(name)
    local _, _, _, _, _, _, spellID = SentinelMentor:GetSpellInfo(name)
    if SentinelMentor:IsSaneSpellID(spellID) then return spellID end
    spellID = ResolveTalentSpellIDByName(name)
    if SentinelMentor:IsSaneSpellID(spellID) then return spellID end
    local baseName = name:match("^(.-)%s*%b()$")
    if baseName then
        _, _, _, _, _, _, spellID = SentinelMentor:GetSpellInfo(baseName)
        if SentinelMentor:IsSaneSpellID(spellID) then return spellID end
        spellID = ResolveTalentSpellIDByName(baseName)
        if SentinelMentor:IsSaneSpellID(spellID) then return spellID end
    end
end

local function ParseRequirementText(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local colonPos = text:find(":")
    local reqText = colonPos and text:sub(colonPos + 1) or text
    local spellIDs = {}
    for part in reqText:gmatch("[^,]+") do
        part = part:match("^%s*(.-)%s*$")
        if part ~= "" then
            local spellID = ResolveRequirementSpellID(part)
            if spellID then table.insert(spellIDs, spellID) end
        end
    end

    if #spellIDs == 0 then return nil end
    return spellIDs
end

local function ReadRequirementsFromAPI(i)
    if not GetTrainerServiceNumAbilityReq or not GetTrainerServiceAbilityReq then return nil end
    local spellIDs = {}
    for r = 1, GetTrainerServiceNumAbilityReq(i) or 0 do
        local ability = GetTrainerServiceAbilityReq(i, r)
        local spellID = ability and ResolveRequirementSpellID(ability)
        if spellID then table.insert(spellIDs, spellID) end
    end

    if #spellIDs == 0 then return nil end
    return spellIDs
end

local function AddSeen(seen, value)
    if not value then return seen end
    seen = seen or {}
    seen[value] = true
    return seen
end

local function IsNonClassTrainer(numServices)
    for i = 1, numServices do
        local spellID = SentinelMentor:GetSpellIDForService(i)
        if SentinelMentor:IsRidingSpell(spellID) or SentinelMentor:IsWeaponSkillSpell(spellID) then return true end
    end
    return false
end

local function GetTrainerNPCID()
    local guid = UnitGUID and UnitGUID("npc")
    if type(guid) ~= "string" then return nil end
    return tonumber(guid:match("^[^-]+%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-(%d+)"))
end

local function IsListedClassTrainer(classToken)
    if not SentinelMentorDB.trainers.class then return nil end
    local npcID = GetTrainerNPCID()
    if not npcID then return false end
    for _, trainer in ipairs(SentinelMentorDB.trainers.class[classToken] or {}) do
        if trainer.npcID == npcID then return true end
    end
    return false
end

local function TrainerTitleMatchesClass(className)
    if not C_TooltipInfo or not C_TooltipInfo.GetUnit or not className then return false end
    local ok, data = pcall(C_TooltipInfo.GetUnit, "npc")
    if not ok or not data or not data.lines then return false end
    for i = 2, #data.lines do
        local text = data.lines[i].leftText
        if type(text) == "string" and text:find(className, 1, true) then return true end
    end
    return false
end

local function IsCurrentClassTrainer(className, classToken)
    local listed = IsListedClassTrainer(classToken)
    if listed == nil then return true end
    return listed or TrainerTitleMatchesClass(className)
end

local function IsPetTrainer(numServices)
    for i = 1, numServices do
        local skillLine = GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(i)
        if SentinelMentor:IsPetTrainerSkillLine(skillLine) then return true end
    end
    return false
end

local function CaptureTrainerInner()
    local className, classToken = UnitClass("player")
    local isTradeskill = IsTradeskillTrainer and IsTradeskillTrainer()
    local professionKey, professionSkillLine
    if isTradeskill then professionKey, professionSkillLine = SentinelMentor:DetectTrainerProfession() end
    SentinelMentor:DebugTrainer("CaptureTrainerInner: npcName=%s npcGUID=%s classToken=%s isTradeskill=%s professionKey=%s professionSkillLine=%s", tostring(UnitName("npc")), tostring(UnitGUID and UnitGUID("npc")), tostring(classToken), tostring(isTradeskill), tostring(professionKey), tostring(professionSkillLine))
    if not classToken then
        SentinelMentor:MSG("UnitClass(\"player\") lieferte keinen Klassen-Token.")
        return
    end

    if not GetNumTrainerServices then
        SentinelMentor:ERR(SentinelMentor:Trans("LID_NOTRAINERAPI"))
        return
    end

    SentinelMentor:ExpandAllTrainerHeaders()
    local numServices = GetNumTrainerServices()
    SentinelMentor:DebugTrainer("CaptureTrainerInner: numServices=%d", numServices)
    if IsNonClassTrainer(numServices) then
        SentinelMentor:DebugTrainer("CaptureTrainerInner: riding or weapon trainer ignored")
        return
    end
    if not professionKey and not IsPetTrainer(numServices) and not IsCurrentClassTrainer(className, classToken) then
        SentinelMentor:DebugTrainer("CaptureTrainerInner: trainer does not match player class")
        return
    end
    local neu = 0
    local neuPet = 0
    local neuProf = 0
    local rankFound = false
    local lastDebugSkillLine
    local readRequirementsFromAPI = _G["ClassTrainerSkill1"] == nil
    local isPetTrainer = C_Trainer and C_Trainer.GetTrainerType and Enum.TrainerType and Enum.TrainerType.Pet ~= nil and C_Trainer.GetTrainerType() == Enum.TrainerType.Pet
    local playerFaction = SentinelMentor:GetPlayerFaction()
    local playerRace = SentinelMentor:GetPlayerRace()
    for i = 1, numServices do
        local _, _, sType = SentinelMentor:GetTrainerServiceInfo(i)
        if sType == "available" or sType == "unavailable" or sType == "used" then
            rankFound = true
            break
        end
    end

    SentinelMentor:DebugTrainer("CaptureTrainerInner: rankFound=%s", tostring(rankFound))
    if not rankFound then return end
    if professionKey and SentinelMentor:UsesBundledTrainerData(classToken, false, professionKey) then return end
    for i = 1, numServices do
        local name, rankText, sType, levelReq, icon = SentinelMentor:GetTrainerServiceInfo(i)
        local rank = rankText and tonumber(rankText:match("%d+"))
        if (rank ~= nil or levelReq ~= nil) and (sType == "available" or sType == "unavailable" or sType == "used") then
            local cost, isProfessionService = 0
            if GetTrainerServiceCost then cost, isProfessionService = GetTrainerServiceCost(i) end
            cost = cost or 0
            local skillLine = GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(i)
            if name and professionKey then
                local spellID = SentinelMentor:GetSpellIDForService(i)
                local skillReq = SentinelMentor:GetSkillReqForService(i)
                local bucket = SentinelMentor:EnsureProfessionPath(professionKey, skillReq)
                local existing = bucket[name]
                local baseCost, baseCostEstimated = SentinelMentor.Pricing.CaptureBaseCost(cost, existing)
                if existing == nil then neuProf = neuProf + 1 end
                local requires = existing and existing.requires
                if readRequirementsFromAPI then requires = ReadRequirementsFromAPI(i) or requires end
                bucket[name] = {
                    spellID = spellID,
                    rankRow = (isProfessionService == true) or (GetTrainerServiceStepIndex and GetTrainerServiceStepIndex() == i) or (existing and existing.rankRow) or nil,
                    icon = icon,
                    cost = cost,
                    baseCost = baseCost,
                    baseCostEstimated = baseCostEstimated,
                    rank = rank,
                    status = sType,
                    levelReq = (levelReq and levelReq > 0) and levelReq or nil,
                    requires = requires,
                    faction = existing and existing.faction,
                    race = existing and existing.race,
                    seenFactions = AddSeen(existing and existing.seenFactions, playerFaction),
                    seenRaces = AddSeen(existing and existing.seenRaces, playerRace)
                }
            else
                local spellID = SentinelMentor:GetSpellIDForService(i)
                local isPetTraining = isPetTrainer or SentinelMentor:IsPetTrainerSkillLine(skillLine)
                if spellID and not SentinelMentor:UsesBundledTrainerData(classToken, isPetTraining) then
                    if not levelReq or levelReq == 0 then levelReq = SentinelMentor:GetSpellLevelLearned(spellID) or levelReq end
                    if skillLine ~= lastDebugSkillLine then
                        lastDebugSkillLine = skillLine
                        SentinelMentor:DebugTrainer("CaptureTrainerInner: skillLine=%s isPetTraining=%s classToken=%s", tostring(skillLine), tostring(isPetTraining), tostring(classToken))
                    end

                    if isPetTraining then
                        local oldBucket = SentinelMentor_Data[classToken] and SentinelMentor_Data[classToken][levelReq or 0]
                        if oldBucket then oldBucket[spellID] = nil end
                    end

                    local bucket = isPetTraining and SentinelMentor:EnsurePetTrainerPath(classToken, levelReq or 0) or SentinelMentor:EnsurePath(classToken, levelReq or 0)
                    local existing = bucket[spellID]
                    local baseCost, baseCostEstimated
                    if not isPetTraining then baseCost, baseCostEstimated = SentinelMentor.Pricing.CaptureBaseCost(cost, existing) end
                    if existing == nil then
                        if isPetTraining then
                            neuPet = neuPet + 1
                        else
                            neu = neu + 1
                        end
                    end

                    local requires = existing and existing.requires
                    if readRequirementsFromAPI then requires = ReadRequirementsFromAPI(i) or requires end
                    bucket[spellID] = {
                        cost = cost,
                        baseCost = baseCost,
                        baseCostEstimated = baseCostEstimated,
                        rank = rank,
                        status = sType,
                        requires = requires,
                        faction = existing and existing.faction,
                        race = existing and existing.race,
                        seenFactions = AddSeen(existing and existing.seenFactions, playerFaction),
                        seenRaces = AddSeen(existing and existing.seenRaces, playerRace)
                    }
                end
            end
        end
    end

    if SentinelMentor.DebugTrainerEnabled then
        if neu > 0 then SentinelMentor:MSG("|cff33ff99SentinelMentor:|r " .. SentinelMentor:Trans("LID_NEWSPELLS"):format(neu, classToken)) end
        if neuPet > 0 then SentinelMentor:MSG("|cff33ff99SentinelMentor:|r " .. SentinelMentor:Trans("LID_NEWPETTRAINERSKILLS"):format(neuPet, classToken)) end
        if neuProf > 0 then SentinelMentor:MSG("|cff33ff99SentinelMentor:|r " .. SentinelMentor:Trans("LID_NEWRECIPES"):format(neuProf, professionSkillLine or SentinelMentor:Trans("LID_PROFESSION"))) end
    end
end

function SentinelMentor:CaptureTrainer()
    local ok, err = pcall(CaptureTrainerInner)
    if not ok then SentinelMentor:ERR("|cffff5555SentinelMentor Fehler:|r " .. tostring(err)) end
end

local function OnTrainerServiceSelectedInner(id)
    local _, classToken = UnitClass("player")
    if not classToken or not id then return end
    local fs = _G["ClassTrainerSkillRequirements"]
    local text = fs and fs:GetText()
    local requires = text and ParseRequirementText(text)
    if not requires then return end
    local isTradeskill = IsTradeskillTrainer and IsTradeskillTrainer()
    local professionKey
    if isTradeskill then professionKey = SentinelMentor:DetectTrainerProfession() end
    local bucket, key
    if professionKey then
        if SentinelMentor:UsesBundledTrainerData(classToken, false, professionKey) then return end
        local name = GetTrainerServiceInfo(id)
        local skillReq = SentinelMentor:GetSkillReqForService(id)
        local profession = SentinelMentor_ProfessionData[professionKey]
        bucket = profession and profession[skillReq]
        key = name
    else
        local spellID = SentinelMentor:GetSpellIDForService(id)
        if not spellID then return end
        local skillLine = GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(id)
        local levelReq = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(id) or 0
        local isPetTraining = SentinelMentor:IsPetTrainerSkillLine(skillLine)
        if SentinelMentor:UsesBundledTrainerData(classToken, isPetTraining) then return end
        local levels = isPetTraining and SentinelMentor_PetTrainerData[classToken] or SentinelMentor_Data[classToken]
        bucket = levels and levels[levelReq]
        key = spellID
    end

    if bucket and key and bucket[key] then
        bucket[key].requires = requires
        if SentinelMentor_Refresh then SentinelMentor_Refresh() end
        if SentinelMentor_ProfessionRefresh then SentinelMentor_ProfessionRefresh() end
    end
end

local function OnTrainerServiceButtonClicked(self)
    local id = self:GetID()
    local ok, err = pcall(OnTrainerServiceSelectedInner, id)
    if not ok then SentinelMentor:MSG("|cffff5555SentinelMentor Fehler:|r " .. tostring(err)) end
end

local hookedTrainerButtons = {}
function SentinelMentor:CaptureTrainerRequirements()
    local i = 1
    while _G["ClassTrainerSkill" .. i] do
        local button = _G["ClassTrainerSkill" .. i]
        if not hookedTrainerButtons[button] then
            hookedTrainerButtons[button] = true
            button:HookScript("OnClick", OnTrainerServiceButtonClicked)
        end

        i = i + 1
    end
end
