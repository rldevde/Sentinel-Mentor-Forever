local _, SentinelMentor = ...
local function IsTrainerTaught(profession, name)
    local levels = SentinelMentor_ProfessionData and SentinelMentor_ProfessionData[profession]
    if not levels then return false end
    for _, entries in pairs(levels) do
        if entries[name] then return true end
    end
    return false
end

local function MergeProfessionEntry(target, source)
    for field, value in pairs(source) do
        if target[field] == nil then target[field] = value end
    end
end

local function RelocalizeProfessionData()
    if not SentinelMentor_ProfessionData then return end
    for profession, skillLevels in pairs(SentinelMentor_ProfessionData) do
        local builtinLevels = SentinelMentorDB.professions[profession] and SentinelMentorDB.professions[profession].skills
        for skillReq, bucket in pairs(skillLevels) do
            local renames = {}
            local builtinIcons = {}
            local builtin = builtinLevels and builtinLevels[skillReq]
            if builtin then
                for spellID, data in pairs(builtin) do
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    if spellInfo and spellInfo.name and data.icon then builtinIcons[data.icon] = builtinIcons[data.icon] == nil and spellInfo.name or false end
                end
            end
            for name, entry in pairs(bucket) do
                local localized
                if type(entry) ~= "table" or entry.rankRow then
                    localized = nil
                elseif entry.spellID then
                    local spellInfo = C_Spell.GetSpellInfo(entry.spellID)
                    localized = spellInfo and spellInfo.name
                elseif entry.icon and builtinIcons[entry.icon] and bucket[builtinIcons[entry.icon]] then
                    localized = builtinIcons[entry.icon]
                end
                if localized and localized ~= name then renames[name] = localized end
            end
            for oldName, newName in pairs(renames) do
                local entry = bucket[oldName]
                bucket[oldName] = nil
                if bucket[newName] then
                    MergeProfessionEntry(bucket[newName], entry)
                else
                    bucket[newName] = entry
                end
            end
        end
    end
end

local function PruneToBuiltin(levels, builtinLevels)
    if not levels then return end
    for level, bucket in pairs(levels) do
        local builtin = builtinLevels[level]
        if type(bucket) == "table" then
            for spellID in pairs(bucket) do
                if not (builtin and builtin[spellID]) then bucket[spellID] = nil end
            end
            if next(bucket) == nil then levels[level] = nil end
        end
    end
end

function SentinelMentor:UsesBundledTrainerData(classToken, isPetTraining, professionKey)
    if SentinelMentor.DebugTrainerEnabled then return false end
    if professionKey then return SentinelMentorDB.professions[professionKey] ~= nil end
    if isPetTraining then return classToken == "HUNTER" and SentinelMentorDB.hunterPet ~= nil end
    return SentinelMentorDB.classes[classToken] ~= nil
end

function SentinelMentor:UsesBundledPetData(pet)
    if SentinelMentor.DebugTrainerEnabled then return false end
    return SentinelMentorDB.warlockPets[pet] ~= nil
end

