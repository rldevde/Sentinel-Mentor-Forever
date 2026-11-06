local ADDON_NAME, SM = ...
SM.DJ = SM.DJ or {}
local SMJ = SM.DJ
SMJ = SMJ or SM.DJ
if not SMJ or not SMJ.DB then return end

-- Shared boss loot: items with a small chance to drop from many bosses across
-- several dungeons. They are kept out of the bosses' own loot lists; a boss
-- that can drop any of them gets a folded "Show Shared Loot (N)" divider below
-- its loot (see RefreshLoot in Core/Journal.lua).
local BFD, STOCKS, RFK, SMGY = "Blackfathom Deeps", "The Stockade", "Razorfen Kraul", "Scarlet Monastery: Graveyard"

local SHARED = {
    { 252512, "Brawler's Leather Helm", {
        [BFD] = { "Gelihast", "Aku'mai", "Lorgus Jett" },
        [STOCKS] = { "Kam Deepfury", "Dextren Ward" },
        [RFK] = { "Aggem Thorncurse", "Death Speaker Jargba", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank", "Roogug" },
        [SMGY] = { "Azshir the Sleepless" },
    } },
    { 252513, "Trapper's Leather Helm", {
        [BFD] = { "Gelihast", "Twilight Lord Kelris", "Lorgus Jett" },
        [STOCKS] = { "Kam Deepfury", "Hamhock" },
        [RFK] = { "Overlord Ramtusk", "Agathelos the Raging" },
        [SMGY] = { "Interrogator Vishas", "Bloodmage Thalnos" },
    } },
    { 252455, "Defender's Leather Helm", {
        [BFD] = { "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai", "Lorgus Jett" },
        [STOCKS] = { "Kam Deepfury", "Bazil Thredd" },
        [RFK] = { "Aggem Thorncurse", "Agathelos the Raging", "Charlga Razorflank", "Earthcaller Halmgar" },
        [SMGY] = { "Interrogator Vishas", "Bloodmage Thalnos" },
    } },
    { 252456, "Totemic Leather Helm", {
        [BFD] = { "Gelihast", "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai" },
        [STOCKS] = { "Bazil Thredd", "Dextren Ward" },
        [RFK] = { "Charlga Razorflank" },
        [SMGY] = { "Azshir the Sleepless" },
    } },
    { 252514, "Stormrider's Leather Helm", {
        [BFD] = { "Gelihast", "Aku'mai" },
        [STOCKS] = { "Dextren Ward" },
        [RFK] = { "Earthcaller Halmgar" },
    } },
    { 252515, "Wisdom's Leather Helm", {
        [BFD] = { "Gelihast", "Twilight Lord Kelris", "Aku'mai" },
        [STOCKS] = { "Kam Deepfury", "Bazil Thredd", "Dextren Ward" },
        [RFK] = { "Death Speaker Jargba", "Overlord Ramtusk", "Charlga Razorflank" },
    } },
}

SMJ.SHARED_LOOT_IDS = SMJ.SHARED_LOOT_IDS or {}
SMJ.SHARED_BY_BOSS = SMJ.SHARED_BY_BOSS or {} -- [dungeon][boss name] = { items }
SMJ.sharedLootMissing = {} -- "Dungeon / Boss" entries that were not found

local function FindBoss(dungeon, bossName)
    for _, boss in ipairs(dungeon.bosses or {}) do
        if type(boss) == "table" and boss.name == bossName then return boss end
    end
    return nil
end

local function AddShared(dungeonName, bossName, item)
    local byBoss = SMJ.SHARED_BY_BOSS[dungeonName] or {}
    SMJ.SHARED_BY_BOSS[dungeonName] = byBoss
    local list = byBoss[bossName] or {}
    byBoss[bossName] = list
    for _, existing in ipairs(list) do
        if tonumber(existing[1]) == tonumber(item[1]) then return end
    end
    list[#list + 1] = item
end

for _, entry in ipairs(SHARED) do
    SMJ.SHARED_LOOT_IDS[entry[1]] = true
end

-- Shared items already written into a boss's own loot move to its shared list.
for dungeonName, dungeon in pairs(SMJ.DB) do
    for _, boss in ipairs(dungeon.bosses or {}) do
        if type(boss) == "table" and type(boss.loot) == "table" and not boss.trash and not boss.recipeTab then
            for i = #boss.loot, 1, -1 do
                local item = boss.loot[i]
                if SMJ.SHARED_LOOT_IDS[tonumber(item[1]) or 0] then
                    table.remove(boss.loot, i)
                    AddShared(dungeonName, boss.name, item)
                end
            end
        end
    end
end

for _, entry in ipairs(SHARED) do
    local itemID, itemName, drops = entry[1], entry[2], entry[3]
    for dungeonName, bosses in pairs(drops) do
        local dungeon = SMJ.DB[dungeonName]
        for _, bossName in ipairs(bosses) do
            if dungeon and FindBoss(dungeon, bossName) then
                AddShared(dungeonName, bossName, { itemID, itemName, "Head, Leather", 3 })
            else
                SMJ.sharedLootMissing[#SMJ.sharedLootMissing + 1] = dungeonName .. " / " .. bossName
            end
        end
    end
end

-- Shared loot of a boss on its page (nil when it has none).
function SMJ.GetBossSharedLoot(dungeonName, boss)
    if type(boss) ~= "table" or boss.trash or boss.recipeTab or boss.fdjDungeon then return nil end
    local byBoss = SMJ.SHARED_BY_BOSS[dungeonName]
    local list = byBoss and byBoss[boss.name]
    if list and #list > 0 then return list end
    return nil
end
