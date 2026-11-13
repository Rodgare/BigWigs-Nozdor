
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("King Ymiron", 575, 644)
if not mod then return end
mod:RegisterEnableMob(26861)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192619, -- Bane
		192621, -- Black Wound
		192622, -- Fetid Rot
		192623, -- Cries of the Dead
		192626, -- Spirit Strike
		192627, -- Spirit Burst
		48585, -- Drought (Vengeful Spirit)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Cast", 192621, 192622, 192626, 192627)
	self:Log("SPELL_AURA_APPLIED", "BaneApplied", 192619)
	self:Log("SPELL_AURA_REMOVED", "BaneRemoved", 192619)
	self:Log("SPELL_AURA_APPLIED", "CriesOfTheDead", 192623)
	self:Log("SPELL_AURA_APPLIED", "Drought", 48585)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Drought", 48585)

	self:Death("Win", 26861)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Cast(args)
	local id = args.spellId
	local sound
	if id == 192622 then
		sound = "Alert"
	elseif id == 192626 or id == 192627 then
		sound = "Warning"
	end
	local color = sound == "Alert" and "orange" or sound == "Warning" and "orange" or "yellow"

	self:Message(id, color, sound, CL.casting:format(args.spellName))

	if id == 192622 then -- Fetid Rot
		self:CDBar(id, 15)
	elseif id == 192621 then -- Black Wound
		self:CDBar(id, 18)
	end
end

function mod:BaneApplied(args)
	if self:MobId(args.destGUID) == 26861 then -- Boss only
		self:Message(args.spellId, "orange", "Info")
		self:Bar(args.spellId, 2)
	end
end

function mod:BaneRemoved(args)
	if self:MobId(args.destGUID) == 26861 then -- Boss only
		self:Message(args.spellId, "green", nil, CL.over:format(args.spellName))
		self:StopBar(args.spellName)
	end
end

function mod:CriesOfTheDead(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "orange", "Alert", nil, nil, true)
	end
end

function mod:Drought(args)
	if self:Me(args.destGUID) or self:Tank() then
		local stacks = args.amount or 1
		self:StackMessage(args.spellId, args.destName, stacks, "orange", "Alert")
	end
end
