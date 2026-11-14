--------------------------------------------------------------------------------
--  Module Declaration
--

local mod, CL = BigWigs:NewBoss("King Dred", 600, 590)
if not mod then return end
mod:RegisterEnableMob(27483)
mod.engageId = 1977

--------------------------------------------------------------------------------
--  Nozdor custom abilities
--  Разрывающий удар (192652, ~17s) / Тяжёлый укус (192650, ~20s)
--  Устрашающий рев (192653, ~21s)  / Проникающий удар (192651, ~37s)
--  Зов ящера (192655, ~58s)
--------------------------------------------------------------------------------

function mod:GetOptions()
	return {
		{192652, "TANK_HEALER"}, -- Разрывающий удар
		192650, -- Тяжёлый укус
		192653, -- Устрашающий рев
		192651, -- Проникающий удар
		192655, -- Зов ящера
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED",  "Rip", 192652)
	self:Log("SPELL_AURA_REMOVED", "RipRemoved", 192652)
	self:Log("SPELL_CAST_SUCCESS", "RipCast", 192652)
	self:Log("SPELL_CAST_START",   "Bite", 192650)
	self:Log("SPELL_CAST_START",   "Roar", 192653)
	self:Log("SPELL_CAST_START",   "Pierce", 192651)
	self:Log("SPELL_CAST_START",   "Raptor", 192655)
end

function mod:OnEngage()
	self:CDBar(192652, 17)
	self:CDBar(192655, 58)
end

function mod:Rip(args)
	if self:Me(args.destGUID) or self:Healer() then
		self:TargetMessage(args.spellId, args.destName, "red", "Alarm", nil, nil, true)
		self:TargetBar(args.spellId, 10, args.destName)
	end
end

function mod:RipRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:RipCast(args)
	self:CDBar(args.spellId, 17)
end

function mod:Bite(args)
	self:Message(args.spellId, "orange", "Warning")
	self:CDBar(args.spellId, 20)
end

function mod:Roar(args)
	self:Message(args.spellId, "red", "Alarm")
	self:CDBar(args.spellId, 21)
end

function mod:Pierce(args)
	self:Message(args.spellId, "orange", "Warning")
	self:CDBar(args.spellId, 37)
end

function mod:Raptor(args)
	self:Message(args.spellId, "yellow", "Info")
	self:CDBar(args.spellId, 58)
end