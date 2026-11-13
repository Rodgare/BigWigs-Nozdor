--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Utgarde Keep Trash", 574)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	23956, -- Dragonflayer Strategist
	23960, -- Dragonflayer Runecaster
	23961, -- Dragonflayer Ironhelm
	24069, -- Dragonflayer Bonecrusher
	24071, -- Dragonflayer Skinner
	24078, -- Dragonflayer Metalworker
	24079, -- Dragonflayer Forge Master
	24080, -- Dragonflayer Weaponsmith
	24082, -- Dragonflayer Handler
	24083, -- Enslaved Proto-Drake
	24084, -- Tunnel Stalker
	24085, -- Dragonflayer Overseer
	28410, -- Dragonflayer Spiritualist
	28419, -- Frenzied Geist
	29735, -- Savage Worg
	53113, -- Wretched Soul (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.dragonflayer = "Dragonflayer"
	L.proto = "Proto-Drake"
	L.undead = "Undead"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Dragonflayer ]]--
		191500, -- Metal Spill
		191506, -- Furnace Blast
		191509, -- Smith's Strike
		191513, -- Heated Weapon
		191515, -- Sharpening Blade
		191517, -- Sharpened Blade
		191518, -- Coated Blade
		191519, -- Coated Blade
		191520, -- Ironhelm
		191521, -- Ironhelm
		191522, -- Ironhelm
		191524, -- Ironhelm
		191525, -- Crossfire
		191527, -- Crossfire
		191528, -- Signal
		191529, -- Signal
		191530, -- Rune of Frost
		191531, -- Runecleave
		191534, -- Runecleave
		191535, -- Bone Crack
		191539, -- Crushing Axe
		191540, -- Crushing Axe
		191541, -- Skin
		191543, -- Skin
		191549, -- Flame Breath
		191560, -- Overseer
		191562, -- Ghostly Bond
		191565, -- Ghostly Bond

		--[[ Proto-Drake ]]--
		191551, -- Burning Breath
		191555, -- Fire Spit

		--[[ Undead ]]--
		191576, -- Convulsive Leap
		191580, -- Dead Grip
		191581, -- Dead Grip
		191582, -- Rending Bite
		191583 -- Rending Bite
	}, {
		[191500] = L.dragonflayer,
		[191551] = L.proto,
		[191576] = L.undead,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_CAST_START", "TrashCast",
		191500, 191506,
		191509, 191513,
		191515, 191518,
		191520, 191522,
		191525, 191528,
		191530, 191531,
		191535, 191539,
		191541, 191543,
		191549, 191551, 191555,
		191560, 191562, 191565,
		191576, 191580, 191582
	)

	self:Log("SPELL_CAST_SUCCESS", "TrashCast",
		191521, 191507, 191517, 191519, 191524, 191529, 191534, 191540, 191583
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		191517, 191519, 191524, 191527, 191529, 191534, 191540, 191581, 191583
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrashCast(args)
	local id = args.spellId
	self:Message(id, "yellow", nil, CL.casting:format(args.spellName))

	if id == 191551 then -- Burning Breath
		self:CDBar(id, 19)
	elseif id == 191555 then -- Fire Spit
		self:CDBar(id, 22)
	elseif id == 191506 then -- Furnace Blast
		self:CDBar(id, 20)
	end
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 191517 or id == 191519 or id == 191524 or id == 191529 or id == 191534 or id == 191540 or id == 191583 then
		self:Message(id, "yellow")
	elseif id == 191527 or id == 191581 then
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "orange", "Alert", nil, nil, true)
		end
	end
end
