local mod = BigWigs:NewBoss("Hogan Death Herald", 961, 53000)
if not mod then return end
mod:RegisterEnableMob(53000)
mod:SetEncounterID(53000)

local L = mod:NewLocale("enUS", true)
if L then
	L[87005] = "Восстаньте"
	L[87027] = "Погребение Даларана"
	L[87038] = "Метка гнили"
	L[87022] = "Оскверненная душа"
	L[87001] = "Погребальный знак"
	L[87017] = "Похищение души"
	L[87020] = "Разрыв души"
	L[87269] = "Впитанная кровь"

	L.rot_warn = "Метка гнили на вас!"
	L.funeral_warn = "Погребальный знак на вас!"
	L.soul_steal_warn = "Похищение души на вас!"
	L.soul_rend_warn = "Разрыв души на вас!"
	L.corrupt_warn = "Оскверненная душа на вас!"
	L.absorb_warn = "Впитанная кровь на вас!"

	L.rise_bar = "Восстаньте"
	L.nodes_warn = "Скоро перефаза"
	L.nodes_start = "Перефаза 60%"
	L.nodes_end = "Перефаза завершена"
	L.nodes_bar = "Пилары живы: %d/5"
	L.nodes_left = "Узлов осталось: %d"
end
L = mod:GetLocale()

local abilities = {
	{ key = 87038, kind = "personal", color = "orange", sound = "alert", text = L.rot_warn },
	{ key = 87001, kind = "personal", color = "yellow", sound = "warning", text = L.funeral_warn },
	{ key = 87017, kind = "personal", color = "purple", sound = "alert", text = L.soul_steal_warn, flags = { "OFF" } },
	{ key = 87020, kind = "personal", color = "red", sound = "warning", text = L.soul_rend_warn },
	{ key = 87022, kind = "personal", color = "purple", sound = "warning", text = L.corrupt_warn, flags = { "OFF" } },
	{ key = 87269, kind = "personal", color = "orange", sound = "alert", text = L.absorb_warn },
	{ key = 87005, kind = "announce", color = "red", sound = "alert", bar = 48 },
	{ key = 87027, kind = "custom" },
}
DalaranFW:Setup(mod, abilities, { "berserk" })

function mod:OnBossEnable()
	DalaranFW:Enable(self)

	self:Log("SPELL_AURA_APPLIED", "GraveyardStart", 87027)
	self:Log("SPELL_AURA_REMOVED", "GraveyardEnd", 87027)
	self:Death("NodeDied", 53016)
	self:Death("Win", 53000)
end

function mod:OnEngage()
	DalaranFW:Reset(self)
	self.phase = 1
	self.warned65 = nil
	self.nodesRemaining = nil
	self.nodesText = nil

	self:Berserk(481)
	self:Bar(87005, 44, L.rise_bar)
	self:RegisterEvent("UNIT_HEALTH", "CheckPhaseHP")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:CheckPhaseHP(_, unit)
	if unit ~= "boss1" or self.warned65 then return end
	local max = UnitHealthMax("boss1")
	if not max or max <= 0 then return end
	if UnitHealth("boss1") / max <= 0.65 then
		self.warned65 = true
		self:Message("stages", "orange", "warning", L.nodes_warn)
	end
end

function mod:GraveyardStart(args)
	if self:MobId(args.destGUID) ~= 53000 then return end
	if DalaranFW:Dedupe(self, "graveyard_start", args.time, 0.5) then return end

	self.phase = 2
	self.nodesRemaining = 5
	self:StopBar(L.rise_bar)
	self:Message(args.spellId, "cyan", "long", L.nodes_start)
	self:ShowNodesBar()
end

function mod:ShowNodesBar()
	if self.nodesText then self:StopBar(self.nodesText) end
	self.nodesText = string.format(L.nodes_bar, self.nodesRemaining)
	self:Bar(87027, 1e9 + 1, self.nodesText, 87027)
end

function mod:NodeDied()
	if self.phase ~= 2 or not self.nodesRemaining then return end

	self.nodesRemaining = self.nodesRemaining - 1
	if self.nodesRemaining > 0 then
		self:Message(87027, "yellow", nil, string.format(L.nodes_left, self.nodesRemaining))
		self:ShowNodesBar()
	else
		if self.nodesText then self:StopBar(self.nodesText) end
		self.nodesText = nil
		self.nodesRemaining = nil
	end
end

function mod:GraveyardEnd(args)
	if self:MobId(args.destGUID) ~= 53000 then return end
	if DalaranFW:Dedupe(self, "graveyard_end", args.time, 0.5) then return end

	self.phase = 3
	if self.nodesText then
		self:StopBar(self.nodesText)
		self.nodesText = nil
	end
	self.nodesRemaining = nil

	self:Message(args.spellId, "green", nil, L.nodes_end)
	self:Bar(87005, 48, L.rise_bar)
end

function mod:OnBossDisable()
	self:StopBar(L.rise_bar)
	if self.nodesText then
		self:StopBar(self.nodesText)
		self.nodesText = nil
	end
	self.nodesRemaining = nil
end
