local mod = BigWigs:NewBoss("Lavanthor", 608)
if not mod then return end
mod.partyContent = true
mod:RegisterEnableMob(29312, 32237)
mod.toggleOptions = {"stages"}

function mod:OnBossEnable()
	self:Death("Win", 29312, 32237)
end
