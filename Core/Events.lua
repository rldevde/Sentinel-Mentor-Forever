local _, SentinelMentor = ...
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("TRAINER_SHOW")
f:RegisterEvent("TRAINER_UPDATE")
f:RegisterEvent("MERCHANT_SHOW")
f:RegisterEvent("MERCHANT_UPDATE")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("SPELLS_CHANGED")
local captureScheduled = false
local merchantCaptureScheduled = false
local petSyncScheduled = false
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "SentinelMentor" then
        if not SentinelMentor:CheckCopyright() then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555SentinelMentor: copyright check failed — addon disabled.|r")
            return
        end
        SentinelMentor_Data = SentinelMentor_Data or {}
        SentinelMentor_Ignored = SentinelMentor_Ignored or {}
        SentinelMentor_IgnoredNames = SentinelMentor_IgnoredNames or {}
        SentinelMentor_Character = SentinelMentor_Character or {}
        SentinelMentor_Character.collapsedGroups = SentinelMentor_Character.collapsedGroups or {}
        SentinelMentor_Character.learnedSpellsPet = SentinelMentor_Character.learnedSpellsPet or {}
        if SentinelMentor_Character.showIgnoredInTrainer == nil then SentinelMentor_Character.showIgnoredInTrainer = false end
        SentinelMentor_Character.rowHeight = SentinelMentor_Character.rowHeight or 16
        SentinelMentor_PetData = SentinelMentor_PetData or {}
        SentinelMentor_PetTrainerData = SentinelMentor_PetTrainerData or {}
        SentinelMentor_ProfessionData = SentinelMentor_ProfessionData or {}
        SentinelMentor_RecipeData = SentinelMentor_RecipeData or {}
        SentinelMentor:SetVersion()
        SentinelMentor:InitializeSettings()
        SentinelMentor:MergeBuiltinData()
        SentinelMentor:RemoveNonClassSpellsFromClassData()
        SentinelMentor_IgnoredProfessions = SentinelMentor_IgnoredProfessions or {}
        _G.SentinelMentor_ToggleIgnoreProfessionSpell = SentinelMentor_ToggleIgnoreProfessionSpell
        _G.SentinelMentor_IsProfessionSpellIgnored = SentinelMentor_IsProfessionSpellIgnored
        SentinelMentor:MigrateLegacyProfessionIgnores()
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        if SentinelMentor.DebugTrainerEnabled then SentinelMentor:EnableTrainerDebugFilters() end
        do
            local isTradeskill = IsTradeskillTrainer and IsTradeskillTrainer()
            local professionKey, professionSkillLine
            if isTradeskill then professionKey, professionSkillLine = SentinelMentor:DetectTrainerProfession() end
            SentinelMentor:DebugTrainer("Event %s: npcName=%s npcGUID=%s isTradeskill=%s professionKey=%s professionSkillLine=%s", event, tostring(UnitName("npc")), tostring(UnitGUID and UnitGUID("npc")), tostring(isTradeskill), tostring(professionKey), tostring(professionSkillLine))
        end

        SentinelMentor:EnsureTrainerUpdateOverrideInstalled()
        SentinelMentor:EnsureTrainerFilterHookInstalled()
        if SentinelMentor.DebugTrainerEnabled and ClassTrainerFrame and SentinelMentorScanButton == nil then
            local scanButton = SentinelMentor.Style:Button(ClassTrainerFrame, "Scannen", 80, 22)
            _G["SentinelMentorScanButton"] = scanButton
            scanButton:SetSize(80, 22)
            scanButton:SetText("Scannen")
            scanButton:SetPoint("BOTTOMLEFT", ClassTrainerFrame, "TOPRIGHT", 0, 0)
            scanButton:SetScript("OnClick", function()
                local ok, err = pcall(function() SentinelMentor:ScanAllTrainerRequirements() end)
                if not ok then SentinelMentor:MSG("|cffff5555SentinelMentor Fehler:|r " .. tostring(err)) end
            end)
        end

        if C_Timer then
            if not captureScheduled then
                captureScheduled = true
                C_Timer.After(0.1, function()
                    captureScheduled = false
                    SentinelMentor:CaptureTrainer()
                    SentinelMentor:CaptureTrainerRequirements()
                end)
            end
        else
            SentinelMentor:CaptureTrainer()
            SentinelMentor:CaptureTrainerRequirements()
        end
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        if C_Timer then
            if not merchantCaptureScheduled then
                merchantCaptureScheduled = true
                C_Timer.After(0.1, function()
                    merchantCaptureScheduled = false
                    SentinelMentor:CaptureMerchant()
                end)
            end
        else
            SentinelMentor:CaptureMerchant()
        end
    elseif event == "SPELLS_CHANGED" or (event == "UNIT_PET" and arg1 == "player") then
        if C_Timer then
            if not petSyncScheduled then
                petSyncScheduled = true
                C_Timer.After(1, function()
                    petSyncScheduled = false
                    SentinelMentor:SyncKnownPetSpellsForActivePet()
                end)
            end
        else
            SentinelMentor:SyncKnownPetSpellsForActivePet()
        end
    end
end)

SentinelMentor_Capture = function() SentinelMentor:CaptureTrainer() end
SentinelMentor_CaptureMerchant = function() SentinelMentor:CaptureMerchant() end
SentinelMentor_SyncPetSpells = function() SentinelMentor:SyncKnownPetSpellsForActivePet() end
