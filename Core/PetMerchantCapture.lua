local _, SentinelMentor = ...
local function DetectPetFromTooltip(tooltip)
    for i = 1, tooltip:NumLines() do
        local fs = _G[tooltip:GetName() .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        local petWord = text and text:match("Teaches%s+(%S+)") or text and text:match("Lehrt%s+(%S+)")
        if petWord then
            for _, pet in pairs(SentinelMentor.PetNames) do
                if petWord:lower() == pet:lower() then return pet end
            end
        end
    end
end

local GetItemInfoCompat = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local function GetMerchantItemPrice(i)
    if GetMerchantItemInfo then
        local _, _, price = GetMerchantItemInfo(i)
        return price
    end

    local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(i)
    return info and info.price
end

local function CaptureMerchantInner()
    if not GetMerchantNumItems or not GetItemInfoCompat then return end
    local numItems = GetMerchantNumItems()
    local neu = 0
    local scanTooltip = SentinelMentor.ScanTooltip
    for i = 1, numItems do
        local itemLink = GetMerchantItemLink(i)
        if itemLink then
            local itemName, _, _, _, itemMinLevel = GetItemInfoCompat(itemLink)
            if itemMinLevel then
                scanTooltip:ClearLines()
                scanTooltip:SetMerchantItem(i)
                local pet = DetectPetFromTooltip(scanTooltip)
                if pet and not SentinelMentor:UsesBundledPetData(pet) then
                    local spellID = SentinelMentor:GetTooltipSpellID(scanTooltip)
                    if SentinelMentor:IsSaneSpellID(spellID) then
                        local price = GetMerchantItemPrice(i)
                        local rankNum = itemName and tonumber(itemName:match("%(.-(%d+)%)"))
                        local bucket = SentinelMentor:EnsurePetPath(pet, itemMinLevel)
                        if bucket[spellID] == nil then neu = neu + 1 end
                        bucket[spellID] = {
                            cost = price or 0,
                            rank = rankNum,
                        }
                    end
                end
            end
        end
    end

    if neu > 0 then SentinelMentor:MSG("|cff33ff99SentinelMentor:|r " .. SentinelMentor:Trans("LID_NEWPETSKILLS"):format(neu)) end
end

function SentinelMentor:CaptureMerchant()
    local ok, err = pcall(CaptureMerchantInner)
    if not ok then SentinelMentor:MSG("|cffff5555SentinelMentor Fehler:|r " .. tostring(err)) end
end

function SentinelMentor:IsPetSpellKnown(spellID, pet)
    if spellID == nil then return nil end
    spellID = tonumber(spellID)
    if pet and SentinelMentor_Character and SentinelMentor_Character.learnedSpellsPet and SentinelMentor_Character.learnedSpellsPet[pet] and SentinelMentor_Character.learnedSpellsPet[pet][spellID] ~= nil then return SentinelMentor_Character.learnedSpellsPet[pet][spellID] end
    if SentinelMentor_Character and SentinelMentor_Character.learnedSpellsPet then
        for i, data in pairs(SentinelMentor_Character.learnedSpellsPet) do
            if data[spellID] ~= nil then return data[spellID] end
        end
    end
    return nil
end

local function FindPetSpellIDByNameAndRank(pet, spellName, rankNum)
    if not spellName then return nil end
    local levels = SentinelMentor_PetData and SentinelMentor_PetData[pet]
    if not levels then return nil end
    for _, spells in pairs(levels) do
        for spellID, data in pairs(spells) do
            local name = SentinelMentor:GetSpellInfo(spellID)
            local rank = (GetSpellSubtext or C_Spell.GetSpellSubtext)(spellID)
            local dbRankNum = rank and tonumber(rank:match("%d+"))
            if name == spellName then
                if dbRankNum and rankNum then
                    if dbRankNum == rankNum then return spellID end
                else
                    return spellID
                end
            end
        end
    end
end

local function OnTooltipSetItem(self)
    local pet = DetectPetFromTooltip(self)
    local family = UnitCreatureFamily("pet")
    if not pet then return end
    local itemName, itemLink = self:GetItem()
    local rankNum = itemName and tonumber(itemName:match("%(.-(%d+)%)"))
    local spellName = itemLink and C_Item and C_Item.GetItemSpell(itemLink)
    local spellID = FindPetSpellIDByNameAndRank(pet, spellName, rankNum)
    if not spellID then return end
    local isPetSpellKnown = SentinelMentor:IsPetSpellKnown(spellID, family)
    if isPetSpellKnown == true then
        if pet ~= family then self:AddLine(SentinelMentor:Trans("LID_ALREADYKNOWN"), 0.9, 0.2, 0.2) end
    elseif isPetSpellKnown == false then
        self:AddLine(SentinelMentor:Trans("LID_NOTLEARNEDYET"), 0.2, 0.9, 0.2)
    else
        self:AddLine(SentinelMentor:Trans("LID_NOTSCANNEDYET"), 0.9, 0.9, 0.2)
    end

    self:Show()
end

if GameTooltip:HasScript("OnTooltipSetItem") then GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem) end

local function MarkKnownPetSpells(pet, dataTable)
    if not UnitExists("pet") then return end
    local health = UnitHealth("pet")
    if SentinelMentor:IsSecret(health) or health <= 0 then return end
    local petSpells = {}
    local i = 1
    while true do
        local name, rank = GetSpellBookItemName(i, BOOKTYPE_PET)
        if not name then break end
        local rankNum = rank and tonumber(rank:match("%d+"))
        petSpells[name] = math.max(petSpells[name] or 0, rankNum or 1)
        i = i + 1
    end

    SentinelMentor_Character.learnedSpellsPet[pet] = SentinelMentor_Character.learnedSpellsPet[pet] or {}
    local changed = false
    for _, spells in pairs(dataTable) do
        for spellID, data in pairs(spells) do
            spellID = tonumber(spellID)
            local info = C_Spell.GetSpellInfo(spellID)
            local name = info and info.name
            local rankNum = type(data) == "table" and tonumber(data.rank)
            local maxKnown = name and petSpells[name]
            if not maxKnown then
                SentinelMentor_Character.learnedSpellsPet[pet][spellID] = false
                changed = true
            elseif rankNum then
                SentinelMentor_Character.learnedSpellsPet[pet][spellID] = rankNum <= maxKnown
                changed = true
            end
        end
    end
    return changed
end

function SentinelMentor:SyncKnownPetSpellsForActivePet()
    if not GetSpellInfo or not UnitCreatureFamily then return end
    local family = UnitCreatureFamily("pet")
    local petData = family and SentinelMentor_PetData[family]
    if not petData then return end
    local changed = MarkKnownPetSpells(family, petData)
    if changed and SentinelMentor_Refresh then SentinelMentor_Refresh() end
end
