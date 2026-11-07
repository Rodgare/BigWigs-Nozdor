local mod = BigWigs:NewBoss("Hogan Death Herald", 961, 53000)
if not mod then return end
mod:RegisterEnableMob(53000)
mod.toggleOptions = {
    87005,
    87027,
    {87038, "ME_ONLY", "FLASH"},
    87022,
    87001,
    {87017, "ME_ONLY"},
    {87020, "ME_ONLY", "FLASH"},
    87262,
    87019,
    "berserk"
}
mod.defaultDB = {
    [87017] = false,
}

local L = mod:NewLocale("enUS", true)
if L then
    L[87005] = "Восстаньте" -- +
    L[87027] = "Погребение Даларана" -- +
    L[87038] = "Метка гнили" -- +
    L[87022] = "Оскверненная душа"
    L[87001] = "Погребальный знак" --+
    L[87017] = "Похищение души" -- +
    L[87020] = "Разрыв души" --+
    L[87262] = "Сгустки крови"
    L[87019] = "Якорь души"

    L.rise_bar = "Восстаньте"
    L.nodes_warn = "Скоро перефаза"
    L.nodes_start = "Перефаза 60%"
    L.nodes_end = "Перефаза завершена"
    L.nodes_bar = "Пилары живы: %d/5"
end
L = mod:GetLocale()

local nodesRemaining = 5

function mod:OnBossEnable()
    self:Log("SPELL_CAST_START", "Rise", 87005)

    self:Log("SPELL_AURA_APPLIED", "GraveyardStart", 87027)
    self:Log("SPELL_AURA_REMOVED", "GraveyardEnd", 87027)
	self:Log("SPELL_AURA_APPLIED", "RotMark", 87038)
	self:Log("SPELL_AURA_APPLIED", "RotMark", 87001)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87017)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87020)

    self:Death("NodeDied", 53016)

    self:Death("Win", 53000)
end

function mod:OnEngage()
    self.phase = 1
    self.warned65 = nil
	self:Berserk(481)
    self:Bar(87005, 44, L.rise_bar)
    self:RegisterEvent("UNIT_HEALTH", "CheckPhaseHP")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:PersonalAuraApplied(args)
    if self:Me(args.destGUID) then
        self:PersonalMessage(args.spellId)
        self:PlaySound(args.spellId, "alarm")
    end
end

function mod:RotMark(args)
    if self:Me(args.destGUID) then
        self:PersonalMessage(args.spellId)
        self:PlaySound(args.spellId, "alarm")
    end
    
    self:TargetMessage(args.spellId, args.destName, "orange", "alert")
end

function mod:CheckPhaseHP(_, unit)
    if unit ~= "boss1" then return end
    local hp = UnitHealth("boss1") / UnitHealthMax("boss1")

    if self.phase == 1 and not self.warned65 and hp <= 0.65 then
        self.warned65 = true
        self:Message("stages", "orange", nil, L.nodes_warn)
        self:PlaySound("stages", "warning")
    end
end

function mod:Rise(args)
    self:Message(args.spellId, "red")
    self:PlaySound(args.spellId, "alert")
    self:Bar(args.spellId, 48, L.rise_bar)
end

function mod:GraveyardStart(args)
    if self:MobId(args.destGUID) ~= 53000 then return end
    self.phase = 2
    nodesRemaining = 5
    
    self:StopBar(L.rise_bar)
    
    self:Bar(87027, 36, L.nodes_start)
    if self.nodesText then self:StopBar(self.nodesText) end
    self.nodesText = string.format(L.nodes_bar, nodesRemaining)
    self:Bar(87027, 1e9, self.nodesText, 87027)

    self:Message(args.spellId, "cyan", nil, L.nodes_start)
    self:PlaySound(args.spellId, "long")
end

function mod:NodeDied(args)
    if self.phase ~= 2 then return end
    nodesRemaining = nodesRemaining - 1
    if self.nodesText then self:StopBar(self.nodesText) end
    if nodesRemaining > 0 then
        self.nodesText = string.format(L.nodes_bar, nodesRemaining)
        self:Bar(87027, 1e9, self.nodesText, 87027)
    else
        self.nodesText = nil
    end
end

function mod:GraveyardEnd(args)
    if self:MobId(args.destGUID) ~= 53000 then return end
    self.phase = 3
    
    self:StopBar(L.nodes_start)
    if self.nodesText then
        self:StopBar(self.nodesText)
        self.nodesText = nil
    end
    
    self:Message(args.spellId, "green", nil, L.nodes_end)
    self:Bar(87005, 48, L.rise_bar)
end