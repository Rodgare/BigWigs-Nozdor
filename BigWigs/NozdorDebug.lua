-- Nozdor: lightweight diagnostics for the custom Siege of Dalaran raid (961).
-- Keeps a short rolling log in BigWigsDebugDB and prints a concise status line
-- when entering the raid, so a missing module pack/core is visible immediately.
-- Manual use: /bwdbg, /bwdbg dump, /bwdbg clear

local MAX_EVENTS = 200
local lastSnapshot, lastSnapshotAt = nil, 0
local wrathLoaded = false

local function db()
	if type(BigWigsDebugDB) ~= "table" then BigWigsDebugDB = {} end
	if type(BigWigsDebugDB.events) ~= "table" then BigWigsDebugDB.events = {} end
	return BigWigsDebugDB.events
end

local function logEvent(tag, msg)
	local events = db()
	events[#events + 1] = ("%s [%s] %s"):format(date("%H:%M:%S"), tag, msg)
	while #events > MAX_EVENTS do
		tremove(events, 1)
	end
end

local function currentZone()
	if not BigWigsLoader or not BigWigsLoader.GetInstanceInfo then return nil end
	local ok, name, instanceType, _, diffName, _, _, _, id = pcall(BigWigsLoader.GetInstanceInfo)
	if not ok then return nil end
	return name, instanceType, diffName, id
end

local function coreEnabled()
	if not BigWigs or not BigWigs.IsEnabled then return false end
	local ok, enabled = pcall(BigWigs.IsEnabled, BigWigs)
	return ok and enabled and true or false
end

local function moduleCount(id)
	if not BigWigsLoader or not BigWigsLoader.GetZoneMenus then return 0 end
	local ok, menus = pcall(BigWigsLoader.GetZoneMenus, BigWigsLoader)
	if not ok or type(menus) ~= "table" then return 0 end
	local list = menus[id]
	return type(list) == "table" and #list or 0
end

local function isDalaran(name, id)
	if id == 961 then return true end
	if type(name) ~= "string" then return false end
	local lower = name:lower()
	return lower:find("осада даларана", 1, true) or lower:find("siege of dalaran", 1, true) or lower:find("вечерняя заря", 1, true)
end

local function snapshot(tag, quiet)
	local name, instanceType, diffName, id = currentZone()
	if not id then return end
	local pack = BigWigsLoader.zoneTbl and BigWigsLoader.zoneTbl[id]
	local msg = ("zone=%s id=%s type=%s diff=%s pack=%s wrath=%s core=%s modules=%d"):format(
		tostring(name), tostring(id), tostring(instanceType), tostring(diffName),
		tostring(pack), wrathLoaded and "loaded" or "NOT-LOADED",
		coreEnabled() and "on" or "off", moduleCount(id))
	logEvent(tag, msg)

	if isDalaran(name, id) and not quiet then
		local now = GetTime()
		if msg ~= lastSnapshot or (now - lastSnapshotAt) > 10 then
			lastSnapshot, lastSnapshotAt = msg, now
			print("|cFF33FF99BigWigs|r [961] " .. msg)
			if not wrathLoaded then
				print("|cFF33FF99BigWigs|r [961] Wrath pack is not loaded: check BigWigs_WrathOfTheLichKing in the addon list / load-on-zone metadata.")
			end
			if moduleCount(id) == 0 then
				print("|cFF33FF99BigWigs|r [961] no boss modules registered for this instance.")
			end
		end
	end
end

local delayedFrame = CreateFrame("Frame")
local delayedLeft = 0
delayedFrame:Hide()
delayedFrame:SetScript("OnUpdate", function(self, elapsed)
	delayedLeft = delayedLeft - (elapsed or 0)
	if delayedLeft <= 0 then
		self:Hide()
		snapshot("ZONE+3s")
	end
end)
local function delayedSnapshot()
	delayedLeft = 3
	delayedFrame:Show()
end

local function mobId(guid)
	if not guid then return 0 end
	local prefix = guid:sub(3, 5):lower()
	if prefix == "f13" or prefix == "f14" or prefix == "f15" then
		return (tonumber(guid:sub(5, 12), 16) or 0) % 65536
	end
	return 0
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

frame:SetScript("OnEvent", function(_, event, addon)
	if event == "ADDON_LOADED" then
		db()
		if addon == "BigWigs_WrathOfTheLichKing" then
			wrathLoaded = true
			logEvent("LOAD", "BigWigs_WrathOfTheLichKing loaded")
			snapshot("LOAD", true)
		elseif addon == "BigWigs_Core" then
			logEvent("LOAD", "BigWigs_Core loaded")
		elseif addon == "BigWigs" then
			logEvent("LOAD", "BigWigs loaded")
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		if IsAddOnLoaded and IsAddOnLoaded("BigWigs_WrathOfTheLichKing") then
			wrathLoaded = true
		end
		local _, _, _, id = currentZone()
		snapshot(event, isDalaran(select(1, currentZone()), id))
		if isDalaran(select(1, currentZone()), id) then
			delayedSnapshot()
		end
	elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		local _, _, _, id = currentZone()
		if not isDalaran(select(1, currentZone()), id) then return end
		for i = 1, 5 do
			local unit = "boss" .. i
			if UnitExists(unit) then
				local guid = UnitGUID(unit)
				local line = ("%s name=%s mob=%d guid=%s"):format(unit, tostring(UnitName(unit)), mobId(guid), tostring(guid))
				logEvent("ENGAGE", line)
				print("|cFF33FF99BigWigs|r [961] " .. line)
			end
		end
	end
end)

-- Log boss modules registered for 961, even before the zone is entered.
if BigWigsLoader and BigWigsLoader.RegisterMessage then
	local listener = {}
	function listener:BigWigs_BossModuleRegistered(_, _, module)
		if type(module) == "table" and module.instanceId == 961 then
			logEvent("MODULE", ("registered %s (mob=%s)"):format(tostring(module.moduleName), tostring(module.enableMob)))
			print(("|cFF33FF99BigWigs|r [961] module registered: %s"):format(tostring(module.moduleName)))
		end
	end
	BigWigsLoader.RegisterMessage(listener, "BigWigs_BossModuleRegistered")

	function listener:BigWigs_OnBossEngage(_, module)
		if type(module) == "table" and module.instanceId == 961 then
			local line = "module engaged: " .. tostring(module.moduleName)
			logEvent("ENGAGE", line)
			print("|cFF33FF99BigWigs|r [961] " .. line)
		end
	end
	BigWigsLoader.RegisterMessage(listener, "BigWigs_OnBossEngage")
end

SLASH_BIGWIGSDEBUG1 = "/bwdbg"
SlashCmdList["BIGWIGSDEBUG"] = function(msg)
	local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
	if cmd == "clear" then
		BigWigsDebugDB = { events = {} }
		print("|cFF33FF99BigWigs|r debug log cleared.")
		return
	end
	snapshot("NOW")
	local events = db()
	local first = cmd == "dump" and 1 or math.max(1, #events - 24)
	print(("|cFF33FF99BigWigs|r debug log (%d/%d):"):format(first, #events))
	for i = first, #events do
		print(events[i])
	end
end
