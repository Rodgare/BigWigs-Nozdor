-------------------------------------------------------------------------------
--  Module Declaration

local mod, CL = BigWigs:NewBoss("Ingvar the Plunderer", 574, 640)
if not mod then return end
mod:RegisterEnableMob(23954)
--mod.engageId = 2025 -- no ENCOUNTER_END on a successful kill
--mod.respawnTime = 30

-------------------------------------------------------------------------------
--  Locals

local deaths = 0

-------------------------------------------------------------------------------
--  Initialization

function mod:GetOptions()
	return {
		"stages",
		192427, -- Smash
		192429, -- Staggering Roar
		192430, -- Enrage
		192431, -- Woe Strike
		192432, -- Dark Smash
		192434, -- Dreadful Roar
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Log("SPELL_CAST_START", "Smash", 192427)
	self:Log("SPELL_CAST_START", "Roar", 192429)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 192430)
	self:Log("SPELL_CAST_START", "DarkSmash", 192432)
	self:Log("SPELL_AURA_APPLIED", "WoeStrike", 192431)
	self:Log("SPELL_AURA_REMOVED", "WoeStrikeRemoved", 192431)
	self:Log("SPELL_CAST_START", "DreadfulRoar", 192434)

	self:Death("Deaths", 23954)
end

function mod:OnEngage()
	deaths = 0
	self:Message("stages", "cyan", nil, CL.stage:format(1), false)
	self:CDBar(192427, 7)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:Smash(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
	self:CDBar(args.spellId, 16)
end

function mod:Roar(args)
	self:Message(args.spellId, "red", self:Ranged() and "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 20)
end

function mod:Enrage(args)
	self:Message(args.spellId, "red", "Warning")
end

function mod:DarkSmash(args)
	self:Message(args.spellId, "red", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2.5)
	self:CDBar(args.spellId, 18)
end

function mod:WoeStrike(args)
	if self:Me(args.destGUID) or self:Healer() or self:Dispeller("curse") then
		self:TargetMessage(args.spellId, args.destName, "orange", "Alarm", nil, nil, true)
		self:TargetBar(args.spellId, 8, args.destName)
	end
	self:CDBar(args.spellId, 13)
end

function mod:WoeStrikeRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:DreadfulRoar(args)
	self:Message(args.spellId, "red", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2.5)
end

function mod:Deaths()
	deaths = deaths + 1
	if deaths == 2 then
		self:Win()
	else
		self:StopBar(192427) -- Smash
		self:StopBar(192429) -- Staggering Roar
		self:Bar("stages", 20, CL.stage:format(2), "spell_shadow_raisedead")
		self:DelayedMessage("stages", 20, "cyan", CL.stage:format(2))
	end
end
