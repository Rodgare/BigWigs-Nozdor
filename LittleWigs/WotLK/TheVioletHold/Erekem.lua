local mod, CL = BigWigs:NewBoss("Erekem", 608)
if not mod then return end
mod.partyContent = true
mod:RegisterEnableMob(29315, 32226)
mod.toggleOptions = {
	54481, -- Chain Heal
}

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ChainHeal", 54481, 59473)
	self:Death("Win", 29315, 32226)
end

function mod:ChainHeal(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
end
