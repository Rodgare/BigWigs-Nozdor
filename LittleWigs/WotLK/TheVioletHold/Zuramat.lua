local mod = BigWigs:NewBoss("Zuramat the Obliterator", 608)
if not mod then return end
mod.partyContent = true
mod:RegisterEnableMob(29314, 32230)
mod.toggleOptions = {
	{54361, "FLASH"}, -- Void Shift
}

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "VoidShift", 54361, 59743)
	self:Death("Win", 29314, 32230)
end

function mod:VoidShift(args)
	self:TargetMessage(args.spellId, args.destName, "blue", "Warning", args.spellName)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
	end
end
