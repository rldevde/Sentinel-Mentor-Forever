local _, SentinelMentor = ...
SentinelMentor.LANGUAGES = {{"English", "enUS"}, {"Deutsch", "deDE"}, {"Español (España)", "esES"}, {"Español (México)", "esMX"}, {"Français", "frFR"}, {"Italiano", "itIT"}, {"한국어", "koKR"}, {"Português (Brasil)", "ptBR"}, {"Русский", "ruRU"}, {"简体中文", "zhCN"}, {"繁體中文", "zhTW"}}
SentinelMentor.LanguageNames = {}
for _, info in ipairs(SentinelMentor.LANGUAGES) do
    SentinelMentor.LanguageNames[info[2]] = info[1]
end

function SentinelMentor:GetLanguage()
    local lang = type(SentinelMentor_Global) == "table" and SentinelMentor_Global.language or nil
    if lang ~= nil and self.LanguageNames[lang] ~= nil then return lang end
    if self.LanguageNames[GetLocale()] ~= nil then return GetLocale() end
    return "enUS"
end

function SentinelMentor:GetLanguageName(lang)
    lang = lang or self:GetLanguage()
    return self.LanguageNames[lang] or lang
end

function SentinelMentor:SetLanguage(lang)
    if self.LanguageNames[lang] == nil or lang == self:GetLanguage() then return end
    SentinelMentor_Global = SentinelMentor_Global or {}
    if lang == GetLocale() then
        SentinelMentor_Global.language = nil
    else
        SentinelMentor_Global.language = lang
    end

    self:RefreshLanguage()
end

SentinelMentor.LibTrans = SentinelMentor.Trans
function SentinelMentor:Trans(key, lang, ...)
    return SentinelMentor.LibTrans(self, key, lang or SentinelMentor:GetLanguage(), ...)
end

function SentinelMentor:RefreshLanguage()
    local win = self.SettingsWindow
    if win then
        local shown = win:IsShown()
        local point = {win:GetPoint(1)}
        local width, height = win:GetSize()
        win:Hide()
        self.SettingsWindow = nil
        self.SettingCheckboxes = {}
        if shown then
            self:ToggleSettings()
            local newWin = self.SettingsWindow
            if newWin and point[1] then
                newWin:ClearAllPoints()
                newWin:SetPoint(unpack(point))
                newWin:SetSize(width, height)
            end
        end
    end

    if SentinelMentor_Refresh then SentinelMentor_Refresh() end
    if SentinelMentor_ProfessionRefresh then SentinelMentor_ProfessionRefresh() end
end

