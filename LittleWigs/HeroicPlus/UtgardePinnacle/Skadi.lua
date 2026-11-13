
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Skadi the Ruthless", 575, 643)
if not mod then return end
mod:RegisterEnableMob(26693)
mod.engageId = 2029
mod.respawnTime = 30

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192606, -- Smash
		192607, -- Poisoned Dart
		192609, -- Whirlwind
		192610, -- Whirlwind (aura)
		192611, -- Whirlwind (damage)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Smash", 192606)
	self:Log("SPELL_CAST_START", "PoisonedDart", 192607)
	self:Log("SPELL_CAST_START", "Whirlwind", 192609)
	self:Log("SPELL_AURA_APPLIED", "WhirlwindAura", 192610)
	self:Log("SPELL_DAMAGE", "WhirlwindDamage", 192611)
	self:Log("SPELL_MISSED", "WhirlwindDamage", 192611)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Smash(args)
	self:Message(args.spellId, "orange", "Alert", CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 10)
end

function mod:PoisonedDart(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CDBar(args.spellId, 19)
end

function mod:Whirlwind(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 24)
end

function mod:WhirlwindAura(args)
	self:Message(args.spellId, "yellow")
end

do
	local prev = 0
	function mod:WhirlwindDamage(args)
		if self:Me(args.destGUID) then
			local t = GetTime()
			if t - prev > 1.5 then
				prev = t
				self:Message(192609, "red", "Alarm", CL.underyou:format(args.spellName))
			end
		end
	end
end
