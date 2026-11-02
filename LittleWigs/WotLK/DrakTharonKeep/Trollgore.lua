--------------------------------------------------------------------------------
--  Module Declaration
--

local mod, CL = BigWigs:NewBoss("Trollgore", 600, 588)
if not mod then return end
mod:RegisterEnableMob(26630)

--------------------------------------------------------------------------------
--  Nozdor custom abilities
--  Сокрушение (192636, ~10s) / Заражённая рана (192637, ~17s)
--  Поглощение (192630, ~20s) / Взрыв трупа (192633, ~20s)
--------------------------------------------------------------------------------

function mod:GetOptions()
	return {
		{192636, "TANK"}, -- Сокрушение
		192637, -- Заражённая рана
		192630, -- Поглощение
		192633, -- Взрыв трупа
	}
end

function mod:OnBossEnable()
	self:Log("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Log("SPELL_AURA_APPLIED",  "InfectedWound", 192637)
	self:Log("SPELL_AURA_REMOVED", "InfectedWoundRemoved", 192637)
	self:Log("SPELL_CAST_SUCCESS", "InfectedWoundCastSuccess", 192637)

	self:Log("SPELL_CAST_SUCCESS", "Crush", 192636)
	self:Log("SPELL_CAST_START",   "Consume", 192630)
	self:Log("SPELL_CAST_START",   "CorpseExplode", 192633)
	self:Death("Win", 26630)
end

function mod:OnEngage()
	self:CDBar(192636, 10) -- Сокрушение
	self:CDBar(192630, 20) -- Поглощение
	self:CDBar(192637, 17) -- Заражённая рана
end

--------------------------------------------------------------------------------
--  Event Handlers
--

function mod:InfectedWound(args)
	if self:Me(args.destGUID) or self:Healer() or self:Dispeller("disease") then
		self:TargetMessage(args.spellId, args.destName, "orange")
		self:TargetBar(args.spellId, 10, args.destName)
	end
end

function mod:InfectedWoundRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:InfectedWoundCastSuccess(args)
	self:CDBar(args.spellId, 17)
end

function mod:Crush(args)
	self:CDBar(args.spellId, 10)
end

function mod:Consume(args)
	self:Message(args.spellId, "yellow")
	self:CDBar(args.spellId, 20)
end

function mod:CorpseExplode(args)
	self:Message(args.spellId, "orange")
	self:CDBar(args.spellId, 20)
end