function SentinelMentor:MergeBuiltinData()
    RelocalizeProfessionData()
    if SentinelMentorDB.classes then
        for class, levels in pairs(SentinelMentorDB.classes) do
            PruneToBuiltin(SentinelMentor_Data[class], levels)
            for level, spells in pairs(levels) do
                local bucket = SentinelMentor:EnsurePath(class, level)
                for spellID, data in pairs(spells) do
                    if bucket[spellID] == nil then
                        bucket[spellID] = {
                            cost = data.cost or 0,
                            rank = data.rank,
                            requires = data.requires,
                            faction = data.faction,
                            race = data.race
                        }
                    else
                        if data.cost then bucket[spellID].cost = data.cost end
                        if data.requires then bucket[spellID].requires = data.requires end
                        if data.faction and bucket[spellID].faction == nil then bucket[spellID].faction = data.faction end
                        if data.race and bucket[spellID].race == nil then bucket[spellID].race = data.race end
                    end
                    if data.cost and data.cost > 0 then
                        bucket[spellID].baseCost = data.cost
                        bucket[spellID].baseCostEstimated = nil
                    end
                end
            end
        end
    end

    if SentinelMentorDB.warlockPets then
        for pet, levels in pairs(SentinelMentorDB.warlockPets) do
            PruneToBuiltin(SentinelMentor_PetData[pet], levels)
            for level, spells in pairs(levels) do
                local bucket = SentinelMentor:EnsurePetPath(pet, level)
                for spellID, data in pairs(spells) do
                    if bucket[spellID] == nil then
                        bucket[spellID] = {
                            cost = data.cost or 0,
                            rank = data.rank,
                            faction = data.faction
                        }
                    else
                        if data.cost then bucket[spellID].cost = data.cost end
                        if data.faction and bucket[spellID].faction == nil then bucket[spellID].faction = data.faction end
                    end
                end
            end
        end
    end

    if SentinelMentorDB.hunterPet then
        PruneToBuiltin(SentinelMentor_PetTrainerData.HUNTER, SentinelMentorDB.hunterPet)
        for level, spells in pairs(SentinelMentorDB.hunterPet) do
            local bucket = SentinelMentor:EnsurePetTrainerPath("HUNTER", level)
            for spellID, data in pairs(spells) do
                if bucket[spellID] == nil then
                    bucket[spellID] = {
                        cost = data.cost or 0,
                        rank = data.rank,
                        faction = data.faction
                    }
                else
                    if data.cost then bucket[spellID].cost = data.cost end
                    if data.faction and bucket[spellID].faction == nil then bucket[spellID].faction = data.faction end
                end
            end
        end
    end

    for profession, pdata in pairs(SentinelMentorDB.professions) do
            for skillReq, recipes in pairs(pdata.skills or {}) do
                local bucket = SentinelMentor:EnsureProfessionPath(profession, skillReq)
                for spellID, data in pairs(recipes) do
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    local name = spellInfo and spellInfo.name
                    if name then
                        if bucket[name] == nil then
                            bucket[name] = {
                                cost = data.cost or 0,
                                spellID = spellID,
                                icon = data.icon,
                                requires = data.requires,
                                faction = data.faction
                            }
                        else
                            if data.cost then bucket[name].cost = data.cost end
                            if bucket[name].spellID == nil then bucket[name].spellID = spellID end
                            if data.icon and bucket[name].icon == nil then bucket[name].icon = data.icon end
                            if data.requires and bucket[name].requires == nil then bucket[name].requires = data.requires end
                            if data.faction and bucket[name].faction == nil then bucket[name].faction = data.faction end
                        end
                    end
                end
            end
        end

    for profession, pdata in pairs(SentinelMentorDB.professions) do
            for skillReq, recipes in pairs(pdata.recipes or {}) do
                local bucket = SentinelMentor:EnsureRecipePath(profession, skillReq)
                for spellID, data in pairs(recipes) do
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    local name = spellInfo and spellInfo.name
                    if name and not IsTrainerTaught(profession, name) then
                        if bucket[name] == nil then
                            bucket[name] = {
                                spellID = spellID,
                                icon = data.icon,
                                requires = data.requires,
                                faction = data.faction,
                                source = data.source,
                                sourceLocations = data.sourceLocations
                            }
                        else
                            if bucket[name].spellID == nil then bucket[name].spellID = spellID end
                            if data.icon and bucket[name].icon == nil then bucket[name].icon = data.icon end
                            if data.requires and bucket[name].requires == nil then bucket[name].requires = data.requires end
                            if data.faction and bucket[name].faction == nil then bucket[name].faction = data.faction end
                            if data.source and bucket[name].source == nil then bucket[name].source = data.source end
                            if data.sourceLocations and bucket[name].sourceLocations == nil then bucket[name].sourceLocations = data.sourceLocations end
                        end
                    end
                end
            end
        end
end
