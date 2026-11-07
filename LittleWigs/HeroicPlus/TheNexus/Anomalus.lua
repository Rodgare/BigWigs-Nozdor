
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Anomalus", 576, 619)
if not mod then return end
mod:RegisterEnableMob(26763)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192525, -- Spark
		192526, -- Arcane Attraction
		192527, -- Create Rift
		192532, -- Rift Shield
		192531, -- Rift Charge
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Spark", 192525)
	self:Log("SPELL_CAST_START", "ArcaneAttraction", 192526)
	self:Log("SPELL_CAST_START", "CreateRift", 192527)
	self:Log("SPELL_AURA_APPLIED", "RiftShield", 192532)
	self:Log("SPELL_CAST_SUCCESS", "RiftCharge", 192531)

	self:Death("Win", 26763)
end

function mod:OnEngage()
	self:CDBar(192525, 5) -- Spark
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Spark(args)
	self:Message(args.spellId, "yellow")
	self:CDBar(args.spellId, 20)
end

function mod:ArcaneAttraction(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 19)
end

function mod:CreateRift(args)
	self:Message(args.spellId, "red", "Warning")
	self:CDBar(args.spellId, 44)
end

function mod:RiftShield(args)
	self:Message(args.spellId, "red", "Warning")
	self:Bar(args.spellId, 9)
end

function mod:RiftCharge(args)
	self:Message(args.spellId, "orange")
end
