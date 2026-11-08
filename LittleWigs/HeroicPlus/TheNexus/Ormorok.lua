
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Ormorok the Tree-Shaper", 576, 620)
if not mod then return end
mod:RegisterEnableMob(26794)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192542, -- Stomp
		192543, -- Spell Reflection
		192546, -- Frenzy
		47981, -- Spell Reflection (3.3.5 spell id)
		48017, -- Frenzy (3.3.5 spell id)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Stomp", 192542)
	self:Log("SPELL_CAST_START", "SpellReflection", 192543)
	self:Log("SPELL_AURA_APPLIED", "SpellReflection", 47981)
	self:Log("SPELL_AURA_REMOVED", "SpellReflectionRemoved", 47981)
	self:Log("SPELL_CAST_SUCCESS", "Frenzy", 48017, 57086)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 192546)

	self:Death("Win", 26794)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Stomp(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 12)
end

function mod:SpellReflection(args)
	self:Message(args.spellId, "yellow")
	self:Bar(args.spellId, 8)
end

function mod:SpellReflectionRemoved(args)
	self:StopBar(args.spellName)
end

function mod:Frenzy(args)
	self:Message(args.spellId, "red", "Warning")
end
