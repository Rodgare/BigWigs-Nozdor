
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Ionar", 602, 599)
if not mod then return end
mod:RegisterEnableMob(28546)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192750, -- Ball Lightning
		192754, -- Disperse
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BallLightning", 192750)
	self:Log("SPELL_CAST_START", "Disperse", 192754)

	self:Death("Win", 28546)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BallLightning(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
end

function mod:Disperse(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
end
