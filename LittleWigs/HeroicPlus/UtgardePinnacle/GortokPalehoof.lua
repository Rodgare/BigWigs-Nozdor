
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Gortok Palehoof", 575, 642)
if not mod then return end
mod:RegisterEnableMob(
	26687, -- Gortok Palehoof
	26683, -- Frenzied Worgen
	26684, -- Ravenous Furbolg
	26685, -- Massive Jormungar
	26686 -- Ferocious Rhino
)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Gortok Palehoof ]]--
		192580, -- Arc Slash
		192582, -- Impale
		192583, -- Withering Roar

		--[[ Frenzied Worgen ]]--
		192584, -- Mortal Wound
		192585, -- Frenzy
		192586, -- Frenzy

		--[[ Ravenous Furbolg ]]--
		192587, -- Chain Lightning
		192589, -- Enrage
		192590, -- Fearsome Roar

		--[[ Massive Jormungar ]]--
		192592, -- Acid Spit

		--[[ Ferocious Rhino ]]--
		192597, -- Gore
		192598, -- Grievous Wound
		192599, -- Grievous Wound
		192601, -- Stomp
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Cast", 192580, 192582, 192583, 192587, 192590, 192592, 192597, 192598, 192601)
	self:Log("SPELL_AURA_APPLIED", "Aura", 192582, 192583, 192584, 192585, 192586, 192589, 192597, 192599, 192601)

	self:Death("Win", 26687)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Cast(args)
	local id = args.spellId
	local sound
	if id == 192583 or id == 192587 or id == 192592 or id == 192598 or id == 192601 then
		sound = "Warning"
	elseif id == 192580 or id == 192597 then
		sound = "Alert"
	end
	local color = sound == "Warning" and "orange" or sound == "Alert" and "orange" or "yellow"

	self:Message(id, color, sound, CL.casting:format(args.spellName))

	if id == 192580 then -- Arc Slash
		self:CDBar(id, 11)
	elseif id == 192582 then -- Impale
		self:CastBar(id, 2)
	elseif id == 192583 then -- Withering Roar
		self:CastBar(id, 3)
		self:CDBar(id, 22)
	end
end

function mod:Aura(args)
	local id = args.spellId
	if id == 192585 or id == 192586 or id == 192589 then -- Frenzy, Enrage
		self:Message(id, "yellow")
	elseif id == 192582 or id == 192584 or id == 192597 or id == 192599 then -- Impale, Mortal Wound, Gore, Grievous Wound
		if self:Me(args.destGUID) or self:Tank() then
			self:TargetMessage(id, args.destName, "red", "Alarm", nil, nil, true)
		end
	elseif id == 192583 or id == 192601 then -- Withering Roar, Stomp
		if self:Me(args.destGUID) then
			self:Message(id, "orange", "Alert")
		end
	end
end
