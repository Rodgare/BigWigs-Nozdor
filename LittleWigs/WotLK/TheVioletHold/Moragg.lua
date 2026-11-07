local mod = BigWigs:NewBoss("Moragg", 608)
if not mod then return end
mod.partyContent = true
mod.otherMenu = "Dalaran"
mod:RegisterEnableMob(29316, 32235)
mod.toggleOptions = {
	54396, -- Optic Link
}

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "OpticLink", 54396)
	self:Death("Win", 29316, 32235)
end

function mod:OpticLink(args)
	local text = args.spellName .. ": " .. args.destName
	self:TargetMessage(args.spellId, args.destName, "red", "Warning", text)
	self:Bar(args.spellId, 12, text)
end
