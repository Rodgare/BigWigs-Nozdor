
local API = {}

--------------------------------------------------------------------------------
-- Locale
--

do
	local tbl = {}
	-- Nozdor 3.3.5 RU-only fork: always resolve the addon to the Russian
	-- locale instead of reading the client locale. This makes every
	-- BigWigs*addon register/apply ruRU unconditionally.
	local myRegion = "ruRU"
	function API:NewLocale(locale, region)
		if region == "enUS" or region == myRegion then
			if not tbl[locale] then
				tbl[locale] = {}
			end
			return tbl[locale]
		end
	end
	function API:GetLocale(locale)
		if tbl[locale] then
			return tbl[locale]
		end
	end
end

--------------------------------------------------------------------------------
-- Voice
--

do
	local addons = {}
	function API.RegisterVoicePack(pack)
		if type(pack) ~= "string" then error("Voice pack name must be a string.") return end

		if not addons[pack] then
			addons[pack] = true
		else
			error(("Voice pack %s already registered."):format(pack))
		end
	end

	function API.HasVoicePack()
		if next(addons) then
			return true
		end
	end
end

--------------------------------------------------------------------------------
-- Countdown
--

do
	local voices = {}
	function API:RegisterCountdown(id, name, data)
		if not data then data, name = name, id end
		if type(id) ~= "string" then error("Countdown name must be a string.") end
		if type(data) ~= "table" or #data < 5 or #data > 10 then error("Countdown data must be an indexed table with 5-10 entries.") end
		if voices[id] then error(("Countdown %q already registered."):format(id)) end

		voices[id] = { name = name }
		for i = 1, #data do
			voices[id][i] = data[i]
		end
	end
	function API:GetCountdownList()
		local list = {}
		for k, v in next, voices do
			list[k] = v.name
		end
		return list
	end
	function API:HasCountdown(id)
		return voices[id] and true
	end
	function API:GetCountdownSound(id, index)
		return voices[id] and voices[id][index]
	end
end

-------------------------------------------------------------------------------
-- Global
--

BigWigsAPI = setmetatable({}, { __index = API, __newindex = function() end, __metatable = false })

--------------------------------------------------------------------------------
-- Nozdor 3.3.5 compatibility shim
--
-- The BigWigs core/options/plugins/modules are written against a modern (post-WoD)
-- WoW API. On the 3.3.5 Nozdor client most of that API exists (C_Timer, C_ChatInfo,
-- C_Map, C_CVar, C_NamePlate, UIParent, CreateAnimationGroup, ...) but a few modern
-- functions do not. Everything below is only installed when the global is MISSING,
-- so it never overrides what the client or another addon already provides.
--------------------------------------------------------------------------------

-- C_EncounterJournal.GetSectionInfo: the core binds this as an upvalue at file-load
-- time (Constants.lua, BossPrototype.lua, Core.lua). If the table is nil the whole
-- core fails to load, so always guarantee a table with a safe stub.
if not C_EncounterJournal then
	C_EncounterJournal = {}
end
if not C_EncounterJournal.GetSectionInfo then
	C_EncounterJournal.GetSectionInfo = function() return nil end
end

-- GetSpellDescription: added in a later expansion. Only used for boss-option
-- tooltips; returning nil degrades cleanly.
if not GetSpellDescription then
	GetSpellDescription = function() return nil end
end

-- GetSpellTexture: try the stock function first (it returns a renderable icon
-- path for most spells). For the few encounter/target spells where it returns
-- nil, fall back to GetSpellInfo(id)'s icon at return 3 — the same thing DBM
-- uses on 3.3.5 (DBM:GetSpellInfo returns name, rank, icon, ...). Never return
-- nil here: callers treat nil as "no icon" and skip rendering.
--
-- Taint: never replace the client global itself. Blizzard's action bars, unit
-- frames, buff frame and tooltips all call GetSpellTexture; wrapping the global
-- with addon code taints every one of those secure code paths and surfaces as
-- "Модификация BigWigs заблокирована" on any protected action (targeting,
-- focusing, casting) later in the fight. Expose the wrapper under a private
-- BigWigs name instead and bind it to a local where it is used.
do
	local originalGetSpellTexture = GetSpellTexture
	function BigWigsGetSpellTexture(id)
		if originalGetSpellTexture then
			local tex = originalGetSpellTexture(id)
			if tex then return tex end
		end
		local _, _, icon = GetSpellInfo(id)
		return icon
	end
