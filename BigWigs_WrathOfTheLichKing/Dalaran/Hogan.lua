local mod = BigWigs:NewBoss("Hogan Death Herald", 961, 53000)
if not mod then return end
mod:RegisterEnableMob(53000)
mod.toggleOptions = {
    87005,
    87027,
    {87038, "INFOBOX", "FLASH"},
    {87022, "OFF"},
    {87001, "INFOBOX"},
    {87017, "OFF"},
    87020,
    87262,
    87269,
    "berserk"
}

local L = mod:NewLocale("enUS", true)
if L then
    L[87005] = "Восстаньте"
    L[87027] = "Погребение Даларана"
    L[87038] = "Метка гнили"
    L[87022] = "Оскверненная душа"
    L[87001] = "Погребальный знак"
    L[87017] = "Похищение души"
    L[87020] = "Разрыв души"
    L[87262] = "Сгустки крови"
    L[87269] = "Впитанная кровь"

    L.rise_bar = "Восстаньте"
    L.nodes_warn = "Скоро перефаза"
    L.nodes_start = "Перефаза 60%"
    L.nodes_end = "Перефаза завершена"
    L.nodes_bar = "Пилары живы: %d/5"
    L.nodes_left = "Узлов осталось: %d"
end
L = mod:GetLocale()

local lastMessage = {}

local function isDuplicate(key, time)
    local now = time or GetTime()
    if lastMessage[key] and now - lastMessage[key] < 0.5 then
        return true
    end
    lastMessage[key] = now
    return false
end

function mod:OnBossEnable()
    self:Log("SPELL_CAST_START", "Rise", 87005)

    self:Log("SPELL_AURA_APPLIED", "GraveyardStart", 87027)
    self:Log("SPELL_AURA_REMOVED", "GraveyardEnd", 87027)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87038)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87001)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87017)
	self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87020)
    self:Log("SPELL_AURA_APPLIED", "PersonalAuraApplied", 87269)

    self:Log("SPELL_AURA_APPLIED", "MassApplied", 87038)
    self:Log("SPELL_AURA_REMOVED", "MassRemoved", 87038)
    self:Log("SPELL_AURA_APPLIED", "MassApplied", 87001)
    self:Log("SPELL_AURA_REMOVED", "MassRemoved", 87001)

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "NodeCLEU")

    self:Death("Win", 53000)
end

function mod:OnEngage()
    self.phase = 1
    self.warned65 = nil
    self.nodesRemaining = nil
    self.nodesText = nil
    self.nodeDeaths = {}
    self.rotMarks = {}
    self.rotInfoOpen = nil
    lastMessage = {}
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

function mod:MassApplied(args)
    if not args.destName then return end
    self.mass = self.mass or {}
    self.mass[args.destName] = true
    self:UpdateMassInfo()
end

function mod:MassRemoved(args)
    if not args.destName or not self.massList then return end
    local list = self.massList[args.spellId]
    if not list then return end
    list[args.destName] = nil
    self:UpdateMassInfo(args.spellId)
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
    if self:MobId(args.sourceGUID) ~= 53000 then return end
    if isDuplicate("rise:"..tostring(args.sourceGUID), args.time) then return end
    self:Message(args.spellId, "red")
    self:PlaySound(args.spellId, "alert")
    self:Bar(args.spellId, 48, L.rise_bar)
end

function mod:GraveyardStart(args)
    if self:MobId(args.destGUID) ~= 53000 then return end
    if isDuplicate("graveyard_start", args.time) then return end
    self.phase = 2
    self.nodesRemaining = 5
    self.nodeDeaths = {}
    
    self:StopBar(L.rise_bar)
    
    self:Bar(87027, 36, L.nodes_start)
    self:ShowNodesBar()

    self:Message(args.spellId, "cyan", nil, L.nodes_start)
    self:PlaySound(args.spellId, "long")
end

function mod:ShowNodesBar()
    if self.nodesText then self:StopBar(self.nodesText) end
    self.nodesText = string.format(L.nodes_bar, self.nodesRemaining)
    self:Bar(87027, 1e9, self.nodesText, 87027)
end

function mod:NodeCLEU(_, _, subevent, _, _, _, destGUID, destName)
    if subevent ~= "UNIT_DIED" or self.phase ~= 2 or not self.nodesRemaining then return end

    local isNode = self:MobId(destGUID) == 53016
    if not isNode and destName then
        local name = destName:lower()
        isNode = name:find("узел", 1, true) or name:find("пилар", 1, true)
    end
    if not isNode then return end
    if self.nodeDeaths[destGUID] then return end
    self.nodeDeaths[destGUID] = true

    self:NodeDied()
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
    if isDuplicate("graveyard_end", args.time) then return end
    self.phase = 3
    
    self:StopBar(L.nodes_start)
    if self.nodesText then
        self:StopBar(self.nodesText)
        self.nodesText = nil
    end
    self.nodesRemaining = nil
    
    self:Message(args.spellId, "green", nil, L.nodes_end)
    self:Bar(87005, 48, L.rise_bar)
end

function mod:OnBossDisable()
    self:StopBar(L.nodes_start)
    self:StopBar(L.rise_bar)
    if self.nodesText then
        self:StopBar(self.nodesText)
        self.nodesText = nil
    end
    self.nodesRemaining = nil
    self.rotMarks = {}
    self.rotInfoOpen = nil
    self:CloseInfo(87038)
end