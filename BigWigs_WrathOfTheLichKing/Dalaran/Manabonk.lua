local mod = BigWigs:NewBoss("Manabonk", 961, 53080)
if not mod then return end
mod:RegisterEnableMob(53080)
mod:SetEncounterID(53080)

local L = mod:NewLocale("enUS", true)
if L then
	L.boss_name = "Минигоб Манабонк"

	L[87200] = "Перегрузка маны"
	L[87206] = "Нестабильная полиморфия"
	L[87242] = "Резонирующая метка"
	L[87209] = "Ледяной заслон"
	L[87235] = "Коллапсирующая сфера"
	L[87214] = "Мана-бомба"
	L[87215] = "Отголосок мана-бомбы"
	L[87212] = "Обледенение"
	L[87213] = "Ледяная полиморфия"

	L.stages = "Фазы"

	L.overload_text = "Перегрузка маны: %d"
	L.polymorph_warn = "Нестабильная полиморфия на вас!"
	L.sphere_warn = "Коллапсирующая сфера — не дайте себя притянуть!"
	L.wall_warn = "Ледяной заслон — перепрыгните стену!"
	L.mark_warn = "Резонирующая метка — отойдите от союзников!"
	L.manabomb_warn = "Мана-бомба на вас — передайте союзнику!"
	L.manabomb_echo = "Отголосок мана-бомбы — отойдите от союзников!"
	L.frozen_warn = "Вы заморожены!"
	L.manabomb_phase = "Мана-бомбы! Босс начал раздавать бомбы"
	L.sky_shard = "Небесный осколок не поглощён — удар по всему рейду!"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

local abilities = {
	{ key = 87200, kind = "personalStack", color = "orange", sound = "warning", stackText = L.overload_text },
	{ key = 87206, kind = "personal", color = "purple", sound = "alert", text = L.polymorph_warn },
	{ key = 87242, kind = "personal", color = "orange", sound = "warning", text = L.mark_warn },
	{ key = 87214, ids = { 87214, 87273, 87274, 87275 }, kind = "personal", color = "orange", sound = "alarm", text = L.manabomb_warn },
	{ key = 87215, kind = "personal", color = "red", sound = "alert", text = L.manabomb_echo },
	{ key = 87212, ids = { 87212, 87213 }, kind = "personal", color = "blue", sound = "alert", text = L.frozen_warn },
	{ key = 87209, kind = "announce", color = "red", sound = "warning", text = L.wall_warn, castBar = 2, cdBar = 45 },
	{ key = 87235, kind = "custom" },
}
DalaranFW:Setup(mod, abilities, { "stages" })

function mod:OnBossEnable()
	DalaranFW:Enable(self)

	self:Log("SPELL_CAST_START", "CollapsingSphere", 87235, 87236)

	self:Death("Win", 53080)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	DalaranFW:Reset(self)
	self:SetStage(1)
	self.sphere75 = nil
	self.sphere40 = nil
	self.bombPhase = nil

	self:Bar(87200, 16)
	self:Bar(87206, 23)
	self:Bar(87242, 37)
	self:Bar(87209, 50)

	self:RegisterEvent("UNIT_HEALTH", "CheckPhaseHP")
end

function mod:AnnounceSphere()
	if DalaranFW:Dedupe(self, "sphere", nil, 10) then return end
	self:Message(87235, "red", "alarm", L.sphere_warn)
end

function mod:CheckPhaseHP(_, unit)
	if unit ~= "boss1" then return end
	local max = UnitHealthMax("boss1")
	if not max or max <= 0 then return end
	local hp = UnitHealth("boss1") / max

	if hp <= 0.75 and not self.sphere75 then
		self.sphere75 = true
		self:AnnounceSphere()
	elseif hp <= 0.65 and not self.bombPhase then
		self.bombPhase = true
		self:SetStage(2)
		self:Message("stages", "orange", "alert", L.manabomb_phase)
	elseif hp <= 0.40 and not self.sphere40 then
		self.sphere40 = true
		self:SetStage(3)
		self:AnnounceSphere()
	end
end

function mod:CollapsingSphere(args)
	if args.spellId == 87235 and not DalaranFW:Dedupe(self, "sphere_cast", args.time, 10) then
		self:CastBar(87235, 3, self:SpellName(87235))
	end
	self:AnnounceSphere()
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsSecret(msg) then return end
	if msg:find("Небесный осколок", nil, true) then
		self:Message("stages", "red", "alarm", L.sky_shard)
	end
end
