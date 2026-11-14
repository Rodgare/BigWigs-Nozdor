
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Loken", 602, 600)
if not mod then return end
mod:RegisterEnableMob(28923)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192762, -- Arc Lightning
		192765, -- Lightning Flash
		192760, -- Shockwave
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ArcLightning", 192762)
	self:Log("SPELL_CAST_START", "LightningFlash", 192765)
	self:Log("SPELL_DAMAGE", "Shockwave", 192760)
	self:Log("SPELL_MISSED", "Shockwave", 192760)

	self:Death("Win", 28923)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ArcLightning(args)
	self:Message(args.spellId, "yellow", "Info", CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 24)
end

function mod:LightningFlash(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 5)
	self:CDBar(args.spellId, 24)
end

do
	local prev = 0
	function mod:Shockwave(args)
		if self:Me(args.destGUID) or self:Tank() then
			local t = GetTime()
			if t - prev > 8 then
				prev = t
				self:Message(args.spellId, "orange", "Alert")
			end
		end
	end
end
