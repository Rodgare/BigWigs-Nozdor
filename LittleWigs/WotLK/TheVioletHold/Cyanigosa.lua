local mod = BigWigs:NewBoss("Cyanigosa", 608)
if not mod then return end
mod.partyContent = true
mod.otherMenu = "Dalaran"
mod:RegisterEnableMob(31134)
mod.toggleOptions = {
	{58693, "FLASH"}, -- Blizzard
	59374, -- Destruction
}

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Blizzard", 58693, 59369)
	self:Log("SPELL_AURA_APPLIED", "Destruction", 59374)
	self:Log("SPELL_AURA_REMOVED", "DestructionRemoved", 59374)
	self:Death("Win", 31134)
end

function mod:Blizzard(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(58693)
		self:Flash(58693)
	end
end

function mod:Destruction(args)
	local text = args.destName .. ": " .. args.spellName
	self:Message(args.spellId, "red", "Warning", text)
	self:Bar(args.spellId, 8, text)
end

function mod:DestructionRemoved(args)
	self:StopBar(args.destName .. ": " .. args.spellName)
end