end

-- IsEncounterInProgress: not available on 3.3.5. Do not create it as a global:
-- the custom Nozdor FrameXML does `if IsEncounterInProgress then` checks and a
-- false-returning stub can silently send Blizzard UI code down the wrong path.
-- Expose it privately for BigWigs callers instead.
BigWigsAPI.IsEncounterInProgress = IsEncounterInProgress or function() return false end

-- IsSpellKnown: guarded here so callers never hit a nil global.
if not IsSpellKnown then
	IsSpellKnown = function() return false end
end

--------------------------------------------------------------------------------
-- Nozdor 3.3.5 compatibility: modern "C_*" namespaces the client does not
-- provide. Installed only when the global is MISSING, so anything the client
-- (or another addon) already defines is left untouched.
--------------------------------------------------------------------------------

-- C_ChatInfo: deliberately NOT created or patched here. Writing into the shared
-- C_ChatInfo namespace leaks into every other addon, and replacing
-- C_ChatInfo.SendAddonMessage (which BigWigs/LittleWigs and DBM-style messages
-- all go through) would change addon comms for the whole UI.
--
-- The 3.3.5 Nozdor AddonComm has no "INSTANCE_CHAT" distribution and throws
-- "Unknown addon chat type" for it, so the normalization BigWigs needs lives in
-- BigWigsLoader's private CompatSendAddonMessage wrapper (Loader.lua), which is
-- what every plugin actually binds and calls.

-- C_CVar: 3.3.5 exposes GetCVar/SetCVar as plain globals. NEVER create or write
-- this global here: this client's SharedXML/FunctionOverride.lua GetCVar() reads
-- the global C_CVar, so an addon-written table (or field) taints every Blizzard
-- GetCVar caller and later surfaces as "<addon> is blocked from an action only
-- available to the Blizzard UI". Callers use the plain globals directly.

-- C_Map: no open-world map API on 3.3.5; callers already guard nils.
-- (The client provides parts of C_Map, so only fill what is missing.)
if not C_Map then
	C_Map = {}
end
if not C_Map.GetBestMapForUnit then
	C_Map.GetBestMapForUnit = function() return nil end
end
if not C_Map.GetMapInfo then
	C_Map.GetMapInfo = function() return nil end
end

-- C_Timer: normally provided by the client, but fill any missing method with a
-- frame-based scheduler. Returns timer objects with :Cancel() like the real API.
if not C_Timer then
	C_Timer = {}
end
do
	local frame = CreateFrame("Frame")
	frame:Hide()
	local jobs = {}
	local nextId = 0
	local function schedule(delay, func, count)
		nextId = nextId + 1
		local j = {
			id = nextId,
			due = GetTime() + delay,
			interval = delay,
			func = func,
			count = count,
		}
		j.Cancel = function(self) jobs[self.id] = nil end
		jobs[j.id] = j
		frame:Show()
		return j
	end
	frame:SetScript("OnUpdate", function(self, elapsed)
		local now = GetTime()
		for id in pairs(jobs) do
			local j = jobs[id]
			if now >= j.due then
				if j.count then
					j.count = j.count - 1
					if j.count <= 0 then
						jobs[id] = nil
					else
						j.due = j.due + j.interval
					end
				else
					jobs[id] = nil
				end
				j.func()
			end
		end
		if not next(jobs) then
			self:Hide()
		end
	end)
	if not C_Timer.After then
		C_Timer.After = function(delay, func) return schedule(delay, func, nil) end
	end
	if not C_Timer.NewTicker then
		C_Timer.NewTicker = function(delay, func, count) return schedule(delay, func, count) end
	end
	if not C_Timer.NewTimer then
		C_Timer.NewTimer = function(delay, func) return schedule(delay, func, 1) end
	end
end

-- C_Spell: only used by BigWigs_Options for spell-data prefetch. Keep it
-- private: a global stub makes the custom FrameXML's `if C_Spell then` checks
-- take a modern path that expects real spell data on 3.3.5.
do
	local realCSpell = C_Spell
	BigWigsAPI.C_Spell = {
		IsSpellDataCached = (realCSpell and realCSpell.IsSpellDataCached) or function() return true end,
		RequestLoadSpellData = (realCSpell and realCSpell.RequestLoadSpellData) or function() end,
	}
end

