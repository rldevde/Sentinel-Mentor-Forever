local _, SentinelMentor = ...
function SentinelMentor:AddHeaderItem(items, text, colorCode, totalCost, groupKey, prefixText, spellCount, headerDepth, countKind)
    local price = type(totalCost) == "table" and totalCost or nil
    if price then totalCost = price.cost end
    table.insert(items, {
        isHeader = true,
        text = text,
        color = colorCode,
        totalCost = totalCost,
        baseCost = price and price.baseCost,
        baseCostEstimated = price and price.baseCostEstimated,
        priceFaction = price and price.priceFaction,
        priceDiscount = price and price.priceDiscount,
        priceEligible = price ~= nil,
        groupKey = groupKey,
        collapsed = SentinelMentor:IsGroupCollapsed(groupKey),
        prefixText = prefixText,
        spellCount = spellCount,
        headerDepth = headerDepth,
        countKind = countKind
    })
end

function SentinelMentor:AddEntryItems(items, list, colorCode, showLevel, showCostTooltip, dimName, levelLabel, rowDepth)
    for _, entry in ipairs(list) do
        table.insert(items, {
            isHeader = false,
            entry = entry,
            color = colorCode,
            showLevel = showLevel,
            showCostTooltip = showCostTooltip,
            dimName = dimName,
            levelLabel = levelLabel,
            rowDepth = rowDepth,
        })
    end
end

function SentinelMentor:SumCost(list)
    local total = 0
    local baseCost, estimated, complete, eligible = 0, false, true, false
    for _, entry in ipairs(list) do
        total = total + (entry.cost or 0)
        baseCost = baseCost + (entry.baseCost or 0)
        estimated = estimated or entry.baseCostEstimated
        eligible = eligible or entry.priceEligible
        if entry.baseCost == nil then complete = false end
    end
    if not eligible then return total end
    local discount, factionName = SentinelMentor.Pricing.GetBestDiscount()
    return {cost = total, baseCost = complete and baseCost or nil, baseCostEstimated = estimated, priceFaction = factionName, priceDiscount = discount}
end

function SentinelMentor:AddCostColumn(items)
    local column = {
        costs = {},
        widths = {}
    }

    local seen = {}
    for _, item in ipairs(items) do
        local cost = item.entry and item.showCostTooltip and item.entry.cost
        if item.entry and item.entry.baseCost ~= nil then cost = SentinelMentor.Pricing.Text(item.entry.baseCost, cost, item.entry.baseCostEstimated) end
        if cost and (type(cost) == "string" or cost > 0) and not seen[cost] then
            seen[cost] = true
            table.insert(column.costs, cost)
        end
    end

    if #column.costs == 0 then return end
    for _, item in ipairs(items) do
        if item.entry and item.showCostTooltip then item.costColumn = column end
    end
end

local function CountGroupEntries(groups)
    return #groups.available + #groups.soon + #groups.higher + #groups.missingTalents + #groups.ignored + #groups.known
end

local function RaceMatches(race, playerRace)
    if not race or not playerRace then return true end
    if type(race) ~= "table" then return race == playerRace end
    for _, raceToken in ipairs(race) do
        if raceToken == playerRace then return true end
    end

    return false
end

local function GetSourceLocations(locations, playerFaction)
    if type(locations) ~= "table" then return nil end
    local result = {}
    for _, location in ipairs(locations) do
        if not location.faction or not playerFaction or location.faction == playerFaction then table.insert(result, location) end
    end
    return #result > 0 and result or nil
end

function SentinelMentor:BuildEntriesFromData(dataTable)
    local allEntries = {}
    local knownMaxRank = {}
    local playerFaction = SentinelMentor:GetPlayerFaction()
    local playerRace = SentinelMentor:GetPlayerRace()
    local discount, factionName = SentinelMentor.Pricing.GetBestDiscount()
    local classToken = select(2, UnitClass("player"))
    local priceEligible = SentinelMentor_Data and dataTable == SentinelMentor_Data[classToken]
    for _, professionData in pairs(SentinelMentor_ProfessionData or {}) do
        if dataTable == professionData then priceEligible = true; break end
    end
    for lvl, spells in pairs(dataTable) do
        for key, data in pairs(spells) do
            local cost, rank, status, requires, faction, race, spellID, icon, levelReq
            local source, sourceLocations
            if type(data) == "table" then
                cost, rank, status, requires, faction, race = data.cost, data.rank, data.status, data.requires, data.faction, data.race
                spellID, icon, levelReq = data.spellID, data.icon, data.levelReq
                source, sourceLocations = data.source, data.sourceLocations
            else
                cost = data
            end

            local raceMatches = RaceMatches(race, playerRace)

            if (not faction or not playerFaction or faction == playerFaction) and raceMatches then
                local name
                if type(key) == "number" then
                    spellID = spellID or key
                    name, _, icon = SentinelMentor:GetSpellInfo(key)
                else
                    name = key
                end

                name = name or ("SpellID " .. tostring(key))
                if not icon and spellID then
                    local _, _, resolvedIcon = SentinelMentor:GetSpellInfo(spellID)
                    icon = resolvedIcon
                end

                icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                local hasRealRank = (type(rank) == "number") or (type(rank) == "string" and rank:match("%d+") ~= nil)
                local rankNum = (type(rank) == "number" and rank) or (type(rank) == "string" and tonumber(rank:match("%d+"))) or 1
                local isLearnedPetSpell = spellID and SentinelMentor:IsPetSpellKnown(spellID)
                local directlyKnown = (spellID and IsPlayerSpell and IsPlayerSpell(spellID)) or isLearnedPetSpell or status == "used"
                local entry = {
                    level = lvl,
                    key = key,
                    spellID = spellID,
                    cost = cost,
                    name = name,
                    icon = icon,
                    rankNum = rankNum,
                    hasRealRank = hasRealRank,
                    directlyKnown = directlyKnown,
                    requires = requires,
                    levelReq = levelReq,
                    source = source,
                    sourceLocations = GetSourceLocations(sourceLocations, playerFaction),
                }

                if priceEligible then SentinelMentor.Pricing.Apply(entry, data, discount, factionName) end

                table.insert(allEntries, entry)
                if directlyKnown and hasRealRank then knownMaxRank[name] = math.max(knownMaxRank[name] or 0, rankNum) end
            end
        end
    end
    return allEntries, knownMaxRank
