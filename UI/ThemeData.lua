local ADDON_NAME, SM = ...
SM.DJ = SM.DJ or {}
local SMJ = SM.DJ
SMJ = SMJ or SM.DJ

SMJ.THEMES = {
    ["Shadowfang Keep"] = {
        frame = {0.022, 0.020, 0.028, 0.99},
        content = {0.16, 0.13, 0.18, 0.90},
        border = {0.40, 0.31, 0.48, 1},
        header = {0.18, 0.14, 0.20, 0.94},
        left = {0.12, 0.09, 0.14, 0.94},
        right = {0.13, 0.10, 0.15, 0.94},
        row = {0.095, 0.07, 0.11, 0.92},
        rowSelected = {0.24, 0.15, 0.28, 0.95},
        lootRow = {0.11, 0.08, 0.13, 0.94},
        title = {0.88, 0.78, 0.96},
        text = {0.90, 0.86, 0.93},
        muted = {0.72, 0.67, 0.76},
    },

    ["Wailing Caverns"] = {
        frame = {0.020, 0.028, 0.018, 0.99},
        content = {0.14, 0.20, 0.10, 0.90},
        border = {0.36, 0.44, 0.18, 1},
        header = {0.15, 0.22, 0.10, 0.94},
        left = {0.10, 0.15, 0.07, 0.94},
        right = {0.11, 0.16, 0.08, 0.94},
        row = {0.08, 0.12, 0.06, 0.92},
        rowSelected = {0.22, 0.30, 0.11, 0.95},
        lootRow = {0.10, 0.14, 0.07, 0.94},
        title = {0.94, 0.92, 0.44},
        text = {0.88, 0.91, 0.73},
        muted = {0.70, 0.78, 0.60},
    },

    ["Ragefire Chasm"] = {
        frame = {0.032, 0.021, 0.016, 0.99},
        content = {0.24, 0.12, 0.055, 0.90},
        border = {0.55, 0.30, 0.10, 1},
        header = {0.26, 0.12, 0.045, 0.94},
        left = {0.18, 0.085, 0.035, 0.94},
        right = {0.20, 0.095, 0.040, 0.94},
        row = {0.14, 0.060, 0.026, 0.92},
        rowSelected = {0.39, 0.16, 0.045, 0.95},
        lootRow = {0.17, 0.075, 0.030, 0.94},
        title = {1.00, 0.72, 0.24},
        text = {0.95, 0.82, 0.64},
        muted = {0.82, 0.67, 0.52},
    },

    ["Hall of Thanes"] = {
        frame = {0.030, 0.026, 0.020, 0.99},
        content = {0.24, 0.18, 0.10, 0.90},
        border = {0.52, 0.36, 0.16, 1},
        header = {0.26, 0.18, 0.09, 0.94},
        left = {0.18, 0.12, 0.06, 0.94},
        right = {0.20, 0.14, 0.07, 0.94},
        row = {0.14, 0.09, 0.045, 0.92},
        rowSelected = {0.36, 0.22, 0.08, 0.95},
        lootRow = {0.17, 0.11, 0.06, 0.94},
        title = {1.00, 0.80, 0.34},
        text = {0.93, 0.84, 0.66},
        muted = {0.82, 0.74, 0.60},
    },

    -- Black / grey prison stone.
    ["The Stockade"] = {
        frame = {0.018, 0.018, 0.020, 0.99},
        content = {0.13, 0.13, 0.14, 0.90},
        border = {0.42, 0.42, 0.44, 1},
        header = {0.15, 0.15, 0.16, 0.94},
        left = {0.10, 0.10, 0.11, 0.94},
        right = {0.11, 0.11, 0.12, 0.94},
        row = {0.08, 0.08, 0.085, 0.92},
        rowSelected = {0.25, 0.25, 0.27, 0.95},
        lootRow = {0.10, 0.10, 0.105, 0.94},
        title = {0.92, 0.92, 0.94},
        text = {0.86, 0.86, 0.88},
        muted = {0.66, 0.66, 0.69},
    },

    -- Arcane violet of the Dalaran loading screen.
    ["City of Dalaran"] = {
        frame = {0.024, 0.016, 0.040, 0.99},
        content = {0.17, 0.10, 0.27, 0.90},
        border = {0.58, 0.40, 0.86, 1},
        header = {0.20, 0.11, 0.32, 0.94},
        left = {0.12, 0.07, 0.20, 0.94},
        right = {0.14, 0.08, 0.22, 0.94},
        row = {0.10, 0.055, 0.16, 0.92},
        rowSelected = {0.34, 0.17, 0.52, 0.95},
        lootRow = {0.12, 0.07, 0.19, 0.94},
        title = {0.90, 0.78, 1.00},
        text = {0.91, 0.87, 0.97},
        muted = {0.74, 0.67, 0.84},
    },

    -- Sickly leper-gnome green.
    ["Gnomeregan"] = {
        frame = {0.016, 0.026, 0.018, 0.99},
        content = {0.11, 0.19, 0.12, 0.90},
        border = {0.42, 0.62, 0.32, 1},
        header = {0.12, 0.21, 0.12, 0.94},
        left = {0.08, 0.14, 0.085, 0.94},
        right = {0.09, 0.155, 0.095, 0.94},
        row = {0.065, 0.11, 0.07, 0.92},
        rowSelected = {0.20, 0.34, 0.15, 0.95},
        lootRow = {0.08, 0.13, 0.085, 0.94},
        title = {0.74, 1.00, 0.52},
        text = {0.84, 0.94, 0.80},
        muted = {0.64, 0.76, 0.62},
    },

    ["Ruins of Lordaeron"] = {
        frame = {0.028, 0.029, 0.023, 0.99},
        content = {0.20, 0.18, 0.13, 0.90},
        border = {0.43, 0.41, 0.30, 1},
        header = {0.21, 0.18, 0.13, 0.94},
        left = {0.15, 0.13, 0.10, 0.94},
        right = {0.17, 0.15, 0.11, 0.94},
        row = {0.12, 0.10, 0.08, 0.92},
        rowSelected = {0.23, 0.18, 0.10, 0.95},
        lootRow = {0.14, 0.12, 0.09, 0.94},
        title = {0.83, 0.90, 0.76},
        text = {0.90, 0.88, 0.80},
        muted = {0.73, 0.74, 0.68},
    },

    ["Blackfathom Deeps"] = {
        frame = {0.021, 0.027, 0.030, 0.99},
        content = {0.16, 0.18, 0.18, 0.90},
        border = {0.28, 0.42, 0.46, 1},
        header = {0.15, 0.18, 0.18, 0.94},
        left = {0.11, 0.14, 0.14, 0.94},
        right = {0.12, 0.15, 0.15, 0.94},
        row = {0.09, 0.11, 0.11, 0.92},
        rowSelected = {0.14, 0.22, 0.24, 0.95},
        lootRow = {0.10, 0.13, 0.13, 0.94},
        title = {0.68, 0.90, 0.92},
        text = {0.86, 0.91, 0.91},
        muted = {0.67, 0.77, 0.77},
    },
}

