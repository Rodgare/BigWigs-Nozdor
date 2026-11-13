-------------------------------------------------------------------------------
--  Module Declaration

local mod, CL = BigWigs:NewBoss("Skarvald & Dalronn", 574, 639)
if not mod then return end
mod:RegisterEnableMob(24200, 24201) -- Skarvald the Constructor, Dalronn the Controller
mod.engageId = 2024
mod.respawnTime = 10

-------------------------------------------------------------------------------
--  Locals

local deaths = 0

-------------------------------------------------------------------------------
--  Initialization

function mod:GetOptions()
	return {
		"stages",
		192413, -- Stone Strike
		192410, -- Charge
		192414, -- Enrage
		192415, -- Shadow Bolt
		192416, -- Debilitate
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "StoneStrike", 192413)
	self:Log("SPELL_CAST_START", "Charge", 192410)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 192414)
	self:Log("SPELL_CAST_START", "ShadowBolt", 192415, 192420)
	self:Log("SPELL_CAST_START", "Debilitate", 192416)
	self:Death("Deaths", 24200, 24201)
end

function mod:OnEngage()
	deaths = 0
	self:CDBar(192413, 10)
	self:CDBar(192415, 5)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:StoneStrike(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 10)
end

function mod:Charge(args)
	self:Message(args.spellId, "orange", "Warning", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
	self:CDBar(args.spellId, 37)
end

function mod:Enrage(args)
	self:Message(args.spellId, "orange", "Warning")
end

function mod:ShadowBolt(args)
	self:Message(args.spellId, "yellow", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 1)
	self:CDBar(args.spellId, 5)
end

function mod:Debilitate(args)
	self:Message(args.spellId, "orange", "Alert", CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 2)
end

function mod:Deaths(args)
	deaths = deaths + 1
	if deaths < 2 then
		self:Message("stages", "green", "Info", CL.mob_killed:format(args.destName, deaths, 2), false)
	end
end
