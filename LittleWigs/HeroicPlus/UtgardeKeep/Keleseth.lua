-------------------------------------------------------------------------------
--  Module Declaration

local mod, CL = BigWigs:NewBoss("Prince Keleseth", 574, 638)
if not mod then return end
mod:RegisterEnableMob(23953)
mod.engageId = 2026
-- mod.respawnTime = 0 -- resets, doesn't respawn

-------------------------------------------------------------------------------
--  Locals

local lastBoneArmor = 0

-------------------------------------------------------------------------------
--  Initialization

function mod:GetOptions()
	return {
		192400, -- Shadow Bolt
		192402, -- Frost Tomb
		192404, -- Bone Armor
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ShadowBolt", 192400)
	self:Log("SPELL_AURA_APPLIED", "FrostTomb", 192402)
	self:Log("SPELL_AURA_REMOVED", "FrostTombRemoved", 192402)
	self:Log("SPELL_CAST_START", "BoneArmor", 192404)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:ShadowBolt(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 1)
end

function mod:FrostTomb(args)
	self:TargetMessage(args.spellId, args.destName, "red", "Warning", nil, nil, true)
	self:TargetBar(args.spellId, 8, args.destName)
end

function mod:FrostTombRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:BoneArmor(args)
	local now = GetTime()
	if now - lastBoneArmor < 1 then return end
	lastBoneArmor = now

	self:Message(args.spellId, "yellow")
	self:CastBar(args.spellId, 1)
end
