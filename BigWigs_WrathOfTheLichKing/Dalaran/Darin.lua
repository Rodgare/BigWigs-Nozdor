local mod = BigWigs:NewBoss("High Cultist Daren", 961, 53070)
if not mod then return end
mod:RegisterEnableMob(53070)
mod:SetEncounterID(53070)

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
	L[87193] = "Обледеневшая земля"
	L.stages = "Фазы"

	L.fire_warn = "Пламенный обстрел на вас!"
	L.frost_warn_on = "Ледяной обстрел на вас!"
	L.seal_warn = "Некротическая печать — отбегите от союзников!"
	L.splinter_text = "Раскол маны: %d"
	L.eradication_warn = "Истребление — прервите каст!"
	L.arcane_warn = "Чародейская канонада — уклоняйтесь!"
	L.frost_warn = "Омертвевшее обледенение — найдите укрытие!"
	L.tandem_warn = "Тандем стихий — найдите партнёра с противоположной меткой!"
	L.mark_fire = "Метка огня на вас"
	L.mark_ice = "Метка льда на вас"
	L.control_warn = "Срыв контроля!"
	L.fire_ground = "Раскалённая земля под вами!"
	L.frost_ground = "Обледеневшая земля под вами!"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

local abilities = {
	{ key = 87267, kind = "personal", color = "orange", sound = "alert", text = L.fire_warn, selfBar = 4 },
	{ key = 87189, kind = "personal", color = "blue", sound = "alert", text = L.frost_warn_on, selfBar = 4 },
	{ key = 87155, kind = "personal", color = "red", sound = "warning", text = L.seal_warn, selfBar = 6 },
	{ key = 87150, kind = "personalStack", color = "yellow", sound = "warning", stackText = L.splinter_text },
	{ key = 87194, kind = "personal", color = "red", sound = "alert", text = L.mark_fire },
	{ key = 87196, kind = "personal", color = "blue", sound = "alert", text = L.mark_ice },
	{ key = 87170, kind = "personal", color = "red", sound = "warning", text = L.control_warn },
	{ key = 87154, kind = "personal", color = "orange", sound = "alert", text = L.fire_ground },
	{ key = 87193, kind = "personal", color = "blue", sound = "alert", text = L.frost_ground },
	{ key = 87162, kind = "announce", color = "red", sound = "warning", text = L.eradication_warn, cdBar = 52 },
	{ key = 87510, kind = "announce", color = "yellow" },
	{ key = 87187, kind = "announce", color = "orange", sound = "warning", text = L.arcane_warn, castBar = 1.5, cdBar = 54 },
	{ key = 87164, kind = "custom" },
	{ key = 87188, kind = "custom" },
}
DalaranFW:Setup(mod, abilities, { "stages" })

function mod:OnBossEnable()
	DalaranFW:Enable(self)

	self:Log("SPELL_CAST_START", "DeadlyFrost", 87164)
	self:Log("SPELL_CAST_START", "ElementalTandem", 87188)
	self:Log("SPELL_CAST_SUCCESS", "ArcaneChannel", 87167)

	self:Death("Win", 53070)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	DalaranFW:Reset(self)
	self:SetStage(1)
	self:CDBar(87267, 9)
	self:CDBar(87162, 43)
	self:CDBar(87187, 55)
end

function mod:DeadlyFrost(args)
	self:SetStage(2)
	self:Message(87164, "red", "alarm", L.frost_warn)
	self:CastBar(87164, 5)
end

function mod:ElementalTandem(args)
	self:SetStage(3)
	self:Message(87188, "red", "alarm", L.tandem_warn)
	self:CastBar(87188, 5)
end

function mod:ArcaneChannel(args)
	if DalaranFW:Dedupe(self, "arcane_channel", args.time, 0.5) then return end
	self:Message(87187, "orange", "alert")
	self:Bar(87187, 10)
end
