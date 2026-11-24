local mod = BigWigs:NewBoss("Kamnerev the Living Earth", 961, 53060)
if not mod then return end
local DalaranFW = BigWigsAPI.internal.DalaranFW
mod:RegisterEnableMob(53060)
mod:SetEncounterID(53060)
mod:SetStage(1)

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

	L.spike_warn = "Каменный шип на вас!"
	L.grip_warn = "Вас схватили!"
	L.bones_text = "Сломанные кости: %d"
	L.fragile_text = "Уязвимость к сотрясению: %d"
	L.trampled_warn = "Растоптанная земля на вас!"
	L.stunned_warn = "Оглушение на вас!"
	L.electrified_warn = "Наэлектризованность на вас!"

	L.charge_end = "Камнерев потерял равновесие"
	L.charge_you = "Разбег на вас!"
	L.heavy_warn = "Тяжелая поступь — спрячьтесь за каменными шипами!"
	L.heavy_soon = "Тяжелая поступь скоро — приготовьтесь спрятаться!"
	L.stomp_bar = "Сотрясение"
	L.charge_bar = "Неудержимый разбег"
	L.quake_warn = "Землетрясение — отбегите!"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

local abilities = {
	{ key = 87174, kind = "announce", color = "orange", sound = "alert", castBar = 2.5, bar = 33.6 },
	{ key = 87102, kind = "announce", color = "orange", sound = "warning", castBar = 7, cdBar = 45.5 },
	{ key = 87110, kind = "announce", color = "red", sound = "alarm", text = L.quake_warn, castBar = 1.5, bar = 64.4 },
	{ key = 87176, kind = "announce", color = "red", sound = "alarm", text = L.heavy_warn, castBar = 4 },
	{ key = 87185, kind = "personal", color = "purple", sound = "alert", text = L.spike_warn },
	{ key = 87107, kind = "personal", color = "red", sound = "alert", text = L.grip_warn },
	{ key = 87101, kind = "personalStack", color = "orange", sound = "warning", stackText = L.bones_text },
	{ key = 87112, kind = "personalStack", color = "yellow", sound = "alert", stackText = L.fragile_text, flags = { "ME_ONLY" } },
	{ key = 87166, kind = "personal", color = "orange", sound = "alert", text = L.trampled_warn, selfBar = 3 },
	{ key = 87106, kind = "personal", color = "red", sound = "warning", text = L.stunned_warn, selfBar = 6 },
	{ key = 87500, kind = "personal", color = "yellow", sound = "alert", text = L.electrified_warn },
}
DalaranFW:Setup(mod, abilities, { "stages" })

function mod:OnBossEnable()
	DalaranFW:Enable(self)

	self:Death("Win", 53060)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	DalaranFW:Reset(self)
	self:SetStage(1)
	self.heavy50 = nil
	self.heavy20 = nil
	self:Bar(87174, 12, L.stomp_bar)
	self:CDBar(87102, 17, L.charge_bar)
	self:CDBar(87110, 48)
	self:RegisterEvent("UNIT_HEALTH", "CheckHeavyFoot")
end

function mod:CheckHeavyFoot(_, unit)
	if unit ~= "boss1" then return end
	local max = UnitHealthMax("boss1")
	if not max or max <= 0 then return end
	local hp = UnitHealth("boss1") / max
	if hp <= 0.52 and not self.heavy50 then
		self.heavy50 = true
		self:Message(87176, "red", "alarm", L.heavy_soon)
	elseif hp <= 0.22 and not self.heavy20 then
		self.heavy20 = true
		self:Message(87176, "red", "alarm", L.heavy_soon)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsSecret(msg) then return end
	if msg:find("разбегу на", nil, true) then
		local target = msg:match("разбегу на%s+(.-)!?$")
		if target and target ~= "" then
			if target == UnitName("player") then
				self:PersonalMessage(87102, false, L.charge_you)
				self:PlaySound(87102, "alarm")
			end
		else
			self:Message(87102, "orange", "alert")
		end
	elseif msg:find("врезается в барьер", nil, true) then
		self:Message(87102, "green", nil, L.charge_end)
	end
end
