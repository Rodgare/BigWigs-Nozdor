-------------------------------------------------------------------------------
--  Module Declaration
--

local mod, CL = BigWigs:NewBoss("Anub'arakAN", 601, 587) -- AN (Azjol-Nerub) is intentional to prevent conflict with Anub'arak from Trial of the Crusader
if not mod then return end
mod:RegisterEnableMob(29120)
mod.engageId = 1973
mod.respawnTime = 30

-------------------------------------------------------------------------------
--  Locals
--

local nextSubmergeWarning = 80

-------------------------------------------------------------------------------
--  Initialization
--

function mod:GetOptions()
	return {
		192480, -- Pound
		192482, -- Carrion Beetles
		192484, -- Carrion Eaters
		-6359, -- Submerge
	}
end

function mod:OnBossEnable()
	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")
	self:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", nil, "boss1")

	self:Log("SPELL_CAST_START", "Pound", 192480)
	self:Log("SPELL_CAST_SUCCESS", "CarrionBeetles", 192482)
	self:Log("SPELL_CAST_START", "CarrionEaters", 192484)
end

function mod:OnEngage()
	nextSubmergeWarning = 80 -- 75%, 50% and 25%
	self:CDBar(192480, 8)
end

-------------------------------------------------------------------------------
--  Event Handlers
--

function mod:Pound(args)
	self:CastBar(args.spellId, 3)
	self:Message(args.spellId, "yellow", "Warning", CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 50)
end

function mod:CarrionBeetles(args)
	self:Message(args.spellId, "orange", "Alert", args.spellName)
	self:Bar(args.spellId, 2)
end

function mod:CarrionEaters(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
end

function mod:UNIT_TARGETABLE_CHANGED(_, unit)
	-- Submerge
	if UnitCanAttack("player", unit) then
		self:Message(-6359, "cyan", "Info", CL.over:format(self:SpellName(-6359)))
	else
		self:Message(-6359, "cyan", "Info")
		self:Bar(-6359, self:Normal() and 41 or 62)
	end
end

function mod:UNIT_HEALTH_FREQUENT(event, unit)
	local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
	if hp < nextSubmergeWarning then
		self:Message(-6359, "cyan", "Info", CL.soon:format(self:SpellName(-6359))) -- Submerge
		nextSubmergeWarning = nextSubmergeWarning - 25

		while nextSubmergeWarning >= 25 and hp < nextSubmergeWarning do
			-- Account for high-level characters hitting multiple thresholds.
			-- Until at least one Submerge happens, the boss's health can't drop below 1.
			nextSubmergeWarning = nextSubmergeWarning - 25
		end

		if nextSubmergeWarning < 25 then
			self:UnregisterUnitEvent(event, unit)
		end
	end
end
