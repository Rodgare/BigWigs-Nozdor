--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewPlugin("Flash")
if not mod then return end

--------------------------------------------------------------------------------
-- Locals
--

local flashFrame, pulseFrame = nil, nil
local flasher, pulser = nil, nil
local colors = nil

-------------------------------------------------------------------------------
-- Initialization
--

do
	flashFrame = UIParent:CreateTexture()
	flashFrame:SetAllPoints(UIParent)
	flashFrame:SetAlpha(0)
	BigWigsTextureSetColor(flashFrame, 0, 0, 1, 0.6)
	flashFrame:Hide()

	-- Nozdor 3.3.5 compatibility: Alpha animation objects lack
	-- SetFromAlpha/SetToAlpha, so drive the flash double-pulse manually
	-- with a shared OnUpdate driver and SetAlpha.
	flasher = {}
	do
		local segments = {
			{dur = 0.2, from = 0, to = 1},
			{dur = 0.2, from = 1, to = 0},
			{dur = 0.2, from = 0, to = 1},
			{dur = 0.2, from = 1, to = 0},
		}
		local totalDuration = 0
		for _, s in ipairs(segments) do totalDuration = totalDuration + s.dur end

		local onFinished
		local flashDriver = CreateFrame("Frame", "BigWigsFlashDriver")
		flashDriver:Hide()
		local startTime

		flashDriver:SetScript("OnUpdate", function(self)
			local elapsed = GetTime() - startTime
			if elapsed >= totalDuration then
				flashFrame:SetAlpha(0)
				self:Hide()
				if onFinished then onFinished() end
				return
			end
			local offset = elapsed
			for _, s in ipairs(segments) do
				if offset < s.dur then
					flashFrame:SetAlpha(s.from + (s.to - s.from) * (offset / s.dur))
					return
				end
				offset = offset - s.dur
			end
		end)

		function flasher:SetScript(script, handler)
			if script == "OnFinished" then onFinished = handler end
		end
		function flasher:Play()
			startTime = GetTime()
			flashFrame:SetAlpha(segments[1].from)
			flashDriver:Show()
		end
		function flasher:Stop()
			flashDriver:Hide()
		end
	end

	pulseFrame = UIParent:CreateTexture()
	pulseFrame:SetPoint("CENTER", UIParent, "CENTER")
	pulseFrame:SetSize(100,100)
	pulseFrame:SetAlpha(0.5)
	pulseFrame:SetTexture("Interface\\Icons\\ability_warrior_charge")
	pulseFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	pulseFrame:Hide()

	pulser = pulseFrame:CreateAnimationGroup()
	pulser:SetScript("OnFinished", function() pulseFrame:Hide() end)

	local pulse1 = pulser:CreateAnimation("Scale")
	pulse1:SetDuration(0.25)
	pulse1:SetScale(2.5,2.5)
	pulse1:SetOrder(1)
	pulse1:SetEndDelay(0.4)
	local pulse2 = pulser:CreateAnimation("Scale")
	pulse2:SetDuration(0.25)
	pulse2:SetScale(0.2,0.2)
	pulse2:SetOrder(2)
end

function mod:OnPluginEnable()
	colors = BigWigs:GetPlugin("Colors")
	self:RegisterMessage("BigWigs_Flash")
	self:RegisterMessage("BigWigs_Pulse")
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BigWigs_Flash(event, module, key)
	if BigWigs.db.profile.flash then
		flasher:Stop()
		if colors then
			local r, g, b = colors:GetColor("flash", module, key)
			BigWigsTextureSetColor(flashFrame, r, g, b, 0.6)
		end
		flashFrame:SetAlpha(0)
		flashFrame:Show()
		flasher:Play()
	end
end

function mod:BigWigs_Pulse(event, _, _, icon)
	pulser:Stop()
	pulseFrame:SetTexture(icon or 134400) -- Interface\\Icons\\INV_Misc_QuestionMark
	pulseFrame:Show()
	pulser:Play()
end