-- Scarlet Monastery: Graveyard shares the Ruins of Lordaeron palette.
SMJ.THEMES["Scarlet Monastery: Graveyard"] = SMJ.THEMES["Ruins of Lordaeron"]

SMJ.DUNGEON_HOME_ART = {
    ["Ragefire Chasm"] = "Interface\\Glues\\LoadingScreens\\LoadScreenRagefireChasm",
    ["Hall of Thanes"] = "Interface\\AddOns\\SentinelMentor\\Media\\HallOfThanes.tga",
    ["Ruins of Lordaeron"] = "Interface\\AddOns\\SentinelMentor\\Media\\RuinsOfLordaeron.tga",
    ["Wailing Caverns"] = "Interface\\Glues\\LoadingScreens\\LoadScreenWailingCaverns",
    ["Shadowfang Keep"] = "Interface\\Glues\\LoadingScreens\\LoadScreenShadowFangKeep",
    ["The Deadmines"] = "Interface\\Glues\\LoadingScreens\\LoadScreenDeadmines",
    ["Blackfathom Deeps"] = "Interface\\Glues\\LoadingScreens\\LoadScreenBlackFathomDeeps",
    ["The Stockade"] = 131870, -- Classic Stormwind Stockade loading screen
    ["Gnomeregan"] = "Interface\\Glues\\LoadingScreens\\LoadScreenGnomeregan",
    ["Razorfen Kraul"] = 131865, -- Classic Razorfen Kraul loading screen
    ["Excavation Site: Wetlands"] = 7963777, -- Forever beta loading screen
    ["City of Dalaran"] = 7963775, -- Forever beta loading screen
    ["Scarlet Monastery: Graveyard"] = "Interface\\Glues\\LoadingScreens\\LoadScreenScarletMonastery2",
}

