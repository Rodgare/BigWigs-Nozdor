local mod = BigWigs:NewBoss("Ichoron", 608)
if not mod then return end
mod.partyContent = true
mod:RegisterEnableMob(29313, 32234)
mod.toggleOptions = {
	54306, -- Bubble
	54312, -- Frenzy
}

local L = mod:GetLocale()
if L then
	L.bubble_end = "Защитный пузырь спал"
	L.bubble_start = "Защитный пузырь"
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Bubble", 54306)
	self:Log("SPELL_AURA_REMOVED", "BubbleRemoved", 54306)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 54312, 59522)
	self:Death("Win", 29313, 32234)
end

function mod:Bubble(args)
	self:Message(args.spellId, "red", "Warning", L.bubble_start)
end

function mod:BubbleRemoved(args)
	self:Message(args.spellId, "green", nil, L.bubble_end)
end

function mod:Frenzy(args)
	self:Message(args.spellId, "red", "Alarm", args.spellName)
end
