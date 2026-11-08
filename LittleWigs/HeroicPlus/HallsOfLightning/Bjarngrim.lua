
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("General Bjarngrim", 602, 597)
if not mod then return end
mod:RegisterEnableMob(28586)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		191773, -- Mighty Blow
		191775, -- Whirlwind
		191780, -- Steel Renewal (Stormforged Lieutenant)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "MightyBlow", 191773)
	self:Log("SPELL_CAST_START", "Whirlwind", 191775)
	self:Log("SPELL_CAST_START", "SteelRenewal", 191780)

	self:Death("Win", 28586)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:MightyBlow(args)
	self:Message(args.spellId, "red", nil, CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 10)
end

function mod:Whirlwind(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
end

function mod:SteelRenewal(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
end
