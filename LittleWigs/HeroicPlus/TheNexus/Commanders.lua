
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Commander Kolurg/Stoutbeard", 576, UnitFactionGroup("player") == "Horde" and 617 or 833)
if not mod then return end
mod:RegisterEnableMob(26798, 26796) -- Commander Kolurg, Commander Stoutbeard

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192503, -- Whirlwind
		192504, -- Whirlwind (aura)
		192500, -- Charge
		192506, -- Intimidating Shout
		192507, -- Battle Shout
		38618, -- Whirlwind (3.3.5 spell id)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Whirlwind", 192503, 38618)
	self:Log("SPELL_AURA_APPLIED", "WhirlwindAura", 192504)
	self:Log("SPELL_CAST_START", "Charge", 192500)
	self:Log("SPELL_CAST_START", "IntimidatingShout", 192506)
	self:Log("SPELL_CAST_START", "BattleShout", 192507)

	self:Death("Win", 26798, 26796)
end

function mod:OnEngage()
	self:CDBar(192507, 3) -- Battle Shout
	self:CDBar(192503, 12) -- Whirlwind
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Whirlwind(args)
	self:Message(args.spellId, "orange", "Info")
	self:CDBar(192503, 24)
end

function mod:WhirlwindAura(args)
	self:Message(args.spellId, "yellow", "Info")
end

function mod:Charge(args)
	self:Message(args.spellId, "yellow", "Warning")
end

function mod:IntimidatingShout(args)
	self:Message(args.spellId, "orange", "Warning")
end

function mod:BattleShout(args)
	self:Message(args.spellId, "yellow", "Info")
	self:CDBar(192507, 24)
end
