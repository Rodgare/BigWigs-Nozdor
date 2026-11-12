-- Общий слой для боссов Осады Даларана (клиент 3.3.5 Nozdor).
-- Подключается в BigWigs_WrathOfTheLichKing.toc ДО боссовых файлов.
--
-- Правила:
--   * одна способность = один канонический key (обычно основной spellID);
--   * все варианты ID (ранги/дубли/каст+канал) перечисляются в ids;
--   * дебафф пишет текст только тому, на кого он лёг;
--   * никаких списков игроков и InfoBox — только личные сообщения и таймеры.

DalaranFW = {}
local D = DalaranFW
local GetTime = GetTime
local format = string.format

local function newState()
	return { seen = {}, stacks = {} }
end

--- Собрать toggleOptions и карты spellID -> ability.
-- @param mod модуль BigWigs
-- @param abilities список описаний способностей
-- @param extraOptions дополнительные опции (строки вроде "stages")
function D:Setup(mod, abilities, extraOptions)
	mod.__dalaran = {
		abilities = abilities,
		aura = {},
		cast = {},
		state = newState(),
	}

	local opts = {}
	for _, ability in ipairs(abilities) do
		if ability.option ~= false then
			local opt = { ability.key }
			for _, flag in ipairs(ability.flags or {}) do
				opt[#opt + 1] = flag
			end
			opts[#opts + 1] = opt
		end

		local ids = ability.ids or { ability.key }
		if ability.kind == "announce" then
			for _, id in ipairs(ids) do
				mod.__dalaran.cast[id] = ability
			end
		elseif ability.kind == "personal" or ability.kind == "personalStack" then
			for _, id in ipairs(ids) do
				mod.__dalaran.aura[id] = ability
			end
		end
	end

	for _, opt in ipairs(extraOptions or {}) do
		opts[#opts + 1] = opt
	end
	mod.toggleOptions = opts
end

local function sortedKeys(tbl)
	local list = {}
	for id in pairs(tbl) do
		list[#list + 1] = id
	end
	table.sort(list)
	return list
end

--- Зарегистрировать обработчики. Вызывать из OnBossEnable.
function D:Enable(mod)
	local data = mod.__dalaran
	local auraIds = sortedKeys(data.aura)
	local castIds = sortedKeys(data.cast)

	mod.DalaranAuraApplied = function(self, args) D:OnAuraApplied(self, args) end
	mod.DalaranAuraDose = function(self, args) D:OnAuraDose(self, args) end
	mod.DalaranAuraRemoved = function(self, args) D:OnAuraRemoved(self, args) end
	mod.DalaranCast = function(self, args) D:OnCast(self, args) end

	if #auraIds > 0 then
		mod:Log("SPELL_AURA_APPLIED", "DalaranAuraApplied", unpack(auraIds))
		mod:Log("SPELL_AURA_APPLIED_DOSE", "DalaranAuraDose", unpack(auraIds))
		mod:Log("SPELL_AURA_REFRESH", "DalaranAuraDose", unpack(auraIds))
		mod:Log("SPELL_AURA_REMOVED", "DalaranAuraRemoved", unpack(auraIds))
	end
	if #castIds > 0 then
		mod:Log("SPELL_CAST_START", "DalaranCast", unpack(castIds))
	end
end

--- Сбросить состояние между пуллами. Вызывать из OnEngage.
function D:Reset(mod)
	mod.__dalaran.state = newState()
end

--- Защита от дублей CLEU и от парных ID одной способности.
-- @return true если событие нужно пропустить
function D:Dedupe(mod, key, time, window)
	local state = mod.__dalaran.state
	local now = time or GetTime()
	if state.seen[key] and now - state.seen[key] < (window or 0.5) then
		return true
	end
	state.seen[key] = now
	return false
end

local function personalText(mod, ability, stacks)
	local text = ability.text or mod:SpellName(ability.key)
	if ability.stackText and stacks and stacks > 1 then
		text = format(ability.stackText, stacks)
	end
	return text
end

--- Личное сообщение + звук только владельцу дебаффа.
-- @param quiet не играть звук (для обновлений стаков ниже порога)
function D:Personal(mod, ability, stacks, quiet)
	mod:PersonalMessage(ability.key, false, personalText(mod, ability, stacks))
	local warned = ability.warnAt and stacks and stacks >= ability.warnAt
	if quiet and not warned then return end
	mod:PlaySound(ability.key, warned and "alarm" or ability.sound or "alert")
end

function D:OnAuraApplied(mod, args)
	local ability = mod.__dalaran.aura[args.spellId]
	if not ability or not args.destGUID or not mod:Me(args.destGUID) then return end
	if D:Dedupe(mod, "aura:" .. ability.key, args.time, 0.2) then return end

	mod.__dalaran.state.stacks[ability.key] = 1
	D:Personal(mod, ability, 1)
end

function D:OnAuraDose(mod, args)
	local ability = mod.__dalaran.aura[args.spellId]
	if not ability or ability.kind ~= "personalStack" then return end
	if not args.destGUID or not mod:Me(args.destGUID) then return end

	local stacks = tonumber(args.amount) or 1
	local state = mod.__dalaran.state
	if state.stacks[ability.key] == stacks then return end
	if D:Dedupe(mod, "stack:" .. ability.key, args.time, 1) then return end

	state.stacks[ability.key] = stacks
	D:Personal(mod, ability, stacks, true)
end

function D:OnAuraRemoved(mod, args)
	local ability = mod.__dalaran.aura[args.spellId]
	if not ability then return end
	if args.destGUID and mod:Me(args.destGUID) then
		mod.__dalaran.state.stacks[ability.key] = nil
	end
end

function D:OnCast(mod, args)
	local ability = mod.__dalaran.cast[args.spellId]
	if not ability then return end
	if ability.sourceMob and mod:MobId(args.sourceGUID) ~= ability.sourceMob then return end
	if D:Dedupe(mod, "cast:" .. ability.key, args.time, ability.dedupe or 0.5) then return end

	local name = ability.name or mod:SpellName(ability.key)
	if ability.message ~= false then
		mod:Message(ability.key, ability.color or "orange", ability.sound, ability.text)
	end
	if ability.castBar then mod:CastBar(ability.key, ability.castBar, name) end
	if ability.bar then mod:Bar(ability.key, ability.bar, name) end
	if ability.cdBar then mod:CDBar(ability.key, ability.cdBar, name) end
end

--- Анонс для уникальных случаев (HP-фазы, эмоуты, ауры на боссе).
function D:Announce(mod, key, color, sound, text, bar, cdBar, castBar)
	local name = mod:SpellName(key)
	mod:Message(key, color or "orange", sound, text)
	if castBar then mod:CastBar(key, castBar, name) end
	if bar then mod:Bar(key, bar, name) end
	if cdBar then mod:CDBar(key, cdBar, name) end
end
