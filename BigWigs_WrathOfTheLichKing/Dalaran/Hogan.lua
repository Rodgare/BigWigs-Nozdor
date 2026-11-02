local mod = BigWigs:NewBoss("Hogan Death Herald", 961, 53000)
if not mod then return end
mod:RegisterEnableMob(53000)  -- mob ID босса (из твоего лога GUID ...080000BD / ID)
mod.toggleOptions = { 12345, 12346 }  -- список ID способностей для чекбоксов

local L = mod:NewLocale("enUS", true)
if L then
	L.spell_bar = "Spell (%d)"
	-- Every id in toggleOptions needs a localized title, otherwise the options
	-- panel shows blank checkboxes (and, before the Constants.lua guard, errored).
	L[12345] = "Grave Strike"
	L[12346] = "Death Herald Cry"
end
L = mod:GetLocale()

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SpellOne", 12345)   -- каждая способность
	self:Log("SPELL_CAST_START", "SpellTwo", 12346)
	self:Death("Win", 53000)
end

function mod:OnEngage()
	self:Bar(12345, 15)               -- первый кастбар
end

function mod:SpellOne(args)
	self:MessageOld(args.spellId, "red")
	self:Bar(args.spellId, 30)
end
function mod:SpellTwo(args)
	self:MessageOld(args.spellId, "orange")
	-- self:CdBardol(...) -- при желании
end