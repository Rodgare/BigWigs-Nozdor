-------------------------------------------------------------------------------
--  Module Declaration
--

local mod, CL = BigWigs:NewBoss("Krystallus", 599, 604)
if not mod then return end
mod:RegisterEnableMob(27977)
mod.engageId = 1994
--mod.respawnTime = 0 -- resets, doesn't respawn

-------------------------------------------------------------------------------
--  Initialization
--

function mod:GetOptions()
	return {
		191401, -- Boulder Toss
		191407, -- Ground Slam
		191473, -- Shatter
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BoulderToss", 191401)
	self:Log("SPELL_CAST_START", "GroundSlam", 191407)
	self:Log("SPELL_CAST_START", "Shatter", 191473)
end

function mod:OnEngage()
	self:CDBar(191401, 3)
end

-------------------------------------------------------------------------------
--  Event Handlers
--

function mod:BoulderToss(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 10)
end

function mod:GroundSlam(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 32)
end

function mod:Shatter(args)
	self:Message(args.spellId, "red", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 32)
end
