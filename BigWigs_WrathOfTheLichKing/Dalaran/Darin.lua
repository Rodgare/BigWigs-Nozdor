local mod = BigWigs:NewBoss("High Cultist Daren", 961, 53070)
if not mod then return end
mod:RegisterEnableMob(53070)
mod:SetEncounterID(53070)

mod.toggleOptions = {
	87267, -- Пламенный обстрел
	87189, -- Ледяной обстрел
	87155, -- Некротическая печать
	87150, -- Раскол маны
	87162, -- Истребление
	87510, -- Защита секты
	87187, -- Чародейская канонада (каст)
	87167, -- Чародейская канонада (канал)
	87164, -- Омертвевшее обледенение
	87188, -- Тандем стихий
	87194, -- Метка огня
	87196, -- Метка льда
	87170, -- Срыв контроля
	87154, -- Раскаленная земля
	87193, -- Обледенелая земля
}

local L = mod:NewLocale("enUS", true)
if L then
	L.boss_name = "Верховный сектант Дарен"
	L[87267] = "Пламенный обстрел"
	L[87189] = "Ледяной обстрел"
	L[87155] = "Некротическая печать"
	L[87150] = "Раскол маны"
	L[87162] = "Истребление"
	L[87510] = "Защита секты"
	L[87187] = "Чародейская канонада"
	L[87167] = "Чародейская канонада"
	L[87164] = "Омертвевшее обледенение"
	L[87188] = "Тандем стихий"
	L[87194] = "Метка огня"
	L[87196] = "Метка льда"
	L[87170] = "Срыв контроля"
	L[87154] = "Раскаленная земля"
	L[87193] = "Обледенелая земля"

	L.seal_warn = "Некротическая печать — отбегите от союзников!"
	L.eradication_warn = "Истребление — прервите каст!"
	L.arcane_warn = "Чародейская канонада — уклоняйтесь!"
	L.frost_warn = "Омертвевшее обледенение — найдите укрытие!"
	L.tandem_warn = "Тандем стихий — найдите партнёра с противоположной меткой!"
	L.control_warn = "Срыв контроля!"
	L.fire_ground = "Раскаленная земля под вами!"
	L.frost_ground = "Обледенелая земля под вами!"
	L.mark_fire = "Метка огня"
	L.mark_ice = "Метка льда"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

local targetBatches = {}

local function pushTarget(self, key, args, expected, color, sound, text)
	local now = args.time or GetTime()
	local batch = targetBatches[key]
	if not batch or now - batch.at > 0.6 then
		batch = { list = {}, at = now, expected = expected }
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
	self:Log("SPELL_AURA_APPLIED", "FireBarrage", 87267)
	self:Log("SPELL_AURA_APPLIED", "FrostBarrage", 87189)
	self:Log("SPELL_AURA_APPLIED", "NecroticSeal", 87155)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ManaSplinter", 87150)
	self:Log("SPELL_CAST_START", "Eradication", 87162)
	self:Log("SPELL_AURA_APPLIED", "SectShield", 87510)
	self:Log("SPELL_CAST_START", "ArcaneBarrage", 87187)
	self:Log("SPELL_CAST_SUCCESS", "ArcaneChannel", 87167)
	self:Log("SPELL_CAST_START", "DeadlyFrost", 87164)
	self:Log("SPELL_CAST_START", "ElementalTandem", 87188)
	self:Log("SPELL_AURA_APPLIED", "MarkFire", 87194)
	self:Log("SPELL_AURA_APPLIED", "MarkIce", 87196)
	self:Log("SPELL_AURA_APPLIED", "ControlBreak", 87170)
	self:Log("SPELL_AURA_APPLIED", "ScorchedGround", 87154)
	self:Log("SPELL_AURA_APPLIED", "FrozenGround", 87193)

	self:Death("Win", 53070)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	self:SetStage(1)
	wipe(targetBatches)
	self:CDBar(87267, 9) -- Fire Barrage
	self:CDBar(87162, 43) -- Eradication
	self:CDBar(87187, 55) -- Arcane Barrage
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FireBarrage(args)
	self:TargetMessage(args.spellId, args.destName, "orange", "alert")
	self:TargetBar(args.spellId, 4, args.destName)
end

function mod:FrostBarrage(args)
	self:TargetMessage(args.spellId, args.destName, "blue", "alert")
	self:TargetBar(args.spellId, 4, args.destName)
end

function mod:NecroticSeal(args)
	self:TargetMessage(args.spellId, args.destName, "red", "warning", L.seal_warn)
	self:TargetBar(args.spellId, 6, args.destName)
end

function mod:ManaSplinter(args)
	local stacks = tonumber(args.amount) or 1
	self:StackMessage(args.spellId, args.destName, stacks, "yellow", stacks >= 4 and "warning")
end

function mod:Eradication(args)
	self:Message(args.spellId, "red", "warning", L.eradication_warn)
	self:CDBar(args.spellId, 52)
end

function mod:SectShield(args)
	self:Message(args.spellId, "yellow")
end

function mod:ArcaneBarrage(args)
	self:Message(args.spellId, "orange", "warning", L.arcane_warn)
	self:CastBar(args.spellId, 1.5)
	self:CDBar(args.spellId, 54)
end

function mod:ArcaneChannel(args)
	self:Message(87167, "orange", "alert")
	self:Bar(87167, 10)
end

function mod:DeadlyFrost(args)
	self:SetStage(2)
	self:Message(args.spellId, "red", "alarm", L.frost_warn)
	self:CastBar(args.spellId, 5)
end

function mod:ElementalTandem(args)
	self:SetStage(3)
	self:Message(args.spellId, "red", "alarm", L.tandem_warn)
	self:CastBar(args.spellId, 5)
end

function mod:MarkFire(args)
	pushTarget(self, 87194, args, 5, "red", "alert", L.mark_fire)
end

function mod:MarkIce(args)
	pushTarget(self, 87196, args, 5, "blue", "alert", L.mark_ice)
end

function mod:ControlBreak(args)
	self:Message(args.spellId, "red", "warning", L.control_warn)
end

function mod:ScorchedGround(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "orange", "alarm", L.fire_ground)
		self:TargetBar(args.spellId, 3, args.destName)
	end
end

function mod:FrozenGround(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "blue", "alarm", L.frost_ground)
		self:TargetBar(args.spellId, 3, args.destName)
	end
end
