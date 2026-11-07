local mod = BigWigs:NewBoss("Xevozz", 608)
if not mod then return end
mod.partyContent = true
mod:RegisterEnableMob(29266, 32231)
mod.toggleOptions = {
	54102, -- Summon Sphere
}

local L = mod:GetLocale()
if L then
	L.sphere = "Призыв эфирной сферы"
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Sphere", 54102, 54137, 54138, 61337, 61338)
	self:Death("Win", 29266, 32231)
end

function mod:Sphere(args)
	self:Message(args.spellId, "red", "Warning", L.sphere)
end
