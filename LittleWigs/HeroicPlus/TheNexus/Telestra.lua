
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Grand Magus Telestra", 576, 618)
if not mod then return end
mod:RegisterEnableMob(26731)
mod.engageId = 2010

--------------------------------------------------------------------------------
-- Locals
--

local splitPhase = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-7395, -- Mirror Images
		47731, -- Critter
		192510, -- Fire Bomb
		192511, -- Frost Flash
		192515, -- Fire Blast (images)
		192517, -- Blizzard (images)
		192519, -- Frost Spike (images)
		192520, -- Time Stop (images)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Critter", 47731)
	self:Log("SPELL_CAST_START", "FireBomb", 192510)
	self:Log("SPELL_CAST_START", "FrostFlash", 192511)
	self:Log("SPELL_CAST_START", "ImageCast", 192515, 192517, 192519, 192520)

	self:Death("Win", 26731)
end

function mod:OnEngage()
	splitPhase = 0
	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")
	self:CDBar(192510, 5) -- Fire Bomb
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:UNIT_HEALTH_FREQUENT(event, unit)
	local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
	if (hp < 56 and splitPhase == 0) or (hp < 16 and splitPhase == 1) then
		splitPhase = splitPhase + 1
		if splitPhase > 1 or self:Normal() then -- No 2nd split on Normal mode
			self:UnregisterUnitEvent(event, unit)
		end
		self:Message(-7395, "green", nil, CL.soon:format(self:SpellName(-7395)), false)
	end
end

do
	local playerList = mod:NewTargetList()

	function mod:Critter(args)
		playerList[#playerList+1] = args.destName
		if #playerList == 1 then
			self:ScheduleTimer("TargetMessage", 0.3, args.spellId, playerList, "orange", "Alert", nil, nil, self:Dispeller("magic"))
		end
	end
end

function mod:FireBomb(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 14) -- 8-21s between casts
end

function mod:FrostFlash(args)
	self:Message(args.spellId, "blue")
	self:CDBar(args.spellId, 20)
end

function mod:ImageCast(args)
	if args.spellId == 192520 then -- Time Stop
		self:Message(args.spellId, "red", "Warning")
		self:CDBar(args.spellId, 30)
	elseif args.spellId == 192517 then -- Blizzard
		self:Message(args.spellId, "orange", "Alarm")
	elseif args.spellId == 192519 then -- Frost Spike
		self:Message(args.spellId, "blue")
	else -- Fire Blast
		self:Message(args.spellId, "yellow")
	end
end
