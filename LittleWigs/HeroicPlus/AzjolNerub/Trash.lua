--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Azjol-Nerub Trash", 601)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	28729, -- Anub'ar Watcher
	28730, -- Anub'ar Guardian
	28731, -- Anub'ar Webspinner
	28732, -- Anub'ar Warrior
	28733, -- Anub'ar Shadowcaster
	28734, -- Anub'ar Skirmisher
	29128, -- Anub'ar Prime Guard
	29335, -- Anub'ar Webspinner
	53113, -- Wretched Soul (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.watchers = "Watchers"
	L.warriors = "Warriors"
	L.casters = "Casters"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Anub'ar Watchers ]]--
		192453, -- Web Shot
		192460, -- Shadow Strike
		192465, -- Shadow Strike

		--[[ Anub'ar Warriors ]]--
		191000, -- Bone Shield
		192461, -- Bone Shield

		--[[ Anub'ar Casters ]]--
		191005, -- Shadow Bolt
		191006, -- Shadow Bolt
		191009, -- Curse of Agony
		191012, -- Mind Flay
		191013, -- Web Wrap
		191016, -- Web Wrap
		192462, -- Poison Spray

		--[[ Anub'ar Prime Guard ]]--
		191050 -- Shield Slam
	}, {
		[192453] = L.watchers,
		[191000] = L.warriors,
		[191005] = L.casters,
		[191050] = L.warriors,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_CAST_START", "TrashCast",
		191005, 191006, 191009, 191012, 191013, 191016,
		192453, 192460, 192462, 191050
	)

	self:Log("SPELL_CAST_SUCCESS", "TrashCast",
		191000, 192461
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		191000, 192461, 192465
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrashCast(args)
	local id = args.spellId
	local sound
	if id == 192453 or id == 191013 or id == 191016 then -- Web Shot, Web Wrap
		sound = "Warning"
	elseif id == 191050 or id == 192460 then -- Shield Slam, Shadow Strike
		sound = "Alert"
	end
	local color = sound == "Warning" and "red" or sound == "Alert" and "orange" or "yellow"

	self:Message(id, color, sound, CL.casting:format(args.spellName))
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 191000 or id == 192461 then -- Bone Shield
		self:Message(id, "yellow")
	elseif id == 192465 then -- Shadow Strike
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "orange", "Alarm", nil, nil, true)
		end
	end
end
