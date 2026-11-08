local mod = BigWigs:NewBoss("Kamnerev the Living Earth", 961, 53060)
if not mod then return end
mod:RegisterEnableMob(53060)
mod:SetEncounterID(53060)

mod.toggleOptions = {
	87174, -- Сотрясение
	87102, -- Неудержимый разбег
	87176, -- Тяжелая поступь
	87110, -- Землетрясение
	87185, -- Каменный шип
	87107, -- Схватить
	87101, -- Сломанные кости
	{87112, "ME_ONLY"}, -- Уязвимость к сотрясению
	"stages",
}

local L = mod:NewLocale("enUS", true)
if L then
	L.boss_name = "Камнерев Живая Земля"
	L[87174] = "Сотрясение"
	L[87102] = "Неудержимый разбег"
	L[87176] = "Тяжелая поступь"
	L[87110] = "Землетрясение"
	L[87185] = "Каменный шип"
	L[87107] = "Схватить"
	L[87101] = "Сломанные кости"
	L[87112] = "Уязвимость к сотрясению"
	L[87166] = "Растоптанная земля"
	L[87106] = "Оглушение"
	L[87500] = "Наэлектризованность"
	L.stages = "Фазы"

	L.charge_end = "Камнерев потерял равновесие"
	L.heavy_warn = "Тяжелая поступь — спрячьтесь за каменными шипами!"
	L.stomp_bar = "Сотрясение"
	L.charge_bar = "Неудержимый разбег"
	L.quake_warn = "Землетрясение — отбегите!"
	L.spikes_warn = "Каменные шипы на игроках"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

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
	self:Log("SPELL_CAST_START", "Stomp", 87174)
	self:Log("SPELL_CAST_START", "Charge", 87102)
	self:Log("SPELL_CAST_START", "Quake", 87110)
	self:Log("SPELL_CAST_START", "HeavyStep", 87176)
	self:Log("SPELL_AURA_APPLIED", "Spike", 87185)
	self:Log("SPELL_AURA_APPLIED", "Grip", 87107)
	self:Log("SPELL_AURA_APPLIED", "Bones", 87101)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Bones", 87101)
	self:Log("SPELL_AURA_APPLIED", "Fragile", 87112)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Fragile", 87112)
	self:Log("SPELL_AURA_APPLIED", "Trampled", 87166)
	self:Log("SPELL_AURA_APPLIED", "Stunned", 87106)
	self:Log("SPELL_AURA_APPLIED", "Electrified", 87500)

	self:Death("Win", 53060)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	self:SetStage(1)
	wipe(targetBatches)
	self:Bar(87174, 13, L.stomp_bar)
	self:CDBar(87102, 18, L.charge_bar)
	self:CDBar(87110, 50, L.quake_warn)
end

function mod:Stomp(args)
	self:Message(args.spellId, "orange", "alert")
	self:CastBar(args.spellId, 2.5, L.stomp_bar)
	self:Bar(args.spellId, 31, L.stomp_bar)
end

function mod:Charge(args)
	self:Message(args.spellId, "orange", "warning")
	self:CastBar(args.spellId, 7, L.charge_bar)
	self:CDBar(args.spellId, 41, L.charge_bar)
end

function mod:Quake(args)
	self:Message(args.spellId, "red", "alarm", L.quake_warn)
	self:CastBar(args.spellId, 1.5)
	self:Bar(args.spellId, 57)
end

function mod:HeavyStep(args)
	self:Message(args.spellId, "red", "alarm", L.heavy_warn)
	self:CastBar(args.spellId, 4)
end

function mod:Spike(args)
	pushTarget(self, 87185, args, 10, "purple", "alert", L.spikes_warn)
end

function mod:Grip(args)
	self:TargetMessage(args.spellId, args.destName, "red", "alert")
end

function mod:Bones(args)
	local stacks = tonumber(args.amount)
	if not stacks or stacks < 1 then stacks = 1 end
	self:StackMessage(args.spellId, args.destName, stacks, "orange", nil)
end

function mod:Fragile(args)
	local stacks = tonumber(args.amount)
	if not stacks or stacks < 1 then stacks = 1 end
	self:StackMessage(args.spellId, args.destName, stacks, "yellow", nil)
end

function mod:Trampled(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "orange", "alert")
		self:TargetBar(args.spellId, 3, args.destName)
	end
end

function mod:Stunned(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "red", "warning")
		self:TargetBar(args.spellId, 6, args.destName)
	end
end

function mod:Electrified(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "yellow")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsSecret(msg) then return end
	if msg:find("разбегу на", nil, true) then
		local target = msg:match("разбегу на%s+(.-)!?$")
		if target and target ~= "" then
			self:TargetMessage(87102, target, "orange", "alert")
		else
			self:Message(87102, "orange", "alert")
		end
	elseif msg:find("врезается в барьер", nil, true) then
		self:Message(87102, "green", nil, L.charge_end)
	end
end


