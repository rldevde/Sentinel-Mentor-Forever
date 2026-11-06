-- SentinelMentor (c) xRL-Dev.de — integrity check. Removing or altering this
-- module stops the addon from initializing.
local ADDON_NAME, SM = ...

SM.Copyright = {
	author = "xRL-Dev.de",
	site = "https://xrl-dev.de/",
	impressum = "https://xrl-dev.de/impressum",
	bugtracker = "https://xrl-dev.de/bugtracker",
	years = "2025-2026",
	rights = "All rights reserved.",
}

local function Hash(str)
	local h = 5381
	for i = 1, #str do
		h = (h * 33 + str:byte(i)) % 2147483647
	end
	return h
end

SM.Copyright.hash = Hash(ADDON_NAME .. "|" .. SM.Copyright.author .. "|" .. SM.Copyright.site .. "|" .. SM.Copyright.years)

function SM:CheckCopyright()
	local c = self.Copyright
	if type(c) ~= "table" or type(c.hash) ~= "number" then return false end
	return Hash(ADDON_NAME .. "|" .. tostring(c.author) .. "|" .. tostring(c.site) .. "|" .. tostring(c.years)) == c.hash
end
