--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Halls of Stone Trash", 599)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	27960, -- Dark Rune Skycaller
	27961, -- Dark Rune Worker
	27963, -- Dark Rune Runecaster
	27964, -- Dark Rune Scholar
	27965, -- Dark Rune Cutter
	27966, -- Dark Rune Observer
	27972, -- Lightning Construct
	27973, -- Crystalline Frayer
	27974, -- Crystalline Protector
	31216, -- Mirror Image
	53112, -- Disembodied Existence (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.darkrune = "Dark Rune"
	L.construct = "Lightning Construct"
	L.crystal = "Crystalline"
	L.mirror = "Mirror Images"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Dark Rune ]]--
		191200, -- Dark Rune
		191854, -- Dark Rune
		191206, -- Dark Rune
		191288, -- Dark Rune
		191291, -- Dark Rune
		191214, -- Dark Rune
		191216, -- Dark Rune
		191217, -- Dark Rune
		191247, -- Dark Rune
		191250, -- Dark Rune
		191252, -- Dark Rune
		191259, -- Dark Rune
		191262, -- Dark Rune

		--[[ Lightning Construct ]]--
		191243, -- Lightning Construct

		--[[ Mirror Image ]]--
		59637 -- Fire Blast
	}, {
		[191200] = L.darkrune,
		[191243] = L.construct,
		[59637] = L.mirror,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_CAST_START", "TrashCast",
		191200, 191854,
		191214, 191216, 191217,
		191243, 191247, 191250,
		191259, 191288
	)

	self:Log("SPELL_CAST_SUCCESS", "TrashCast",
		191252, 191200, 191854, 59637
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		191206, 191252, 191262, 191291
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrashCast(args)
	local id = args.spellId
	self:Message(id, "yellow", "Info", CL.casting:format(args.spellName))
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 191206 or id == 191252 or id == 191262 then
		self:Message(id, "yellow", "Info")
	elseif id == 191291 then
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "orange", "Alert", nil, nil, true)
		end
	end
end