-- ElvUI nameplates flip onto the modern driver path whenever C_NamePlate is
-- truthy (INP = C_NamePlate and true). Stubbing C_NamePlate here made INP
-- true while GetNamePlateForUnit/GetNamePlates returned nil, so ElvUI's
-- NAME_PLATE_UNIT_ADDED never found a frame and every nameplate disappeared.
-- Leave the client namespace absent so ElvUI keeps its working 3.3.5 fallback.
-- The same rule applies to every C_* namespace: on this custom client the
-- FrameXML is partially modernized and does `if C_Foo then` checks, so a
-- truthy empty stub can silently send Blizzard code down a broken path.
-- BigWigs callers guard these namespaces themselves instead.

-- Nozdor 3.3.5: EJ_GetTierInfo (retail Encounter-Journal API, used to label the
-- expansion tiers in the BigWigs options tree) does not exist here. The raid /
-- dungeon tree calls it unguarded, so it would crash the whole tab and the
-- "Raid Bosses"/"Dungeons" sections would never render. Provide an equivalent
-- that returns a localized expansion name for the tier index.
if not EJ_GetTierInfo then
	local EJ_GetTierInfoNames = {
		{ -- enUS fallback
			[1] = "Classic", [2] = "The Burning Crusade", [3] = "Wrath of the Lich King",
			[4] = "Cataclysm", [5] = "Mists of Pandaria", [6] = "Warlords of Draenor",
			[7] = "Legion", [8] = "Battle for Azeroth", [9] = "Shadowlands",
		},
		ruRU = {
			[1] = "Классика", [2] = "Пылающий клинок", [3] = "Гнев Короля-лича",
			[4] = "Катаклизм", [5] = "Туман Пандарии", [6] = "Дренаор",
			[7] = "Легион", [8] = "Битва за Азерот", [9] = "Темные земли",
		},
	}
	local tierNames = EJ_GetTierInfoNames[GetLocale()] or EJ_GetTierInfoNames[1]
	EJ_GetTierInfo = function(tier)
		return tierNames[tier]
	end
end

--------------------------------------------------------------------------------
-- Nozdor 3.3.5 group / role / spec API shims.
-- 3.3.5 predates GetNumGroupMembers, IsInRaid, IsInGroup, UnitGroupRolesAssigned
-- and GetSpecialization. BigWigs calls all of them from the boss-enable path
-- (Core.lua, BossPrototype.lua IterateGroup), so a single missing global made
-- every encounter throw before any bar could be created -> no indicators.
--------------------------------------------------------------------------------

if not GetNumGroupMembers then
	GetNumGroupMembers = function()
		if GetNumRaidMembers and GetNumRaidMembers() > 0 then
			return GetNumRaidMembers()
		end
		if GetNumPartyMembers then
			return GetNumPartyMembers() + 1
		end
		return 0
	end
end

if not IsInRaid then
	IsInRaid = function()
		return (GetNumRaidMembers and GetNumRaidMembers() > 0) and true or false
	end
end

if not IsInGroup then
	IsInGroup = function()
		if GetNumRaidMembers and GetNumRaidMembers() > 0 then return true end
		if GetNumPartyMembers and GetNumPartyMembers() > 0 then return true end
		return false
	end
end

if not UnitGroupRolesAssigned then
	UnitGroupRolesAssigned = function(unit)
		local symbol = "MAINTANK"
		if GetPartyAssignment and GetPartyAssignment(symbol, unit) then
			return "TANK"
		end
		return "NONE"
	end
end

-- GetSpecialization / GetSpecializationRole are absent on 3.3.5 and every
-- BigWigs caller already guards them (`if GetSpecialization then ... end`).
-- Do NOT create them globally: other addons (WeakAuras, Bartender, HealBot)
-- also do `if GetSpecialization then` and would silently take a modern path
-- that expects a real spec id, then receive nil from the stub.

-- IsLoggedIn is 4.x+. core:Enable() calls it unconditionally, and a nil call
-- there aborted the enable sequence, leaving BigWigs disabled forever.
if not IsLoggedIn then
	IsLoggedIn = function() return true end
end

-- 3.3.5 has no IsEventRegistered (added in MoP). It is NOT added to the global
-- frame prototype here: patching RegisterEvent/UnregisterEvent for every widget
-- in the game also patched every ElvUI frame, which broke ElvUI's settings
-- (missing menu entries / unrendered text). BossBlock, the only caller, uses a
-- local fallback instead.
