
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Keristrasza", 576, 621)
if not mod then return end
mod:RegisterEnableMob(26723)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		192550, -- Intense Cold
		192553, -- Crystalline Breath
		192555, -- Tail Sweep
		192557, -- Crystallize
		192558, -- Crystallize (aura)
		192559, -- Enrage
		48095, -- Intense Cold (3.3.5 spell id)
		48179, -- Crystallize (3.3.5 spell id)
		50997, -- Crystal Chains
		8599, -- Enrage (3.3.5 spell id)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "IntenseCold", 192550, 48095)
	self:Log("SPELL_AURA_APPLIED_DOSE", "IntenseCold", 192550, 48095)
	self:Log("SPELL_CAST_START", "CrystallineBreath", 192553)
	self:Log("SPELL_CAST_START", "TailSweep", 192555)
	self:Log("SPELL_CAST_START", "Crystallize", 192557)
	self:Log("SPELL_CAST_SUCCESS", "Crystallize", 48179)
	self:Log("SPELL_AURA_APPLIED", "CrystallizeAura", 192558)
	self:Log("SPELL_AURA_REMOVED", "CrystallizeAuraRemoved", 192558)
	self:Log("SPELL_AURA_APPLIED", "CrystalChains", 50997)
	self:Log("SPELL_AURA_REMOVED", "CrystalChainsRemoved", 50997)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 192559, 8599)
	self:Log("SPELL_CAST_SUCCESS", "Enrage", 192559, 8599)

	self:Death("Win", 26723)
end

function mod:OnEngage()
	self:CDBar(192553, 25) -- Crystalline Breath
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:IntenseCold(args)
	if self:Me(args.destGUID) then
		local stacks = args.amount or 1
		self:StackMessage(args.spellId, args.destName, stacks, "blue", stacks > 3 and "Alarm")
	end
end

function mod:CrystallineBreath(args)
	self:Message(args.spellId, "orange", "Alert")
	self:CDBar(args.spellId, 20)
end

function mod:TailSweep(args)
	self:Message(args.spellId, "yellow", self:Melee() and "Alarm")
	self:CDBar(args.spellId, 20)
end

function mod:Crystallize(args)
	self:Message(args.spellId, "red", "Warning")
	self:CDBar(192557, 20)
end

function mod:CrystallizeAura(args)
	self:TargetMessage(args.spellId, args.destName, "orange", "Alarm")
	self:TargetBar(args.spellId, 8, args.destName)
end

function mod:CrystallizeAuraRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:CrystalChains(args)
	self:TargetMessage(args.spellId, args.destName, "yellow")
	self:TargetBar(args.spellId, 10, args.destName)
end

function mod:CrystalChainsRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:Enrage(args)
	self:Message(args.spellId, "red", "Warning", CL.percent:format(20, self:SpellName(args.spellId)))
end
