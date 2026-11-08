-------------------------------------------------------------------------------
--  Module Declaration

local mod, CL = BigWigs:NewBoss("Krik'thir the Gatewatcher", 601, 585)
if not mod then return end
mod:RegisterEnableMob(28684)
mod.engageId = 1971
mod.respawnTime = 30

-------------------------------------------------------------------------------
--  Initialization

function mod:GetOptions()
	return {
		192450, -- Mind Flay
		192451, -- Curse of Fatigue
		192452, -- Web Wrap
		192459, -- Frenzy
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "MindFlay", 192450)
	self:Log("SPELL_AURA_APPLIED", "CurseOfFatigue", 192451)
	self:Log("SPELL_AURA_REMOVED", "CurseOfFatigueRemoved", 192451)
	self:Log("SPELL_CAST_START", "WebWrap", 192452)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 192459)

	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")
end

function mod:OnEngage()
	self:CDBar(192450, 4)
	self:CDBar(192451, 9)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:MindFlay(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 10)
end

function mod:CurseOfFatigue(args)
	self:TargetMessage(args.spellId, args.destName, "yellow")
	self:TargetBar(args.spellId, 10, args.destName)
	self:CDBar(args.spellId, 16)
end

function mod:CurseOfFatigueRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:WebWrap(args)
	self:Message(args.spellId, "red", "Alert", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
	self:Bar(args.spellId, 20)
end

function mod:Frenzy(args)
	self:Message(args.spellId, "red", nil, CL.percent:format(10, args.spellName))
end

function mod:UNIT_HEALTH_FREQUENT(event, unit)
	local health = UnitHealth(unit) / UnitHealthMax(unit) * 100
	if health > 10 and health <= 15 then
		self:UnregisterUnitEvent(event, unit)
		self:Message(192459, "red", nil, CL.soon:format(self:SpellName(192459))) -- Frenzy
	end
end
