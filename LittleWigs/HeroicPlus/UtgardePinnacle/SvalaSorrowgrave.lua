
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Svala Sorrowgrave", 575, 641)
if not mod then return end
mod:RegisterEnableMob(26668, 29281)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192571, -- Summon Flame
		192573, -- Ritual of the Sword
		192574, -- Ritual of the Sword (victim)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SummonFlame", 192571)
	self:Log("SPELL_CAST_START", "RitualOfTheSword", 192573)
	self:Log("SPELL_AURA_APPLIED", "RitualVictim", 192574)

	self:Death("Win", 26668, 29281)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SummonFlame(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
end

function mod:RitualOfTheSword(args)
	self:Message(args.spellId, "orange", "Info")
	self:Bar(args.spellId, 24, CL.cast:format(args.spellName))
	self:CDBar(args.spellId, 36)
end

function mod:RitualVictim(args)
	self:TargetMessage(args.spellId, args.destName, "red", "Alarm", nil, nil, true)
end
