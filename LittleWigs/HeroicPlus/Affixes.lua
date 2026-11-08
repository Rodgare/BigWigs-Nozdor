--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Heroic+ Affixes", 0)
if not mod then return end
mod.displayName = "Heroic+: Affixes"
mod:RegisterEnableMob(
	53113, -- Wretched Soul
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.necrotic = "Necrotic Plague"
	L.wretched = "Wretched Soul"
	L.cry = "Cry of the Wretched Soul"
	L.disembodied = "Disembodied"
	L.destabilization = "Destabilization"
	L.incorporeal = "Incorporeal"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnRegister()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckZone")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckZone")
	self:CheckZone()
end

function mod:CheckZone()
	local _, instanceType = GetInstanceInfo()
	if instanceType == "party" and not self:IsEnabled() then
		self:Enable()
	end
end

function mod:CheckForEncounterEngage()
	-- Global module: do not let boss engage matching disable it.
end

function mod:GetOptions()
	return {
		83646, -- Necrotic Plague
		192115, -- Wretched Soul (affix debuff)
		192110, -- Cry of the Wretched Soul
		192095, -- Disembodied
		192096, -- Destabilization
		192098, -- Incorporeal
	}, {
		[83646] = L.necrotic,
		[192115] = L.wretched,
		[192110] = L.cry,
		[192095] = L.disembodied,
		[192096] = L.destabilization,
		[192098] = L.incorporeal,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "NecroticPlague", 83646)
	self:Log("SPELL_AURA_APPLIED_DOSE", "NecroticPlague", 83646)
	self:Log("SPELL_AURA_APPLIED", "WretchedSoul", 192115)
	self:Log("SPELL_CAST_START", "Cry", 192110)
	self:Log("SPELL_AURA_APPLIED", "AffixAura", 192095, 192098)
	self:Log("SPELL_CAST_START", "Destabilization", 192096)
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

function mod:Destabilization(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 9)
end

function mod:AffixAura(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "orange", "Alert", nil, nil, true)
	end
end
