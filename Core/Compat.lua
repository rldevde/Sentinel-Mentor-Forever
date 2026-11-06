-- Compatibility layer: provides every helper the rest of the addon expects,
-- self-contained (no external library). Translation store, output, events,
-- addon info, waypoints, shared-settings and slash shims.
local ADDON_NAME, SM = ...
local addon = SM

SM.ADDON_NAME = ADDON_NAME

-- output ----------------------------------------------------------------------
local PREFIX = "|cffebad33Sentinel|r|cffffffffMentor|r"
function SM:SetAddonOutput() end

function SM:MSG(msg)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(msg))
	else
		print(PREFIX .. ": " .. tostring(msg))
	end
end

function SM:ERR(msg)
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage(tostring(msg), 1, 0.1, 0.1)
	else
		self:MSG("|cffff5555" .. tostring(msg) .. "|r")
	end
end

-- translations ------------------------------------------------------------------
SM.Translations = {}
function SM:AddTrans(lang, key, text)
	self.Translations[lang] = self.Translations[lang] or {}
	self.Translations[lang][key] = text
end

function SM.Trans(self, key, lang, ...)
	lang = lang or "enUS"
	local store = self.Translations
	local text = store[lang] and store[lang][key] or store.enUS and store.enUS[key] or key
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, text, ...)
		if ok then return formatted end
	end
	return text
end

-- events --------------------------------------------------------------------------
function SM:RegisterEvent(frame, event)
	if frame and frame.RegisterEvent then pcall(frame.RegisterEvent, frame, event) end
end

-- misc ----------------------------------------------------------------------------
function SM:IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local IsAddOnLoadedFunc = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
function SM:IsAddonLoaded(name)
	return IsAddOnLoadedFunc and IsAddOnLoadedFunc(name) and true or false
end

function SM:GetWoWBuild()
	return "RETAIL"
end

function SM:CheckTemplates(templateName)
	if not templateName then return false end
	local ok, frame = pcall(CreateFrame, "Frame", nil, nil, templateName)
	return ok and frame ~= nil
end

function SM:GetAddonIcon()
	return "Interface\\AddOns\\SentinelMentor\\logo"
end

function SM:GetAddonVersion()
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
	end
	return GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version") or "?"
end

function SM:SetVersion()
	self.Version = self:GetAddonVersion()
end

-- waypoints -------------------------------------------------------------------------
function SM:HasWaypointSupport()
	return C_SuperTrack and C_SuperTrack.SetUserWaypoint ~= nil
end

function SM:SetTrackedWaypoint(uiMapID, x, y)
	if not self:HasWaypointSupport() then return false end
	if not C_Map or not C_Map.MapHasArt or not CreateVector2D then
		-- still try: some clients accept SetUserWaypoint without art check
	end
	local point = CreateVector2D(x, y)
	local ok = pcall(C_SuperTrack.SetUserWaypoint, uiMapID, point)
	if not ok then
		ok = pcall(function()
			C_SuperTrack.SetSuperTrackedUserWaypoint(false)
			C_Map.SetUserWaypoint(uiMapID, point)
			C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		end)
	end
	return ok and true or false
end

SM.waypointFallbackGetDB = nil
function SM:EnableWaypointFallback(getDB)
	self.waypointFallbackGetDB = getDB
end

-- shared settings (compat: external addons may sync settings; keep it in-process) -----
SM.sharedSettings = {keys = {}, getDB = nil, get = nil, set = nil, onChange = nil}
function SM:RegisterSharedSettings(def)
	self.sharedSettings = def
end

function SM:SetSharedSetting(key, value)
	local shared = self.sharedSettings
	if shared and shared.set then
		shared.set(key, value)
		if shared.onChange then shared.onChange(key, value) end
	end
end

function SM:GetSharedSetting(key)
	local shared = self.sharedSettings
	if shared and shared.get then return shared.get(key) end
end

-- slash ------------------------------------------------------------------------------
local slashCount = 0
function SM:AddSlash(cmd, func)
	slashCount = slashCount + 1
	local tag = "SENTINELMENTOR" .. slashCount
	_G["SLASH_" .. tag .. "1"] = "/" .. cmd
	SlashCmdList[tag] = func
end
