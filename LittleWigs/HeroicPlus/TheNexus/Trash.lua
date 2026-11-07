--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("The Nexus Trash", 576)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	26716, -- Azure Warder
	26727, -- Mage Hunter Ascendant
	26728, -- Mage Hunter Initiate
	26729, -- Steward
	26730, -- Mage Slayer
	26734, -- Azure Inquisitor
	26735, -- Azure Scale-Binder
	26737, -- Mana Surge
	26746, -- Crazed Mana-Wraith
	26782, -- Crystalline Keeper
	26792, -- Crystalline Protector
	26793, -- Crystalline Frayer
	28231, -- Crystalline Tender
	58941, -- Ice Sphere
	53113, -- Wretched Soul (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.slayer = "Mage Slayer"
	L.steward = "Steward"
	L.hunters = "Mage Hunters"
	L.azure = "Azure"
	L.crystals = "Crystalline"
	L.alliance = "Alliance"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Mage Slayer ]]--
		30849, -- Spell Lock
		190206, -- Magic Sense
		190208, -- Arcane Howl

		--[[ Steward ]]--
		47779, -- Arcane Torrent
		190238, -- Spear Throw
		190240, -- Shattered Wind Vial

		--[[ Mage Hunters ]]--
		190209, -- Arcane Arrow
		190211, -- Azure Magic Beam
		190244, -- Arcane Shackles
		190245, -- Suppression Seal

		--[[ Azure ]]--
		190200, -- Azure Crush
		190202, -- Crushing Axe
		190214, -- Arcane Blast
		190213, -- Arcane Projection
		190216, -- Spear Throw
		56969, -- Arcane Blast
		61326, -- Heal

		--[[ Crystalline ]]--
		48053, -- Binding
		48058, -- Crystal Bloom
		48082, -- Shell
		190255, -- Crystal Strike
		190257, -- Crystal Bark
		190261, -- Crystal of Roots
		190259, -- Crystalline Bloom
		190250, -- Sphere Explosion

		--[[ Alliance ]]--
		190222, -- Trap
		190223, -- Ice Trap
		190226, -- Ice Puddle
		190228, -- Blade Whirl
		190232, -- Bleed
		191901, -- Shattered Wind Vial
		190323, -- Ice-Tipped Arrow
		191900, -- Smite
		190233, -- Holy Flash
	}, {
		[30849] = L.slayer,
		[47779] = L.steward,
		[190209] = L.hunters,
		[190200] = L.azure,
		[190255] = L.crystals,
		[190323] = L.alliance,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_AURA_APPLIED", "SpellLock", 30849)
	self:Log("SPELL_AURA_APPLIED", "ArcaneTorrent", 47779)

	self:Log("SPELL_CAST_START", "TrashCast",
		190206, 190208,
		190238, 190240,
		190209, 190211, 190244, 190245,
		190200, 190202, 190214, 190213, 190216,
		56969, 61326,
		190255, 190261, 190259, 190250,
		190323, 191900, 190233
	)

	self:Log("SPELL_CAST_SUCCESS", "TrashCast",
		190211, 190202, 190216,
		48053, 48058
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		48082, 190222, 190223, 190226, 190228, 190232, 191901, 190257
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SpellLock(args)
	if self:Dispeller("magic") or self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "yellow", "Alarm", nil, nil, true)
	end
end

do
	local playerList, isOnMe = mod:NewTargetList(), false

	local function announce(self, spellId)
		if self:Dispeller("magic") or isOnMe then
			self:TargetMessage(spellId, playerList, "orange", "Alert", nil, nil, true)
		else
			wipe(playerList) -- TargetMessage wipes the table; if we don't call it, we should do the same manually
		end
		isOnMe = false
	end

	function mod:ArcaneTorrent(args)
		if bit.band(args.destFlags, 0x400) == 0 then return end -- COMBATLOG_OBJECT_TYPE_PLAYER = 0x400, filtering out pets
		if self:Me(args.destGUID) then
			isOnMe = true
		end
		playerList[#playerList+1] = args.destName
		if #playerList == 1 then
			self:ScheduleTimer(announce, 0.3, self, args.spellId)
		end
	end
end

function mod:TrashCast(args)
	local id = args.spellId
	local sound
	if id == 61326 or id == 190233 or id == 190250 then -- Heal, Holy Flash, Sphere Explosion
		sound = "Warning"
	elseif id == 190200 or id == 56969 or id == 190214 or id == 190244 or id == 190255 or id == 48053 then
		sound = "Alert"
	end
	local color = sound == "Warning" and "red" or sound == "Alert" and "orange" or "yellow"
	self:Message(id, color, sound)

	if id == 190250 then
		self:CDBar(id, 18)
	end
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 48082 or id == 190257 or id == 190228 then -- Shell, Crystal Bark, Blade Whirl
		self:Message(id, "yellow")
	elseif id == 190223 or id == 190226 then -- Ice Trap, Ice Puddle
		if self:Me(args.destGUID) then
			self:Message(id, "orange", "Alarm")
		end
	elseif id == 190222 or id == 191901 then -- Trap, Shattered Wind Vial
		if self:Me(args.destGUID) then
			self:TargetMessage(id, args.destName, "orange", "Alarm")
		else
			self:Message(id, "yellow")
		end
	elseif id == 190232 then -- Bleed
		if self:Me(args.destGUID) or self:Tank("player") then
			self:TargetMessage(id, args.destName, "yellow")
		end
	end
end
