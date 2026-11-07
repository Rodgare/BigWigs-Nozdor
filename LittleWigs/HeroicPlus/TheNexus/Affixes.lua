
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("The Nexus Affixes", 576)
if not mod then return end
mod.displayName = "The Nexus: Affixes"
mod:RegisterEnableMob(
	53113, -- Wretched Soul
	53114, -- Keystone Affix
	26716, 26727, 26728, 26729, 26730, 26734, 26735, 26737, 26746, 26782, 26792, 26793, 28231, 58941,
	26731, 26763, 26794, 26723, 26796, 26798 -- bosses
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.necrotic = "Necrotic Plague"
	L.wretched = "Wretched Soul"
	L.cry = "Cry of the Wretched Soul"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		83646, -- Necrotic Plague
		192115, -- Wretched Soul (affix debuff)
		192110, -- Cry of the Wretched Soul
	}, {
		[83646] = L.necrotic,
		[192115] = L.wretched,
		[192110] = L.cry,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "NecroticPlague", 83646)
	self:Log("SPELL_AURA_APPLIED_DOSE", "NecroticPlague", 83646)
	self:Log("SPELL_AURA_APPLIED", "WretchedSoul", 192115)
	self:Log("SPELL_CAST_START", "Cry", 192110)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:NecroticPlague(args)
	if self:Me(args.destGUID) then
		local stacks = args.amount or 1
		self:StackMessage(83646, args.destName, stacks, "red", stacks >= 4 and "Warning")
	end
end

function mod:WretchedSoul(args)
	if self:Dispeller("magic") or self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "orange", "Alert", nil, nil, true)
		self:TargetBar(args.spellId, 4, args.destName)
	end
end

function mod:Cry(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 30)
end