function SentinelMentor:AddLanguageButton(win)
    local function LanguageMenu(_, root)
        root:CreateTitle(self:Trans("LID_LANGUAGE"))
        for _, info in ipairs(self.LANGUAGES) do
            local lang = info[2]
            root:CreateRadio(format("%s (%s)", info[1], lang), function() return self:GetLanguage() == lang end, function() self:SetLanguage(lang) end)
        end
    end

    local parent = win.titleBar or win
    local button
    do
        button = self:CreateButton(nil, parent)
        button:SetSize(130, 20)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -2)
        button.Arrow = button:CreateTexture(nil, "OVERLAY")
        button.Arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        button.Arrow:SetSize(16, 16)
        button.Arrow:SetPoint("RIGHT", button, "RIGHT", -2, 0)
        button:SetScript("OnClick", function(sel)
            if MenuUtil and MenuUtil.CreateContextMenu then
                MenuUtil.CreateContextMenu(sel, LanguageMenu)
            else
                local current = 1
                for i, info in ipairs(self.LANGUAGES) do
                    if info[2] == self:GetLanguage() then current = i end
                end

                self:SetLanguage(self.LANGUAGES[current % #self.LANGUAGES + 1][2])
            end
        end)

        button:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetText(self:Trans("LID_LANGUAGE"))
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    button:SetText(self:GetLanguageName())
    win.Language = button
end

SentinelMentor.TabSettings = {}
SentinelMentor.TabSettingKeys = {"spellbook", "class", "pet", "beasts", "trainers", "weapons","professions", "profession_skill", "profession_recipes", "profession_trainers", "compendium_class", "compendium_professions"}
SentinelMentor.SharedTabSettings = {
    SENTINELMENTOR_COMPENDIUM_CLASS = "compendium_class",
    SENTINELMENTOR_COMPENDIUM_PROFESSIONS = "compendium_professions"
}

function SentinelMentor:LoadTabSettings()
    for _, key in ipairs(self.TabSettingKeys) do
        self.TabSettings[key] = SentinelMentor_Character[key] ~= false
    end
end

SentinelMentor:LoadTabSettings()
SentinelMentor.TabSettingListeners = {}
SentinelMentor.SettingCheckboxes = {}
function SentinelMentor:OnTabSettingsChanged(listener)
    table.insert(self.TabSettingListeners, listener)
end

function SentinelMentor:ApplyTabSettings()
    if not self.SettingsReady then return end
    self:LoadTabSettings()
    for _, listener in ipairs(self.TabSettingListeners) do
        local ok, err = pcall(listener)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end

    self:RegisterCompendiumTabs()
    if self.SettingsWindow and self.SettingsWindow.UpdateDependencies then self.SettingsWindow:UpdateDependencies() end
end

SentinelMentor:RegisterSharedSettings({
    keys = {"SENTINELMENTOR_COMPENDIUM_CLASS", "SENTINELMENTOR_COMPENDIUM_PROFESSIONS"},
    getDB = function() return SentinelMentor_Character end,
    get = function(key) return SentinelMentor_Character[SentinelMentor.SharedTabSettings[key]] ~= false end,
    set = function(key, value) SentinelMentor_Character[SentinelMentor.SharedTabSettings[key]] = value end,
    onChange = function(key, value)
        local checkbox = SentinelMentor.SettingCheckboxes[SentinelMentor.SharedTabSettings[key]]
        if checkbox and checkbox.SetChecked then checkbox:SetChecked(value ~= false) end
        SentinelMentor:ApplyTabSettings()
    end
})

function SentinelMentor:IsTabEnabled(key)
    return self.TabSettings[key] ~= false
end

function SentinelMentor:FilterTabViews(views, prefix)
    local visible = {}
    for _, entry in ipairs(views) do
        if self:IsTabEnabled((prefix or "") .. (entry.view or entry.mode)) then table.insert(visible, entry) end
    end
    return visible
end

function SentinelMentor:HasSpellbookTabs()
    local _, classToken = UnitClass("player")
    return self:IsTabEnabled("class") or self:IsTabEnabled("trainers") and self.BuildClassTrainerItems ~= nil or self:IsTabEnabled("weapons") and self.BuildWeaponSkillItems ~= nil or self:IsTabEnabled("pet") and self:HasPetClassData(classToken) or self:IsTabEnabled("beasts") and self.BuildBeastItems ~= nil
end

function SentinelMentor:GetTabLayout(key)
    return SentinelMentor_Character and SentinelMentor_Character[key] == "tabs" and "tabs" or "combined"
end

function SentinelMentor:HasProfessionTabs()
    return self:IsTabEnabled("profession_skill") or self:IsTabEnabled("profession_recipes") or self:IsTabEnabled("profession_trainers")
end

function SentinelMentor:ToggleSettings()
    if not self.SettingsWindow then
        local win = self:CreateUIWindow({
            name = "SentinelMentorSettings",
            title = format("|T%s:20:20|t SentinelMentor v%s", SentinelMentor:GetAddonIcon(), SentinelMentor:GetAddonVersion()),
            width = 520,
            height = 600
        })

        self.SettingsWindow = win
        self:AddLanguageButton(win)
        win:AddSearch()
        win:AddCategory({
            label = "LID_GENERAL",
            key = "general"
        })

        win:AddCheckbox({
            label = "LID_SHOWMINIMAPBUTTON",
            added = "2026-10-07",
            value = SentinelMentor_Character.showMinimapButton ~= false,
            func = function(value)
                SentinelMentor_Character.showMinimapButton = value
                if value then
                    self:ShowMMBtn("SentinelMentor")
                else
                    self:HideMMBtn("SentinelMentor")
                end
            end
        })

        win:AddCategory({
            label = "LID_ABOUT",
            key = "about"
        })

        local copyright = self.Copyright or {}
        local accent = self.Style and self.Style.colors.accent
        win:AddInfo({label = "LID_ABOUT_VERSION", text = "v" .. self:GetAddonVersion()})
        win:AddInfo({label = "LID_ABOUT_AUTHOR", text = copyright.author or "xRL-Dev.de", color = accent})
        win:AddInfo({label = "LID_ABOUT_WEBSITE", text = copyright.site or "https://xrl-dev.de/"})
        win:AddInfo({label = "LID_ABOUT_BUGTRACKER", text = copyright.bugtracker or "https://xrl-dev.de/bugtracker"})
        win:AddInfo({label = "LID_ABOUT_IMPRINT", text = copyright.impressum or "https://xrl-dev.de/impressum"})
        win:AddInfo({label = "LID_ABOUT_LICENSE", text = "© " .. tostring(copyright.years or "") .. " " .. tostring(copyright.author or "") .. " — " .. tostring(copyright.rights or "")})

        if self.AutoRanks then
            local autoRanks = self.AutoRanks.Settings()
            win:AddCategory({
                label = "LID_SETTINGS_AUTORANKS",
                key = "autoranks",
                added = "2026-11-04"
            })

            local autoRanksBox = win:AddCheckbox({
                label = "LID_AUTORANKS",
                added = "2026-11-04",
                value = autoRanks.autoSpellRanks,
                func = function(value)
                    SentinelMentor_Character.autoSpellRanks = value
                    win:UpdateDependencies()
                    if value then self.AutoRanks.Schedule(0.2) end
                end
            })

            local reportBox = win:AddCheckbox({
                label = "LID_AUTORANKS_REPORT",
                added = "2026-11-04",
                value = autoRanks.autoSpellRanksReport,
                func = function(value) SentinelMentor_Character.autoSpellRanksReport = value end
            })

            win:AddDependency(reportBox, function() return SentinelMentor_Character.autoSpellRanks ~= false end)
            win:AddRequirement(reportBox, autoRanksBox)
        end

        win:AddCategory({
            label = "LID_SETTINGS_PRICES",
            key = "prices"
        })

        win:AddDropdown({
            label = "LID_SETTINGS_PRICEDISPLAY",
            added = "2026-10-07",
            value = SentinelMentor.Pricing.GetDisplayMode(),
            choices = {
                {
                    value = "both",
                    label = "LID_SETTINGS_PRICEDISPLAY_BOTH"
                },
                {
                    value = "discounted",
                    label = "LID_SETTINGS_PRICEDISPLAY_DISCOUNTED"
                },
                {
                    value = "base",
                    label = "LID_SETTINGS_PRICEDISPLAY_BASE"
                }
            },
            func = function(value)
                SentinelMentor_Character.priceDisplay = value
                if SentinelMentor_Refresh then SentinelMentor_Refresh() end
                if SentinelMentor_ProfessionRefresh then SentinelMentor_ProfessionRefresh() end
            end
        })

        for _, category in ipairs({
            {
                label = "LID_SETTINGS_SPELLBOOK",
                key = "spellbook",
                layout = "spellbookLayout",
                compendium = "compendium_class",
                compendiumLabel = "LID_SETTINGS_COMPENDIUM_CLASS",
                options = {{"class", "LID_CLASSTRAINER"}, {"pet", "LID_PETTRAINING"}, {"beasts", "LID_BEASTS"}, {"trainers","LID_CLASSTRAINERS"}, {"weapons", "LID_SETTINGS_WEAPONS"}}
            },
            {
                label = "LID_PROFESSIONS",
                key = "professions",
                layout = "professionLayout",
                compendium = "compendium_professions",
                compendiumLabel = "LID_SETTINGS_COMPENDIUM_PROFESSIONS",
                options = {{"profession_skill", "LID_PROFESSION_FROMTRAINER"}, {"profession_recipes", "LID_PROFESSION_OTHERRECIPES"}, {"profession_trainers", "LID_PROFESSION_FINDTRAINER"}}
            }
        }) do
            win:AddCategory({
                label = category.label,
                key = category.key
            })

            local function AddParent(key, label)
                local checkbox = win:AddCheckbox({
                    label = label,
                    added = "2026-10-07",
                    value = SentinelMentor_Character[key] ~= false,
                    func = function(value)
                        SentinelMentor_Character[key] = value
                        for sharedKey, setting in pairs(self.SharedTabSettings) do
                            if setting == key then self:SetSharedSetting(sharedKey, value) end
                        end

                        self:ApplyTabSettings()
                    end
                })

                self.SettingCheckboxes[key] = checkbox
                return checkbox
            end

            local layout = win:AddDropdown({
                label = "LID_SETTINGS_LAYOUT",
                value = self:GetTabLayout(category.layout),
                choices = {
                    {
                        value = "combined",
                        label = "LID_SETTINGS_LAYOUT_COMBINED"
                    },
                    {
                        value = "tabs",
                        label = "LID_SETTINGS_LAYOUT_TABS"
                    }
                },
                func = function(value)
                    SentinelMentor_Character[category.layout] = value
                    self:ApplyTabSettings()
                end
            })

            win:AddDependency(layout, function() return SentinelMentor_Character[category.key] ~= false end, 0)
            local addonTab = AddParent(category.key, "LID_SETTINGS_ADDONTAB")
            local children = {}
            for _, option in ipairs(category.options) do
                local key = option[1]
                local checkbox = win:AddCheckbox({
                    label = option[2],
                    added = "2026-10-07",
                    value = SentinelMentor_Character[key] ~= false,
                    func = function(value)
                        SentinelMentor_Character[key] = value
                        self:ApplyTabSettings()
                    end
                })

                self.SettingCheckboxes[key] = checkbox
                win:AddDependency(checkbox, function() return SentinelMentor_Character[category.key] ~= false or SentinelMentor_Character[category.compendium] ~= false end)
                table.insert(children, checkbox)
            end

            local compendiumTab = AddParent(category.compendium, category.compendiumLabel)
            for _, checkbox in ipairs(children) do
                win:AddRequirement(checkbox, addonTab)
                win:AddRequirement(checkbox, compendiumTab)
            end
        end

        win:UpdateDependencies()
        win:Layout()
    end

    self.SettingsWindow:SetShown(not self.SettingsWindow:IsShown())
end

function SentinelMentor:InitializeSettings()
    self:LoadTabSettings()
    self.SettingsReady = true
    if SentinelMentor_Character.showMinimapButton == nil then SentinelMentor_Character.showMinimapButton = true end
    self:CreateMinimapButton({
        name = "SentinelMentor",
        icon = SentinelMentor:GetAddonIcon(),
        dbtab = SentinelMentor_Character,
        dbkey = "showMinimapButton",
        vTT = {{"SentinelMentor"}, {self:Trans("LID_OPENJOURNAL")}, {self:Trans("LID_SETTINGS_OPEN")}},
        funcL = function() if SentinelMentorJournal_Toggle then SentinelMentorJournal_Toggle() end end,
        funcR = function() self:ToggleSettings() end
    })

    self:AddSlash("ts", function() self:ToggleSettings() end)
    self:AddSlash("sentinelmentor", function() self:ToggleSettings() end)
    self:ApplyTabSettings()
end
