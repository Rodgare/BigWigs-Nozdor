--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Halls of Lightning Trash", 602)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	28547, -- Raging Vortex
	28578, -- Stormforged Ravager
	28579, -- Stormforged Berserker
	28580, -- Stormforged Skycaller
	28581, -- Stormforged Tactician
	28582, -- Stormforged Healer
	28583, -- Blistering Steamrag
	28584, -- Unbound Firestorm
	28585, -- Slag
	28825, -- Whirlwind
	28826, -- Storm Fury
	28835, -- Stormforged Construct
	28836, -- Stormforged Runeshaper
	28837, -- Stormforged Sentinel
	28838, -- Titanic Warrior
	28920, -- Stormforged Giant
	28961, -- Titanic Warrior
	28965, -- Titanic Stormcaller
	53113, -- Wretched Soul (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.stormforged = "Stormforged"
	L.molten = "Molten"
	L.storm = "Storm"
	L.constructs = "Stormforged Constructs"
	L.titan = "Titanic"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Stormforged ]]--
		191850, -- Shield Slam
		191853, -- Shield Slam
		191300, -- Call Reinforcements
		191302, -- Arc Weld
		191304, -- Reforged Shell
		191392, -- Storm Heal
		191311, -- Hammer Strike
		191312, -- Shock Arrow
		191318, -- Shot
		191319, -- Combat Overheat
		191320, -- Weapon Throw

		--[[ Molten ]]--
		191325, -- Steam Blast
		191335, -- Lava Burst
		191336, -- Destabilize

		--[[ Storm ]]--
		191357, -- Thunderbolt
		191363, -- Lightning

		--[[ Stormforged Constructs ]]--
		191364, -- Charged Flurry
		191367, -- Thunderous Roar
		191369, -- Forked Lightning
		191376, -- Runic Strike
		191383, -- Thunderous Eruption
		191387, -- Soul Strike

		--[[ Titanic ]]--
		191377, -- Charge
		191382, -- Poisoned Spear
		191740, -- Titanic Ram
		191748 -- Throw
	}, {
		[191850] = L.stormforged,
		[191325] = L.molten,
		[191357] = L.storm,
		[191364] = L.constructs,
		[191377] = L.titan,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_CAST_START", "TrashCast",
		191300, 191304, 191312, 191318, 191392,
		191325, 191335, 191336,
		191357, 191363,
		191364, 191367, 191369, 191383,
		191377, 191740, 191748,
		191850
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		191302, 191311, 191319, 191320,
		191376, 191382, 191387,
		191853
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrashCast(args)
	local id = args.spellId
	self:Message(id, "yellow", nil, CL.casting:format(args.spellName))
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 191302 or id == 191311 or id == 191320 or id == 191376 or id == 191382 or id == 191387 or id == 191853 then
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "orange", "Alert", nil, nil, true)
		end
	elseif id == 191319 then
		self:Message(id, "yellow")
	end
end
