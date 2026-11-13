local mod = BigWigs:NewBoss("Overseer Malkren", 961, 53046)
if not mod then return end
mod:RegisterEnableMob(53046)
mod:SetEncounterID(53046)

local L = mod:NewLocale("enUS", true)
if L then
	L[87058] = "Пламенные цепи"
	L[87050] = "Осадное клеймо"
	L[87051] = "Кара печати"
	L[87066] = "Осадный барьер"
	L[87067] = "Жертвоприношение"
	L[87063] = "Взрыв колодца душ"
	L[87064] = "Горящая душа"
	L[87083] = "Защита Кирин-Тора"
	L[87420] = "Рунический обстрел"
	L[87133] = "Коллапс стихий"
	L[87137] = "Ритуальный разлом"
	L[87071] = "Ритуальный снаряд"
	L[87419] = "Ритуальный след"
	L[87124] = "Фиолетовая руна"
	L[87125] = "Оранжевая руна"
	L[87126] = "Жёлтая руна"
	L[87127] = "Синяя руна"
	L[87128] = "Зелёная руна"
	L[87065] = "Ярость надзирателя"

	L.seal_text = "Осадное клеймо: %d"
	L.punishment_warn = "Кара печати на вас!"
	L.burning_warn = "Горящая душа на вас!"
	L.barrage_warn = "Рунический обстрел на вас!"
	L.rift_warn = "Ритуальный разлом на вас!"
	L.missile_warn = "Ритуальный снаряд на вас!"
	L.trail_warn = "Ритуальный след на вас!"
	L.rune_violet = "Фиолетовая руна на вас — найдите пару!"
	L.rune_orange = "Оранжевая руна на вас — найдите пару!"
	L.rune_yellow = "Жёлтая руна на вас — найдите пару!"
	L.rune_blue = "Синяя руна на вас — найдите пару!"
	L.rune_green = "Зелёная руна на вас — найдите пару!"

	L.wells = "Колодцы душ"
	L.runes = "Парные руны"
	L.stages = "Фазы"

	L.wells_msg = "Колодцы душ — закройте их собой!"
	L.runes_msg = "Парные руны — найдите партнёра с такой же руной!"
	L.sacrifice_msg = "Жертвоприношение! Разбейте ритуальные цепи!"
	L.last_sacrifice = "Последнее жертвоприношение!"
	L.chains_bar = "Цепи: уничтожьте!"
	L.chains_broken = "Цепи разбиты, жертва спасена"
	L.barrier_down = "Барьер снят"
	L.enrage = "Ярость надзирателя! Осталось ~60 секунд"
	L.enrage_bar = "Ярость надзирателя"
end
L = mod:GetLocale()

local abilities = {
	{ key = 87058, ids = { 87058, 87431 }, kind = "announce", castBar = 3, message = false },
	{ key = 87050, kind = "personalStack", color = "orange", sound = "warning", stackText = L.seal_text },
	{ key = 87051, kind = "personal", color = "red", sound = "alarm", text = L.punishment_warn },
	{ key = 87064, kind = "personal", color = "red", sound = "alert", text = L.burning_warn, selfBar = 2 },
	{ key = 87420, kind = "personal", color = "orange", sound = "alert", text = L.barrage_warn },
	{ key = 87137, kind = "personal", color = "yellow", sound = "warning", text = L.rift_warn },
	{ key = 87071, kind = "personal", color = "red", sound = "alert", text = L.missile_warn },
	{ key = 87419, kind = "personal", color = "orange", sound = "alert", text = L.trail_warn },
	{ key = 87124, kind = "personal", color = "purple", sound = "alert", text = L.rune_violet },
	{ key = 87125, kind = "personal", color = "orange", sound = "alert", text = L.rune_orange },
	{ key = 87126, kind = "personal", color = "yellow", sound = "alert", text = L.rune_yellow },
	{ key = 87127, kind = "personal", color = "blue", sound = "alert", text = L.rune_blue },
	{ key = 87128, kind = "personal", color = "green", sound = "alert", text = L.rune_green },
	{ key = 87133, kind = "announce", color = "red", sound = "warning", text = L[87133] },
	{ key = 87066, kind = "custom" },
	{ key = 87067, kind = "custom" },
	{ key = 87063, kind = "custom" },
	{ key = 87083, kind = "custom" },
	{ key = 87065, kind = "custom" },
}
DalaranFW:Setup(mod, abilities, { "wells", "runes", "stages" })

function mod:OnBossEnable()
	DalaranFW:Enable(self)

	self:Log("SPELL_AURA_APPLIED", "BarrierUp", 87066)
	self:Log("SPELL_AURA_REMOVED", "BarrierDown", 87066)
	self:Log("SPELL_AURA_APPLIED", "SacrificeStart", 87067, 87091)
	self:Log("SPELL_AURA_REMOVED", "SacrificeEnd", 87067, 87091)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 87065)
	self:Log("SPELL_AURA_APPLIED", "WellExplosion", 87063)
	self:Log("SPELL_AURA_APPLIED", "KirinTorShield", 87083)

	self:Death("ChainsDown", 53030)
	self:Death("Win", 53046)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	DalaranFW:Reset(self)
	self:SetStage(1)
	self:CDBar("wells", 16, L.wells)
end

function mod:BarrierUp(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(87066, "yellow")
end

function mod:BarrierDown(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(87066, "green", nil, L.barrier_down)
end

function mod:SacrificeStart(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	if DalaranFW:Dedupe(self, "sacrifice", args.time, 0.5) then return end

	self:SetStage(2)
	self:Message(87067, "red", "alarm", L.sacrifice_msg)
	self:Bar(87067, 1e9 + 1, L.chains_bar)
end

function mod:SacrificeEnd(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	if DalaranFW:Dedupe(self, "sacrifice_end", args.time, 0.5) then return end

	self:StopBar(L.chains_bar)
	self:SetStage(1)
	self:Message(87067, "green", nil, L.chains_broken)
end

function mod:ChainsDown()
	self:StopBar(L.chains_bar)
end

function mod:WellExplosion(args)
	self:Message(87063, "red", "alarm")
end

function mod:KirinTorShield(args)
	self:Message(87083, "yellow")
end

function mod:Enrage(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(87065, "red", "alarm", L.enrage)
	self:CDBar(87065, 60, L.enrage_bar)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsSecret(msg) then return end
	if msg:find("Колодцы душ", nil, true) then
		self:Message("wells", "orange", "alert", L.wells_msg)
		self:CDBar("wells", 25, L.wells)
	elseif msg:find("Последнее Жертвоприношение", nil, true) then
		self:Message("stages", "red", "alarm", L.last_sacrifice)
	elseif msg:find("Парные руны", nil, true) then
		self:Message("runes", "purple", "warning", L.runes_msg)
		self:CDBar("runes", 20, L.runes)
	end
end
