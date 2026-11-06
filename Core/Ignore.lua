local _, SentinelMentor = ...
function SentinelMentor_ToggleIgnoreSpell(spellID)
    spellID = tonumber(spellID)
    local _, classToken = UnitClass("player")
    if not classToken or not spellID then return end
    SentinelMentor_Ignored[classToken] = SentinelMentor_Ignored[classToken] or {}
    local ignored = SentinelMentor_Ignored[classToken]
    if ignored[spellID] then
        ignored[spellID] = nil
    else
        ignored[spellID] = true
    end
end

function SentinelMentor_ToggleIgnoreName(name)
    local _, classToken = UnitClass("player")
    if not classToken or not name then return end
    SentinelMentor_IgnoredNames[classToken] = SentinelMentor_IgnoredNames[classToken] or {}
    local ignored = SentinelMentor_IgnoredNames[classToken]
    if ignored[name] then
        ignored[name] = nil
        local ignoredSpells = SentinelMentor_Ignored[classToken]
        if ignoredSpells then
            for spellID in pairs(ignoredSpells) do
                if SentinelMentor:GetSpellInfo(spellID) == name then ignoredSpells[spellID] = nil end
            end
        end
    else
        ignored[name] = true
    end
end

function SentinelMentor_IsSpellIgnored(spellID)
    spellID = tonumber(spellID)
    local _, classToken = UnitClass("player")
    if not classToken or not spellID then return false end
    return SentinelMentor_Ignored[classToken] and SentinelMentor_Ignored[classToken][spellID] or false
end

function SentinelMentor_IsNameIgnored(name)
    local _, classToken = UnitClass("player")
    if not classToken or not name then return false end
    return SentinelMentor_IgnoredNames[classToken] and SentinelMentor_IgnoredNames[classToken][name] or false
end

function SentinelMentor_IsIgnored(spellID, name)
    return SentinelMentor_IsSpellIgnored(spellID) or SentinelMentor_IsNameIgnored(name)
end

function SentinelMentor_IsProfessionSpellIgnored(spellID, professionKey)
    spellID = tonumber(spellID)
    local _, classToken = UnitClass("player")
    if not classToken or not spellID then return false end
    professionKey = professionKey or SentinelMentor:DetectTrainerProfession()
    if not professionKey then return false end
    SentinelMentor_IgnoredProfessions[professionKey] = SentinelMentor_IgnoredProfessions[professionKey] or {}
    local ignored = SentinelMentor_IgnoredProfessions[professionKey]
    return ignored[spellID] or false
end

function SentinelMentor_ToggleIgnoreProfessionSpell(spellID, professionKey)
    spellID = tonumber(spellID)
    local _, classToken = UnitClass("player")
    if not classToken or not spellID then return end
    professionKey = professionKey or SentinelMentor:DetectTrainerProfession()
    if not professionKey then return end
    SentinelMentor_IgnoredProfessions[professionKey] = SentinelMentor_IgnoredProfessions[professionKey] or {}
    local ignored = SentinelMentor_IgnoredProfessions[professionKey]
    if ignored[spellID] then
        ignored[spellID] = nil
    else
        ignored[spellID] = true
    end

    if SentinelMentor_ProfessionRefresh then SentinelMentor_ProfessionRefresh() end
end

function SentinelMentor:MigrateLegacyProfessionIgnores()
    if SentinelMentor_Data.migratedProfessionIgnoresV1 then return end
    SentinelMentor_Data.migratedProfessionIgnoresV1 = true
    local _, classToken = UnitClass("player")
    if not classToken then return end
    local ignoredSpells = SentinelMentor_Ignored[classToken]
    local ignoredNames = SentinelMentor_IgnoredNames[classToken]
    if not ignoredSpells and not ignoredNames then return end
    for _, dataStore in ipairs({SentinelMentor_ProfessionData, SentinelMentor_RecipeData}) do
        for professionKey, byLevel in pairs(dataStore or {}) do
            for _, spells in pairs(byLevel) do
                for key, data in pairs(spells) do
                    local spellID = (type(key) == "number" and key) or (type(data) == "table" and data.spellID)
                    if spellID then
                        local name = SentinelMentor:GetSpellInfo(spellID)
                        local nameIgnored = ignoredNames and name and ignoredNames[name]
                        if (ignoredSpells and ignoredSpells[spellID]) or nameIgnored then
                            SentinelMentor_IgnoredProfessions[professionKey] = SentinelMentor_IgnoredProfessions[professionKey] or {}
                            SentinelMentor_IgnoredProfessions[professionKey][spellID] = true
                            if ignoredSpells then ignoredSpells[spellID] = nil end
                            if nameIgnored then ignoredNames[name] = nil end
                        end
                    end
                end
            end
        end
    end
end
