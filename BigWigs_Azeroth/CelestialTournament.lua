--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Celestial Tournament", -925)
if not mod then return end
mod:RegisterEnableMob(60615, 60612, 60614, 60613) -- Xuen, Yu'lon, Niuzao, Chi-Ji
mod.otherMenu = -947
mod.worldBoss = 60615

--------------------------------------------------------------------------------
-- Locals
--

local L = mod:GetLocale() or {}
local ACTIVE = L.active or "Активен: %s"

local XUEN, YULON, NIUZAO, CHIJI = 60615, 60612, 60614, 60613

local BOSS_NAMES = {
	[XUEN] = "Сюэнь",
	[YULON] = "Юй-лун",
	[NIUZAO] = "Нюцзао",
	[CHIJI] = "Чи-Цзи",
}

local BOSS_ICON = {
	[XUEN] = 83494,
	[YULON] = 83512,
	[NIUZAO] = 83496,
	[CHIJI] = 83509,
}

local ALL_SPELLS = {
	83492, 83493, 83494, 83813, 83819,
	83512, 83513, 83514, 83515,
	83495, 83496, 83497, 83498, 83500,
	83509, 83502, 83503, 83507, 83816,
}

local currentBoss = nil

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	local options = {
		"stages",
		83492, 83493, 83494, 83813, 83819,
		83512, 83513, 83514, 83515,
		83495, 83496, 83497, 83498, 83500,
		83509, 83502, 83503, 83507, 83816,
	}
	local headers = {
		["stages"] = "general",
		[83492] = "Сюэнь", [83493] = "Сюэнь", [83494] = "Сюэнь", [83813] = "Сюэнь", [83819] = "Сюэнь",
		[83512] = "Юй-лун", [83513] = "Юй-лун", [83514] = "Юй-лун", [83515] = "Юй-лун",
		[83495] = "Нюцзао", [83496] = "Нюцзао", [83497] = "Нюцзао", [83498] = "Нюцзао", [83500] = "Нюцзао",
		[83509] = "Чи-Цзи", [83502] = "Чи-Цзи", [83503] = "Чи-Цзи", [83507] = "Чи-Цзи", [83816] = "Чи-Цзи",
	}
	local altNames = {}
	for i = 1, #options do
		local id = options[i]
		if type(id) == "number" then
			altNames[id] = tostring(id)
		end
	end
	return options, headers, altNames
end

function mod:OnBossEnable()
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatEnded")

	-- Boss defeated marker (Return of the Celestial)
	self:Log("SPELL_AURA_APPLIED", "CelestialReturned", 83814)

	-- Xuen
	self:Log("SPELL_CAST_SUCCESS", "GhostlyStrike", 83492)
	self:Log("SPELL_CAST_SUCCESS", "Agility", 83494)
	self:Log("SPELL_CAST_START", "XuenCast", 83493, 83813, 83819)
	self:Log("SPELL_CAST_SUCCESS", "XuenCast", 83493, 83813, 83819)

	-- Yu'lon
	self:Log("SPELL_CAST_SUCCESS", "JadeFireStrike", 83512)
	self:Log("SPELL_CAST_START", "JadeFireBreath", 83513)
	self:Log("SPELL_AURA_APPLIED", "JadeFireFlare", 83515)
	self:Log("SPELL_CAST_SUCCESS", "YulonCast", 83514)

	-- Niuzao
	self:Log("SPELL_CAST_START", "Fortitude", 83496)
	self:Log("SPELL_CAST_START", "Charge", 83498)
	self:Log("SPELL_CAST_SUCCESS", "NiuzaoCast", 83495, 83497, 83500)

	-- Chi-Ji
	self:Log("SPELL_CAST_SUCCESS", "CraneCharge", 83509)
	self:Log("SPELL_CAST_SUCCESS", "ChiJiCast", 83502, 83503, 83507, 83816)
end

function mod:OnBossDisable()
	currentBoss = nil
end

--------------------------------------------------------------------------------
-- Helper
--

function mod:Track(guid)
	local id = self:MobId(guid)
	if not BOSS_NAMES[id] then return false end
	if currentBoss ~= id then
		if currentBoss then
			for i = 1, #ALL_SPELLS do
				self:StopBar(ALL_SPELLS[i])
			end
		end
		currentBoss = id
		self:Message("stages", "cyan", "Info", ACTIVE:format(BOSS_NAMES[id]), BOSS_ICON[id])
		if id == XUEN then
			self:CDBar(83492, 10) -- pull:10.8
		elseif id == YULON then
			self:CDBar(83512, 10) -- pull:86.7 (10.0 after engage)
		elseif id == NIUZAO then
			self:CDBar(83496, 7) -- pull:7.0
		elseif id == CHIJI then
			self:CDBar(83509, 12) -- pull:12.1
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GhostlyStrike(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "red")
	self:PlaySound(args.spellId, "warning")
	self:CDBar(args.spellId, 15) -- pull:10.8, 25.9 (15.0)
end

function mod:Agility(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "yellow")
	self:PlaySound(args.spellId, "info")
end

function mod:XuenCast(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "orange")
	self:PlaySound(args.spellId, "alert")
end

function mod:JadeFireStrike(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "orange")
	self:PlaySound(args.spellId, "alert")
	self:CDBar(args.spellId, 20) -- pull:10.0, 30.0 (86.7, 106.7)
end

function mod:JadeFireBreath(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "purple", CL.casting:format(args.spellName))
	self:PlaySound(args.spellId, "long")
	self:CastBar(args.spellId, 2) -- 91.7 -> 93.7
end

function mod:JadeFireFlare(args)
	if not self:Track(args.sourceGUID) then return end
	if self:Me(args.destGUID) then
		self:PersonalMessage(args.spellId)
		self:PlaySound(args.spellId, "alarm")
	end
end

function mod:YulonCast(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "yellow")
	self:PlaySound(args.spellId, "info")
end

function mod:Fortitude(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "cyan", CL.casting:format(args.spellName))
	self:PlaySound(args.spellId, "long")
	self:CastBar(args.spellId, 1.5) -- 159.2 -> 160.7
	self:CDBar(args.spellId, 7) -- 109.1, 116.1 (7.0)
end

function mod:Charge(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "red")
	self:PlaySound(args.spellId, "warning")
	self:CastBar(args.spellId, 3) -- 173.6 -> 176.6
	self:CDBar(args.spellId, 15.6) -- pull:21.4, 37.0
end

function mod:NiuzaoCast(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "yellow")
	self:PlaySound(args.spellId, "info")
end

function mod:CraneCharge(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "orange")
	self:PlaySound(args.spellId, "alert")
	self:CDBar(args.spellId, 15) -- pull:12.1, 27.1 (15.0, 15s channel)
end

function mod:ChiJiCast(args)
	if not self:Track(args.sourceGUID) then return end
	self:Message2(args.spellId, "yellow")
	self:PlaySound(args.spellId, "info")
end

function mod:CelestialReturned(args)
	local id = self:MobId(args.sourceGUID)
	local name = BOSS_NAMES[id]
	if not name then return end
	self:Message("stages", "green", "Long", ("Испытание пройдено: %s"):format(name), BOSS_ICON[id])
	currentBoss = nil
	for i = 1, #ALL_SPELLS do
		self:StopBar(ALL_SPELLS[i])
	end
end

function mod:CombatEnded()
	for i = 1, #ALL_SPELLS do
		self:StopBar(ALL_SPELLS[i])
	end
end
