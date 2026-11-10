local mod = BigWigs:NewBoss("Manabonk", 961, 53080)
if not mod then return end
mod:RegisterEnableMob(53080)
mod:SetEncounterID(53080)

mod.toggleOptions = {
	87200, -- Перегрузка маны
	87206, -- Нестабильная полиморфия
	87242, -- Резонирующая метка
	87209, -- Ледяной заслон
	87235, -- Коллапсирующая сфера
	87214, -- Мана-бомба
	87215, -- Отголосок мана-бомбы
	87212, -- Обледенение
	87213, -- Ледяная полиморфия
	"stages",
}

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

	L.sphere_warn = "Коллапсирующая сфера — не дайте себя притянуть!"
	L.wall_warn = "Ледяной заслон"
	L.polymorph_warn = "Нестабильная полиморфия"
	L.mark_warn = "Резонирующая метка - вынести!"
	L.manabomb_warn = "Мана-бомба — передай союзнику!"
	L.manabomb_echo = "Отголосок мана-бомбы — вынести!"
	L.frozen_warn = "Под тобой лужа!"
	L.manabomb_phase = "Мана-бомбы! Босс начал раздавать бомбы"
	L.sky_shard = "Небесный осколок не поглощён — удар по всему рейду!"
end
L = mod:GetLocale()
mod.displayName = L.boss_name

local lastCast = {}

local function isDuplicate(key, time, window)
	local now = time or GetTime()
	window = window or 1
	if lastCast[key] and now - lastCast[key] < window then
		return true
	end
	lastCast[key] = now
	return false
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ManaOverloadCast", 87200)
	self:Log("SPELL_AURA_APPLIED", "ManaOverload", 87200)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ManaOverload", 87200)
	self:Log("SPELL_AURA_APPLIED", "Polymorph", 87206)
	self:Log("SPELL_AURA_APPLIED", "Mark", 87242)
	self:Log("SPELL_CAST_START", "IceWall", 87209)
	self:Log("SPELL_CAST_START", "CollapsingSphere", 87235, 87236)
	self:Log("SPELL_AURA_APPLIED", "ManaBomb", 87214, 87273, 87274, 87275)
	self:Log("SPELL_AURA_APPLIED", "ManaBombEcho", 87215)
	self:Log("SPELL_AURA_APPLIED", "Frozen", 87212, 87213)

	self:Death("Win", 53080)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage()
	self:SetStage(1)
	self.sphere75 = nil
	self.sphere40 = nil
	self.bombPhase = nil
	wipe(lastCast)

	self:Bar(87200, 16)
	self:Bar(87206, 23)
	self:Bar(87242, 37)
	self:Bar(87209, 50)

	self:RegisterEvent("UNIT_HEALTH", "CheckPhaseHP")
end

-- HP-based abilities ---------------------------------------------------------

function mod:AnnounceSphere()
	if isDuplicate("sphere", nil, 10) then return end
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

-- Spell handlers ------------------------------------------------------------

function mod:ManaOverloadCast(args)
	self:CDBar(87200, 18)
end

function mod:ManaOverload(args)
	if self:Me(args.destGUID) then
		local stacks = tonumber(args.amount) or 1
		self:StackMessage(87200, args.destName, stacks, "orange", "alert")
	end
end

function mod:Polymorph(args)
	if isDuplicate("polymorph", nil, 2) then return end
	self:CDBar(87206, 42)
	if self:Me(args.destGUID) then
		self:PersonalMessage(87206, false, L.polymorph_warn)
		self:PlaySound(87206, "alert")
	end
end

function mod:Mark(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(87242, false, L.mark_warn)
		self:PlaySound(87242, "warning")
	end
end

function mod:IceWall(args)
	self:Message(args.spellId, "red", "warning", L.wall_warn)
	self:PlaySound(args.spellId, "warning")
	self:CastBar(args.spellId, 2, L[87209])
	self:CDBar(args.spellId, 45)
end

function mod:CollapsingSphere(args)
	if args.spellId == 87235 and not isDuplicate("sphereCast", nil, 10) then
		self:CastBar(87235, 3, L[87235])
	end
	self:AnnounceSphere()
end

function mod:ManaBomb(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(args.spellId, false, L.manabomb_warn)
		self:PlaySound(args.spellId, "alarm")
	end
end

function mod:ManaBombEcho(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(87215, false, L.manabomb_echo)
		self:PlaySound(87215, "alert")
	end
end

function mod:Frozen(args)
	if self:Me(args.destGUID) and not isDuplicate("frozen", nil, 3) then
		self:PersonalMessage(args.spellId, false, L.frozen_warn)
		self:PlaySound(87213, "alert")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsSecret(msg) then return end
	if msg:find("Небесный осколок", nil, true) then
		self:Message("stages", "red", "alarm", L.sky_shard)
	end
end
