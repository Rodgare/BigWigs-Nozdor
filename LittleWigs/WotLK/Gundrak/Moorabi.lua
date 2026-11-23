
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Moorabi", 604, 594)
if not mod then return end
mod:RegisterEnableMob(29305)
mod.engageId = 1980
mod.respawnTime = 30

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		55098, -- Transformation
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Transformation", 55098)
	self:Log("SPELL_INTERRUPT", "Interrupt", "*")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Transformation(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	-- Cast time is different on each cast, at least on heroic/TW, so prefer the
	-- live remaining time. UnitCastingInfo() can return nothing (unknown unit
	-- token / cast already over); it used to feed a nil endTime into arithmetic
	-- and error on every cast. Fall back to the spell's base cast time.
	local _, _, _, castTime = GetSpellInfo(args.spellId)
	local length = castTime and castTime > 0 and castTime / 1000 or nil
	local _, _, _, _, endTime = UnitCastingInfo("boss1")
	if endTime then
		length = endTime / 1000 - GetTime()
	end
	if length and length > 0 then
		self:Bar(args.spellId, length)
	end
end

function mod:Interrupt(args)
	if args.extraSpellId == 55098 then -- Transformation
		self:Message(55098, "green", nil, CL.interrupted_by:format(args.extraSpellName, self:ColorName(args.sourceName)))
		self:StopBar(args.extraSpellName) -- Name of interrupted spell
	end
end
