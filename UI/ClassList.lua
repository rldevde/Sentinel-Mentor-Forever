local _, SentinelMentor = ...
local classFrame = SentinelMentor.ClassFrame
SentinelMentor.ClassView = SentinelMentor.ClassView or "class"
local searchBox = CreateFrame("EditBox", "SentinelMentorSearchBox", classFrame, "SearchBoxTemplate")
SentinelMentor.SearchBox = searchBox
SentinelMentor.Style:SkinSearchBox(searchBox)
searchBox:SetPoint("TOPLEFT", classFrame, "TOPLEFT", -60, -6)
searchBox:SetPoint("TOPRIGHT", classFrame, "TOPRIGHT", -10, -6)
searchBox:SetHeight(20)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnTextChanged", function(self)
    if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
    SentinelMentor_SearchText = self:GetText() or ""
    SentinelMentor_Refresh()
end)

local scrollBox = CreateFrame("Frame", "SentinelMentorScrollBox", classFrame, "WowScrollBoxList")
SentinelMentor.ClassScrollBox = scrollBox
SentinelMentor.ClassScrollTarget = scrollBox.ScrollTarget
scrollBox.ScrollTarget = nil
function scrollBox:GetScrollTarget() return SentinelMentor.ClassScrollTarget end
scrollBox:SetPoint("TOPLEFT", classFrame, "TOPLEFT", 6, -4)
scrollBox:SetPoint("BOTTOMRIGHT", classFrame, "BOTTOMRIGHT", -24, 13)
local listBg = classFrame:CreateTexture("SentinelMentorFrameBackground", "BACKGROUND")
SentinelMentor.ClassListBackground = listBg
local scrollBar = CreateFrame("EventFrame", "SentinelMentorScrollBar", classFrame, "MinimalScrollBar")
scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -2)
scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)
local scrollView = CreateScrollBoxListLinearView()
function scrollView:RefreshSmartNav() end
scrollView:SetElementExtentCalculator(function(_, elementData)
    if elementData.isHeader then return SentinelMentor.HeaderHeight + SentinelMentor.HeaderExtraGap end
    return SentinelMentor.RowHeight
end)

scrollView:SetPadding(0, 0, 0, 0, SentinelMentor.RowSpacing)
scrollView:SetElementInitializer("Frame", function(rowFrame, elementData)
    SentinelMentor:InitScrollRow(rowFrame, elementData, SentinelMentor.RowHeight)
    SentinelMentor:ApplyRowStripe(rowFrame, elementData)
    SentinelMentor:ApplyRowInteraction(rowFrame)
    SentinelMentor:PrepareGamepadNavigation(rowFrame)
end)
ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

function SentinelMentor:BuildClassViewItems(viewMode, searchText)
    searchText = (searchText or ""):lower()
    local selectedLevel = UnitLevel("player") or 1
    local selectedClass = select(2, UnitClass("player"))
    local classData = selectedClass and SentinelMentor_Data and SentinelMentor_Data[selectedClass]
    local items = {}
    if viewMode == "class" and classData then
        local groups = SentinelMentor:ClassifyEntries(classData, searchText, selectedLevel)
        SentinelMentor:AppendGroupItems(items, groups, "")
    end

    if viewMode == "pet" then
        if selectedClass == "WARLOCK" then SentinelMentor:AppendPetAbilities(items, searchText, selectedLevel) end
        if selectedClass == "HUNTER" then SentinelMentor:AppendPetTrainerAbilities(items, searchText, selectedLevel, selectedClass) end
    end

    if viewMode == "weapons" and SentinelMentor.BuildWeaponSkillItems then
        SentinelMentor:BuildWeaponSkillItems(items, searchText, selectedLevel)
    end

    if viewMode == "trainers" and SentinelMentor.BuildClassTrainerItems then
        SentinelMentor:BuildClassTrainerItems(items, searchText)
    end

    if viewMode == "beasts" and SentinelMentor.BuildBeastItems then
        SentinelMentor:BuildBeastItems(items, searchText)
    end

    if #items == 0 then
        if viewMode == "weapons" or viewMode == "trainers" or viewMode == "beasts" then
            SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_NOENTRIES"), "|cffaaaaaa")
        elseif not classData then
            SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_NODATAFORCLASS"):format(tostring(selectedClass)), "|cffff5555")
        else
            SentinelMentor:AddHeaderItem(items, SentinelMentor:Trans("LID_NOENTRIES"), "|cffaaaaaa")
        end
    end

    SentinelMentor:AddCostColumn(items)
    return items
end

function SentinelMentor_Refresh()
    SentinelMentor.RunDetached(classFrame, function()
        scrollBox:SetDataProvider(CreateDataProvider(SentinelMentor:CompactItems(SentinelMentor:BuildClassViewItems(SentinelMentor.ClassView, SentinelMentor_SearchText))), ScrollBoxConstants.RetainScrollPosition)
        if ScrollBoxConstants.UpdateImmediately then scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
    end)

    if SentinelMentor.CompendiumClassView then SentinelMentor.CompendiumClassView:Refresh() end
end

function SentinelMentor:HasPetClassData(classToken)
    if classToken == "HUNTER" then
        local data = SentinelMentor_PetTrainerData and SentinelMentor_PetTrainerData[classToken]
        if data and next(data) ~= nil then return true end
        return SentinelMentorDB.hunterPet and next(SentinelMentorDB.hunterPet) ~= nil
    end

    if classToken == "WARLOCK" then
        for _, petGroup in ipairs(SentinelMentor.PetGroups) do
            for _, key in ipairs(petGroup.keys) do
                local data = SentinelMentor_PetData and SentinelMentor_PetData[key]
                if data and next(data) then return true end
                local builtinData = SentinelMentorDB.warlockPets and SentinelMentorDB.warlockPets[key]
                if builtinData and next(builtinData) then return true end
            end
        end
    end

    return false
end

function SentinelMentor:SetClassView(view)
    if view == "pet" then
        local classToken = select(2, UnitClass("player"))
        if not SentinelMentor:HasPetClassData(classToken) then view = "class" end
    end

    if view == "beasts" and not SentinelMentor.BuildBeastItems then view = "class" end

    SentinelMentor.ClassView = view
    if SentinelMentor_Character then SentinelMentor_Character.classView = view end
    if SentinelMentor.UpdateClassViewTabs then SentinelMentor:UpdateClassViewTabs() end
    if SentinelMentor_Refresh then SentinelMentor_Refresh() end
end

classFrame:SetScript("OnShow", function()
    if SentinelMentor_SyncPetSpells then SentinelMentor_SyncPetSpells() end
    SentinelMentor_Refresh()
end)

classFrame:RegisterEvent("PLAYER_LEVEL_UP")
classFrame:RegisterEvent("SPELLS_CHANGED")
classFrame:RegisterEvent("PLAYER_MONEY")
classFrame:RegisterEvent("UPDATE_FACTION")
classFrame:HookScript("OnEvent", function(self, event)
    if event == "PLAYER_LEVEL_UP" or event == "SPELLS_CHANGED" or event == "PLAYER_MONEY" or event == "UPDATE_FACTION" then SentinelMentor_Refresh() end
end)