SMJ.DUNGEON_HOME_TEXCOORD = {
    ["Ragefire Chasm"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Hall of Thanes"] = { 0.03, 0.97, 0.05, 0.95 },
    ["Ruins of Lordaeron"] = { 0.03, 0.97, 0.05, 0.95 },
    ["Wailing Caverns"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Shadowfang Keep"] = { 0.02, 0.98, 0.24, 0.82 },
    ["The Deadmines"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Blackfathom Deeps"] = { 0.02, 0.98, 0.25, 0.82 },
    ["The Stockade"] = { 0.02, 0.98, 0.24, 0.82 },
    ["Gnomeregan"] = { 0.02, 0.98, 0.24, 0.82 },
    ["Razorfen Kraul"] = { 0.02, 0.98, 0.24, 0.82 },
    ["Excavation Site: Wetlands"] = { 0.00, 1.00, 0.12, 0.88 },
    ["City of Dalaran"] = { 0.00, 1.00, 0.12, 0.88 },
    ["Scarlet Monastery: Graveyard"] = { 0.02, 0.98, 0.24, 0.82 },
}

SMJ.DUNGEON_PAGE_ART = {
    ["Ragefire Chasm"] = "Interface\\Glues\\LoadingScreens\\LoadScreenRagefireChasm",
    ["Hall of Thanes"] = "Interface\\AddOns\\SentinelMentor\\Media\\HallOfThanes.tga",
    ["Ruins of Lordaeron"] = "Interface\\AddOns\\SentinelMentor\\Media\\RuinsOfLordaeron.tga",
    ["Wailing Caverns"] = "Interface\\Glues\\LoadingScreens\\LoadScreenWailingCaverns",
    ["Shadowfang Keep"] = "Interface\\Glues\\LoadingScreens\\LoadScreenShadowFangKeep",
    ["The Deadmines"] = "Interface\\Glues\\LoadingScreens\\LoadScreenDeadmines",
    ["Blackfathom Deeps"] = "Interface\\Glues\\LoadingScreens\\LoadScreenBlackFathomDeeps",
}

SMJ.DUNGEON_PAGE_TEXCOORD = {
    ["Ragefire Chasm"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Hall of Thanes"] = { 0.03, 0.97, 0.05, 0.95 },
    ["Ruins of Lordaeron"] = { 0.03, 0.97, 0.05, 0.95 },
    ["Wailing Caverns"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Shadowfang Keep"] = { 0.02, 0.98, 0.24, 0.82 },
    ["The Deadmines"] = { 0.02, 0.98, 0.25, 0.82 },
    ["Blackfathom Deeps"] = { 0.02, 0.98, 0.25, 0.82 },
}

-- The Library keeps the stock loading-screen art; the Graveyard uses its own bundled image.
SMJ.DUNGEON_HOME_ART["Scarlet Monastery: Library"] = "Interface\\AddOns\\SentinelMentor\\Media\\ScarletMonasteryLibraryHome"
SMJ.DUNGEON_HOME_TEXCOORD["Scarlet Monastery: Library"] = { 0, 1, 0.06, 0.94 }
SMJ.DUNGEON_HOME_ART["Scarlet Monastery: Graveyard"] = "Interface\\AddOns\\SentinelMentor\\Media\\ScarletMonasteryGraveyardHome"
SMJ.DUNGEON_HOME_TEXCOORD["Scarlet Monastery: Graveyard"] = { 0, 1, 0.06, 0.94 }

-- Scarlet Monastery: Library reuses the Graveyard look.
for _, tableName in ipairs({ "THEMES", "DUNGEON_HOME_ART", "DUNGEON_HOME_TEXCOORD", "DUNGEON_PAGE_ART", "DUNGEON_PAGE_TEXCOORD" }) do
    local t = SMJ[tableName]
    if type(t) == "table" and t["Scarlet Monastery: Graveyard"] ~= nil and t["Scarlet Monastery: Library"] == nil then
        t["Scarlet Monastery: Library"] = t["Scarlet Monastery: Graveyard"]
    end
end

-- Armory and Cathedral share the Graveyard look; Razorfen Downs the Kraul one.
-- Home-card art: the first loading screen this client actually has.
do
    local function Pick(candidates)
        if not GetFileIDFromPath then return nil end
        for _, path in ipairs(candidates) do
            local ok, id = pcall(GetFileIDFromPath, path)
            if ok and id then return path end
        end
    end
    local SM = { "Interface\\Glues\\LoadingScreens\\LoadScreenScarletMonastery", "Interface\\Glues\\LoadingScreens\\LoadScreenMonastery" }
    local RFD = { "Interface\\Glues\\LoadingScreens\\LoadScreenRazorfenDowns", "Interface\\Glues\\LoadingScreens\\LoadScreenRazorfenDown" }
    local smArt, rfdArt = Pick(SM), Pick(RFD)
    for _, wing in ipairs({ "Scarlet Monastery: Armory", "Scarlet Monastery: Cathedral" }) do
        if smArt then
            SMJ.DUNGEON_HOME_ART[wing] = smArt
            SMJ.DUNGEON_HOME_TEXCOORD[wing] = { 0.02, 0.98, 0.24, 0.82 }
        end
    end
    if rfdArt then
        SMJ.DUNGEON_HOME_ART["Razorfen Downs"] = rfdArt
        SMJ.DUNGEON_HOME_TEXCOORD["Razorfen Downs"] = { 0.02, 0.98, 0.24, 0.82 }
    end
    for _, tableName in ipairs({ "THEMES", "DUNGEON_HOME_ART", "DUNGEON_HOME_TEXCOORD", "DUNGEON_PAGE_ART", "DUNGEON_PAGE_TEXCOORD" }) do
        local t = SMJ[tableName]
        if type(t) == "table" then
            for _, wing in ipairs({ "Scarlet Monastery: Armory", "Scarlet Monastery: Cathedral" }) do
                if t[wing] == nil then t[wing] = t["Scarlet Monastery: Graveyard"] end
            end
            if t["Razorfen Downs"] == nil then t["Razorfen Downs"] = t["Razorfen Kraul"] end
        end
    end
end

-- The Cathedral has its own bundled card art (its loading screen, logo cut off).
SMJ.DUNGEON_HOME_ART["Scarlet Monastery: Cathedral"] = "Interface\\AddOns\\SentinelMentor\\Media\\ScarletMonasteryCathedralHome"
SMJ.DUNGEON_HOME_TEXCOORD["Scarlet Monastery: Cathedral"] = { 0, 1, 0.06, 0.94 }

SMJ.DUNGEON_HOME_ART["Scarlet Monastery: Armory"] = "Interface\\AddOns\\SentinelMentor\\Media\\ScarletMonasteryArmoryHome"
SMJ.DUNGEON_HOME_TEXCOORD["Scarlet Monastery: Armory"] = { 0, 1, 0.06, 0.94 }


-- Bundled card art (the client may not ship these loading screens yet).
for name, file in pairs({ ["Uldaman"] = "UldamanHome", ["Zul'Farrak"] = "ZulFarrakHome", ["Razorfen Downs"] = "RazorfenDownsHome",
    ["Sunken Temple"] = "SunkenTempleHome", ["Scholomance"] = "ScholomanceHome", ["Maraudon"] = "MaraudonHome",
    ["Blackrock Depths"] = "BlackrockDepthsHome", ["Upper Blackrock Spire"] = "UpperBlackrockSpireHome", ["Lower Blackrock Spire"] = "BlackrockSpireHome",
    ["Dire Maul: East"] = "DireMaulHome", ["Dire Maul: West"] = "DireMaulWestHome", ["Dire Maul: North"] = "DireMaulNorthHome",
    ["Stratholme: Living"] = "StratholmeHome", ["Stratholme: Undead"] = "StratholmeUndeadHome",
    -- WoW Forever dungeons announced but not out yet ("Coming Soon" cards).
    ["The Drowned City"] = "DrownedCityHome", ["Krol'dok Stronghold"] = "KroldokHome", ["Alcaz Prison"] = "AlcazPrisonHome",
    ["Blackmaw Hold"] = "BlackmawHoldHome", ["Shaper's Terrace"] = "ShapersTerraceHome" }) do
    SMJ.DUNGEON_HOME_ART[name] = "Interface\\AddOns\\SentinelMentor\\Media\\" .. file
    SMJ.DUNGEON_HOME_TEXCOORD[name] = { 0, 1, 0.06, 0.94 }
end

-- Prefer the client's own artwork: loading screens and encounter-journal
-- cards win over bundled images; the bundled art only fills the gaps for
-- dungeons the client cannot draw.
do
    local function Has(path)
        if not GetFileIDFromPath then return false end
        local ok, id = pcall(GetFileIDFromPath, path)
        return ok and id ~= nil
    end
    local function EJ(n) return "Interface\\EncounterJournal\\UI-EJ-DUNGEONBUTTON-" .. n end
    local function LS(n) return "Interface\\Glues\\LoadingScreens\\LoadScreen" .. n end
    for name, paths in pairs({
        ["The Deadmines"] = { EJ("Deadmines"), LS("Deadmines") },
        ["Shadowfang Keep"] = { EJ("ShadowfangKeep"), LS("Shadowfang") },
        ["Wailing Caverns"] = { EJ("WailingCaverns"), LS("WailingCaverns") },
        ["Blackfathom Deeps"] = { EJ("BlackfathomDeeps"), LS("BlackfathomDeeps") },
        ["The Stockade"] = { EJ("StormwindStockade"), EJ("Stockades"), LS("StormwindStockade"), LS("Stockade") },
        ["Ragefire Chasm"] = { EJ("RagefireChasm"), LS("Ragefire") },
        ["Gnomeregan"] = { EJ("Gnomeregan"), LS("Gnomeregan") },
        ["Razorfen Kraul"] = { EJ("RazorfenKraul"), LS("RazorfenKraul") },
        ["Razorfen Downs"] = { EJ("RazorfenDowns"), LS("RazorfenDowns") },
        ["Uldaman"] = { EJ("Uldaman"), LS("Uldaman") },
        ["Zul'Farrak"] = { EJ("ZulFarrak"), LS("ZulFarrak"), LS("Zulfarrak") },
        ["Maraudon"] = { EJ("Maraudon"), LS("Maraudon") },
        ["Sunken Temple"] = { EJ("SunkenTemple"), EJ("TempleofAtalHakkar"), LS("SunkenTemple"), LS("TempleOfAtalHakkar") },
        ["Blackrock Depths"] = { EJ("BlackrockDepths"), LS("BlackrockDepths") },
        ["Lower Blackrock Spire"] = { EJ("LowerBlackrockSpire"), EJ("BlackrockSpire"), LS("LowerBlackrockSpire"), LS("BlackrockSpire") },
        ["Upper Blackrock Spire"] = { EJ("UpperBlackrockSpire"), LS("UpperBlackrockSpire") },
        ["Dire Maul: East"] = { EJ("DireMaulEast"), EJ("DireMaul"), LS("DireMaul") },
        ["Dire Maul: West"] = { EJ("DireMaulWest"), EJ("DireMaul"), LS("DireMaul") },
        ["Dire Maul: North"] = { EJ("DireMaulNorth"), EJ("DireMaul"), LS("DireMaul") },
        ["Stratholme: Living"] = { EJ("Stratholme"), LS("Stratholme") },
        ["Stratholme: Undead"] = { EJ("Stratholme"), LS("Stratholme") },
        ["Scholomance"] = { EJ("Scholomance"), LS("Scholomance") },
        ["Scarlet Monastery: Graveyard"] = { EJ("ScarletMonasteryGraveyard"), EJ("ScarletMonastery"), LS("ScarletMonastery") },
        ["Scarlet Monastery: Library"] = { EJ("ScarletMonasteryLibrary"), EJ("ScarletMonastery"), LS("ScarletMonastery") },
        ["Scarlet Monastery: Armory"] = { EJ("ScarletMonasteryArmory"), EJ("ScarletMonastery"), LS("ScarletMonastery") },
        ["Scarlet Monastery: Cathedral"] = { EJ("ScarletMonasteryCathedral"), EJ("ScarletMonastery"), LS("ScarletMonastery") },
    }) do
        for _, path in ipairs(paths) do
            if Has(path) then
                SMJ.DUNGEON_HOME_ART[name] = path
                SMJ.DUNGEON_HOME_TEXCOORD[name] = { 0.02, 0.98, 0.24, 0.82 }
                break
            end
        end
    end
end

-- Cards whose art ends in a dark strip get a coloured band over the bottom
-- edge, tinted to match the art: { r, g, b, height }.
SMJ.DUNGEON_HOME_BOTTOM_BAND = {
    ["City of Dalaran"] = { 0.36, 0.26, 0.42, 4 },
}

-- Sentinel default: neutral dark chrome with the gold accent, used whenever a
-- dungeon has no theme of its own.
SMJ.THEMES.default = {
    frame = {0.05, 0.06, 0.105, 0.99},
    content = {0.06, 0.07, 0.12, 0.90},
    border = {0.92, 0.68, 0.20, 1},
    header = {0.09, 0.10, 0.16, 0.94},
    left = {0.07, 0.08, 0.13, 0.94},
    right = {0.07, 0.08, 0.13, 0.94},
    row = {0.075, 0.085, 0.14, 0.92},
    rowSelected = {0.30, 0.23, 0.10, 0.95},
    lootRow = {0.08, 0.09, 0.15, 0.94},
    title = {0.92, 0.68, 0.20},
    text = {0.92, 0.92, 0.95},
    muted = {0.55, 0.57, 0.64},
}
