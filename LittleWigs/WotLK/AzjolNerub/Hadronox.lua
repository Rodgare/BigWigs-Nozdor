-------------------------------------------------------------------------------
--  Module Declaration

local mod, CL = BigWigs:NewBoss("Hadronox", 601, 586)
if not mod then return end
mod:RegisterEnableMob(28921)
-- mod.engageId = 1972 -- ENCOUNTER_START fires when you enter the area, not when you actually pull the boss. Also it doesn't get assigned a boss1 unit.

-------------------------------------------------------------------------------
--  Initialization

function mod:GetOptions()
	return {
		192470, -- Pierced Armor
		192471, -- Acid Cloud
		192473, -- Leech Poison
		192476, -- Web Grab
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "PiercedArmor", 192470)
	self:Log("SPELL_CAST_START", "AcidCloud", 192471)
	self:Log("SPELL_CAST_START", "LeechPoison", 192473)
	self:Log("SPELL_CAST_START", "WebGrab", 192476)
	self:Death("Win", 28921)
end

function mod:OnEngage()
	self:CDBar(192470, 18)
	self:CDBar(192471, 22)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:PiercedArmor(args)
	self:Message(args.spellId, "red", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 20)
end

function mod:AcidCloud(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 20)
end

function mod:LeechPoison(args)
	self:Message(args.spellId, "orange", "Alert", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
end

function mod:WebGrab(args)
	self:Message(args.spellId, "red", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
end