end

function SentinelMentor:CreateSpoilerFreeCheckbox(parent, settingKey, descKey, onToggle)
    local checkbox = SentinelMentor.Style:Check(parent, SentinelMentor:Trans("LID_SPOILERFREE"))
    checkbox.text = checkbox.label
    checkbox:SetScript("OnShow", function(button) button:SetChecked(SentinelMentor_Character[settingKey] and true or false) end)
    checkbox:SetScript("OnClick", function(button)
        SentinelMentor_Character[settingKey] = button:GetChecked() and true or false
        onToggle()
    end)
    checkbox:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(SentinelMentor:Trans("LID_SPOILERFREE"))
        GameTooltip:AddLine(SentinelMentor:Trans(descKey), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    return checkbox
end

function SentinelMentor:ClassifyEntries(dataTable, searchText, selectedLevel, skipTalentCheck, professionKey)
    local allEntries, knownMaxRank = SentinelMentor:BuildEntriesFromData(dataTable)
    local talentNames, learnedTalents
    if not skipTalentCheck then talentNames, learnedTalents = SentinelMentor:GetTalentNameSet() end
    local ignored, known, remaining = {}, {}, {}
    local spoilerLimit
    if professionKey then
        spoilerLimit = SentinelMentor_Character and SentinelMentor_Character.professionSpoilerFree and selectedLevel + 5
    else
        spoilerLimit = SentinelMentor_Character and SentinelMentor_Character.spoilerFree and selectedLevel + 2
    end
    for _, entry in ipairs(allEntries) do
        if (not spoilerLimit or entry.level <= spoilerLimit) and SentinelMentor:EntryMatchesSearch(entry, searchText) then
            local isIgnored
            if professionKey then
                isIgnored = SentinelMentor_IsProfessionSpellIgnored and SentinelMentor_IsProfessionSpellIgnored(entry.spellID, professionKey)
            else
                isIgnored = SentinelMentor_IsIgnored and SentinelMentor_IsIgnored(entry.spellID, entry.name)
            end

            if isIgnored then
                table.insert(ignored, entry)
            else
                local maxKnown = knownMaxRank[entry.name] or 0
                local isKnown = entry.directlyKnown or (entry.hasRealRank and entry.rankNum <= maxKnown)
                if isKnown then
                    table.insert(known, entry)
                else
                    table.insert(remaining, entry)
                end
            end
        end
    end

    local available, missingTalents, future = {}, {}, {}
    for _, entry in ipairs(remaining) do
        local looksTalentGated = talentNames and ((talentNames[entry.name] and not learnedTalents[entry.name]) or SentinelMentor:RequiresUnknownTalent(entry, talentNames, learnedTalents))
        if looksTalentGated then
            table.insert(missingTalents, entry)
        elseif entry.level > selectedLevel then
            table.insert(future, entry)
        else
            table.insert(available, entry)
        end
    end

    local nextLevel
    for _, entry in ipairs(future) do
        if not nextLevel or entry.level < nextLevel then nextLevel = entry.level end
    end

    local soon, higher = {}, {}
    for _, entry in ipairs(future) do
        if entry.level == nextLevel then
            table.insert(soon, entry)
        else
            table.insert(higher, entry)
        end
    end

    SentinelMentor:SortEntries(available)
    SentinelMentor:SortEntries(missingTalents)
    SentinelMentor:SortEntries(ignored)
    SentinelMentor:SortEntries(soon)
    SentinelMentor:SortEntries(higher)
    SentinelMentor:SortEntries(known)
    return {
        available = available,
        soon = soon,
        higher = higher,
        missingTalents = missingTalents,
        ignored = ignored,
        known = known,
        nextLevel = nextLevel,
    }
end

function SentinelMentor:AppendGroupItems(items, groups, keyPrefix, labelPrefix, unitLabel, showCost, headerDepth, countKind)
    local Colors = SentinelMentor.UIColors
    if showCost == nil then showCost = true end
    local entryLevelLabel = unitLabel and unitLabel ~= SentinelMentor:Trans("LID_LVL") and unitLabel or nil
    unitLabel = unitLabel or SentinelMentor:Trans("LID_LVL")
    if #groups.available > 0 then
        SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_AVAILABLENOW"), Colors.AVAILABLE, showCost and SentinelMentor:SumCost(groups.available) or nil, keyPrefix .. "available", labelPrefix, #groups.available, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "available") then SentinelMentor:AddEntryItems(items, groups.available, Colors.AVAILABLE, true, showCost, false, entryLevelLabel, headerDepth) end
    end

    if #groups.soon > 0 then
        SentinelMentor:AddHeaderItem(items, ("%s (%s %d)"):format(SentinelMentor:Trans("LID_COMINGSOON"), unitLabel, groups.nextLevel), Colors.SOON, showCost and SentinelMentor:SumCost(groups.soon) or nil, keyPrefix .. "soon", labelPrefix, #groups.soon, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "soon") then SentinelMentor:AddEntryItems(items, groups.soon, Colors.SOON, true, showCost, false, entryLevelLabel, headerDepth) end
    end

    if #groups.higher > 0 then
        SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_NOTYETAVAILABLE"), Colors.NOTYET, showCost and SentinelMentor:SumCost(groups.higher) or nil, keyPrefix .. "higher", labelPrefix, #groups.higher, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "higher") then SentinelMentor:AddEntryItems(items, groups.higher, Colors.NOTYET, true, showCost, false, entryLevelLabel, headerDepth) end
    end

    if #groups.missingTalents > 0 then
        SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_MISSINGREQUIREDTALENTS"), Colors.TALENT, showCost and SentinelMentor:SumCost(groups.missingTalents) or nil, keyPrefix .. "missingTalents", labelPrefix, #groups.missingTalents, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "missingTalents") then SentinelMentor:AddEntryItems(items, groups.missingTalents, Colors.TALENT, true, showCost, false, entryLevelLabel, headerDepth) end
    end

    if #groups.ignored > 0 then
        SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_IGNORED"), Colors.IGNORED, nil, keyPrefix .. "ignored", labelPrefix, #groups.ignored, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "ignored") then SentinelMentor:AddEntryItems(items, groups.ignored, Colors.IGNORED, true, showCost, true, entryLevelLabel, headerDepth) end
    end

    if #groups.known > 0 then
        SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_ALREADYKNOWN"), Colors.KNOWN, showCost and SentinelMentor:SumCost(groups.known) or nil, keyPrefix .. "known", labelPrefix, #groups.known, headerDepth, countKind)
        if not SentinelMentor:IsGroupCollapsed(keyPrefix .. "known") then SentinelMentor:AddEntryItems(items, groups.known, Colors.KNOWN, true, showCost, true, entryLevelLabel, headerDepth) end
    end
end

local function MergePetData(keys)
    local merged = {}
    for _, key in ipairs(keys) do
        local data = SentinelMentor_PetData and SentinelMentor_PetData[key]
        if data then
            for lvl, spells in pairs(data) do
                merged[lvl] = merged[lvl] or {}
                for spellID, entryData in pairs(spells) do
                    merged[lvl][spellID] = entryData
                end
            end
        end
    end
    return merged
end

function SentinelMentor:AppendPetAbilities(items, searchText, selectedLevel)
    local Colors = SentinelMentor.UIColors
    for _, petGroup in ipairs(SentinelMentor.PetGroups) do
        local merged = MergePetData(petGroup.keys)
        if next(merged) then
            local groupKey = "pet_" .. table.concat(petGroup.keys, "_")
            local groups = SentinelMentor:ClassifyEntries(merged, searchText, selectedLevel, true)
            local subItems = {}
            SentinelMentor:AppendGroupItems(subItems, groups, groupKey .. "_", nil, nil, nil, 1)
            if #subItems > 0 then
                local groupCount = CountGroupEntries(groups)
                SentinelMentor:AddHeaderItem(items, petGroup.label, Colors.PET_HEADER, nil, groupKey, nil, groupCount)
                if not SentinelMentor:IsGroupCollapsed(groupKey) then
                    for _, item in ipairs(subItems) do
                        table.insert(items, item)
                    end
                end
            end
        end
    end
end

function SentinelMentor:AppendPetTrainerAbilities(items, searchText, selectedLevel, classToken)
    local petTrainerData = SentinelMentor_PetTrainerData and SentinelMentor_PetTrainerData[classToken]
    if not petTrainerData or not next(petTrainerData) then return end
    local groups = SentinelMentor:ClassifyEntries(petTrainerData, searchText, selectedLevel, true)
    SentinelMentor:AppendGroupItems(items, groups, "pettrainer_")
end
