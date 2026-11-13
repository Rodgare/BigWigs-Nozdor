--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Utgarde Pinnacle Trash", 575)
if not mod then return end
mod.displayName = CL.trash
mod:RegisterEnableMob(
	26536, -- Mindless Servant
	26550, -- Dragonflayer Deathseer
	26553, -- Dragonflayer Fanatic
	26554, -- Dragonflayer Seer
	26555, -- Scourge Hulk
	26669, -- Ymirjar Savage
	26670, -- Ymirjar Flesh Hunter
	26672, -- Bloodthirsty Tundra Wolf
	26690, -- Ymirjar Warrior
	26691, -- Ymirjar Witch Doctor
	26692, -- Ymirjar Harpooner
	26694, -- Ymirjar Dusk Shaman
	26696, -- Ymirjar Berserker
	27228, -- Jormungar Tunneler
	28368, -- Ymirjar Necromancer
	53113, -- Wretched Soul (affix add)
	53114 -- Keystone Affix
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.dragonflayer = "Dragonflayer"
	L.ymirjar = "Ymirjar"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Dragonflayer ]]--
		191600, -- Funeral Cleave
		191602, -- Funeral Cleave
		191605, -- Madness of Loyalty
		191606, -- Madness of Loyalty
		191607, -- Fanatic's Leap
		191611, -- Chain Lightning
		191613, -- Storm's Omen
		191617, -- Stone Strike
		191622, -- Rotten Eruption
		191661, -- Numbing Grasp
		191662, -- Numbing Grasp

		--[[ Ymirjar ]]--
		191625, -- Sweeping Axe
		191631, -- Devouring Strike
		191634, -- Call of Blood
		191636, -- Call of Blood
		191637, -- Call of Blood
		191638, -- Hamstring Pursuit
		191640, -- Hamstring Pursuit
		191641, -- Twilight Restoration
		191643, -- Spirit of Winter's Hunt
		191649, -- Whirlwind of Fury
		191657, -- Dead Cold Volley
		191658, -- Dead Cold Volley
		191659, -- Raise Servants
		192614, -- Shadow Bolt
		192615, -- Shrink
		192616 -- Harpoon Throw
	}, {
		[191600] = L.dragonflayer,
		[191625] = L.ymirjar,
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")

	self:Log("SPELL_CAST_START", "TrashCast",
		191600, 191605, 191607,
		191611, 191613, 191617, 191622, 191661,
		191625, 191631, 191634, 191638, 191641, 191643,
		191649, 191657, 191659,
		192614, 192615, 192616
	)

	self:Log("SPELL_AURA_APPLIED", "TrashAura",
		191602, 191606, 191636, 191637, 191640,
		191658, 191662, 192615
	)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrashCast(args)
	local id = args.spellId
	self:Message(id, "yellow", nil, CL.casting:format(args.spellName))

	if id == 191657 then -- Dead Cold Volley
		self:CDBar(id, 15)
	elseif id == 192616 then -- Harpoon Throw
		self:CDBar(id, 6)
	elseif id == 192614 or id == 192615 then -- Shadow Bolt, Shrink
		self:CDBar(id, 10)
	elseif id == 191631 then -- Devouring Strike
		self:CDBar(id, 8)
	end
end

function mod:TrashAura(args)
	local id = args.spellId
	if id == 191606 or id == 191636 then -- Madness of Loyalty, Call of Blood (self)
		self:Message(id, "yellow")
	elseif id == 191602 or id == 191637 or id == 191640 or id == 191658 or id == 191662 or id == 192615 then
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "orange", "Alert", nil, nil, true)
		end
	end
end
