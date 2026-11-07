local mod = BigWigs:NewBoss("Overseer Malkren", 961, 53046)
if not mod then return end
mod:RegisterEnableMob(53046)
mod:SetEncounterID(53046)

mod.toggleOptions = {
	87058, -- Пламенные цепи
	87050, -- Осадное клеймо
	{87051, "ME_ONLY", "FLASH"}, -- Кара печати
	87066, -- Осадный барьер
	87067, -- Жертвоприношение
	87137, -- Ритуальный разлом
	87071, -- Ритуальный снаряд
	87419, -- Ритуальный след
	{87124, "FLASH"}, -- Фиолетовая руна
	{87125, "FLASH"}, -- Оранжевая руна
	87065, -- Ярость надзирателя
	87138, -- Паника
	"wells",
	"runes",
	"stages",
}

local L = mod:NewLocale("enUS", true)
if L then
	L[87058] = "Пламенные цепи"
	L[87050] = "Осадное клеймо"
	L[87051] = "Кара печати"
	L[87066] = "Осадный барьер"
	L[87067] = "Жертвоприношение"
	L[87137] = "Ритуальный разлом"
	L[87071] = "Ритуальный снаряд"
	L[87419] = "Ритуальный след"
	L[87124] = "Фиолетовая руна"
	L[87125] = "Оранжевая руна"
	L[87065] = "Ярость надзирателя"
	L[87138] = "Паника"

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

local targetBatches = {}

local function pushTarget(self, key, args, expected, color, sound, text)
	local now = args.time or GetTime()
	local batch = targetBatches[key]
	if not batch or now - batch.at > 0.6 then
		batch = {list = {}, at = now, expected = expected}
		targetBatches[key] = batch
		self:ScheduleTimer("FlushTargets", 0.5, key, batch)
	end
	batch.at = now
	batch.list[#batch.list + 1] = args.destName
	batch.color, batch.sound, batch.text = color, sound, text
	if #batch.list >= expected then
		self:FlushTargets(key, batch)
	end
end

function mod:FlushTargets(key, batch)
	if not batch or targetBatches[key] ~= batch or #batch.list == 0 then return end
	targetBatches[key] = nil
	self:TargetMessage(key, batch.list, batch.color, batch.sound, batch.text)
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Chains", 87058)
	self:Log("SPELL_AURA_APPLIED", "Seal", 87050)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Seal", 87050)
	self:Log("SPELL_AURA_APPLIED", "Punishment", 87051)
	self:Log("SPELL_AURA_APPLIED", "BarrierUp", 87066)
	self:Log("SPELL_AURA_REMOVED", "BarrierDown", 87066)
	self:Log("SPELL_AURA_APPLIED", "SacrificeStart", 87067)
	self:Log("SPELL_AURA_REMOVED", "SacrificeEnd", 87067)
	self:Log("SPELL_AURA_APPLIED", "Rift", 87137)
	self:Log("SPELL_AURA_APPLIED", "Missile", 87071)
	self:Log("SPELL_AURA_APPLIED", "Trail", 87419)
	self:Log("SPELL_AURA_APPLIED", "RuneViolet", 87124)
	self:Log("SPELL_AURA_APPLIED", "RuneOrange", 87125)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 87065)

	self:Death("ChainsDown", 53030)
	self:Death("Win", 53046)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	self:SetStage(1)
	wipe(targetBatches)
	self:CDBar("wells", 16, L.wells)
end

function mod:Chains(args)
	self:CastBar(args.spellId, 3, L[87058])
end

function mod:Seal(args)
	if self:MobId(args.destGUID) == 53046 then return end
	local stacks = tonumber(args.amount)
	if not stacks or stacks < 1 then stacks = 1 end
	self:StackMessage(args.spellId, args.destName, stacks, "yellow", nil)
end

function mod:Punishment(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(args.spellId)
		self:PlaySound(args.spellId, "alarm")
	end
end

function mod:BarrierUp(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(args.spellId, "yellow")
end

function mod:BarrierDown(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(args.spellId, "green", nil, L.barrier_down)
end

function mod:SacrificeStart(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:SetStage(2)
	self:Message(args.spellId, "red", "alarm", L.sacrifice_msg)
	self:Bar(args.spellId, 1e9 + 1, L.chains_bar)
end

function mod:SacrificeEnd(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:StopBar(L.chains_bar)
	self:SetStage(1)
	self:Message(args.spellId, "green", nil, L.chains_broken)
end

function mod:ChainsDown(args)
	self:StopBar(L.chains_bar)
end

function mod:Rift(args)
	pushTarget(self, 87137, args, 3, "yellow", "warning", L[87137])
end

function mod:Trail(args)
	pushTarget(self, 87419, args, 10, "orange", "alert", L[87419])
end

function mod:RuneViolet(args)
	pushTarget(self, 87124, args, 2, "purple", "alert", L[87124])
end

function mod:RuneOrange(args)
	pushTarget(self, 87125, args, 2, "purple", "alert", L[87125])
end

function mod:Missile(args)
	self:TargetMessage(args.spellId, args.destName, "red", "alert")
end

function mod:Enrage(args)
	if self:MobId(args.destGUID) ~= 53046 then return end
	self:Message(args.spellId, "red", "alarm", L.enrage)
	self:CDBar(args.spellId, 60, L.enrage_bar)
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


