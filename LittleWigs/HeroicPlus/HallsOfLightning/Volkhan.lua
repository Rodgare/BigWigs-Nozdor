
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Volkhan", 602, 598)
if not mod then return end
mod:RegisterEnableMob(28587)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		191804, -- Shattering Stomp
		191800, -- Forge Golems
		191809, -- Resonance
		191803, -- Searing Strike (Molten Golem)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ShatteringStomp", 191804)
	self:Log("SPELL_CAST_START", "ForgeGolems", 191800)
	self:Log("SPELL_DAMAGE", "Resonance", 191809)
	self:Log("SPELL_MISSED", "Resonance", 191809)
	self:Log("SPELL_AURA_APPLIED", "SearingStrike", 191803)

	self:Death("Win", 28587)
end

function mod:OnEngage()
	self:CDBar(191800, 40)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShatteringStomp(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 4)
end

function mod:ForgeGolems(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 40)
end

function mod:Resonance(args)
	self:Message(args.spellId, "orange", "Alert")
end

function mod:SearingStrike(args)
	if self:Me(args.destGUID) or self:Tank() then
		self:TargetMessage(args.spellId, args.destName, "red", "Alarm", nil, nil, true)
	end
end
