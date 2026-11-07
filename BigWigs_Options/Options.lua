local _,_,_,toc = GetBuildInfo() -- XXX Remove after beta
local BigWigs = BigWigs
local options = {}

local C = BigWigs.C

local L = BigWigsAPI:GetLocale("BigWigs")

local ldbi = LibStub("LibDBIcon-1.0")
local acr = LibStub("BW-AceConfigRegistry-3.0")
local acd = LibStub("BW-AceConfigDialog-3.0")
local AceGUI = LibStub("BW-AceGUI-3.0")
local adbo = LibStub("BW-AceDBOptions-3.0")
local lds = LibStub("BW-LibDualSpec-1.0")

local loader = BigWigsLoader
local API = BigWigsAPI
local sort = table.sort
options.SendMessage = loader.SendMessage

local bwTooltip = CreateFrame("GameTooltip", "BigWigsOptionsTooltip", UIParent, "GameTooltipTemplate")

local colorModule
local soundModule
local isOpen, isPluginOpen

local showToggleOptions, getAdvancedToggleOption = nil, nil

local getOptions
local acOptions = {
	type = "group",
	name = "BigWigs",
	get = function(info)
		return BigWigs.db.profile[info[#info]]
	end,
	set = function(info, value)
		local key = info[#info]
		BigWigs.db.profile[key] = value
		options:SendMessage("BigWigs_CoreOptionToggled", key, value)
	end,
	args = {
		general = {
			order = 20,
			type = "group",
			name = "BigWigs",
			args = {
				minimap = {
					type = "toggle",
					name = L.minimapIcon,
					desc = L.minimapToggle,
					order = 13,
					get = function() return not BigWigsIconDB.hide end,
					set = function(_, v)
						if v then
							BigWigsIconDB.hide = nil
							ldbi:Show("BigWigs")
						else
							BigWigsIconDB.hide = true
							ldbi:Hide("BigWigs")
						end
					end,
					width = "full",
				},
				separator2 = {
					type = "description",
					name = " ",
					order = 14,
					width = "full",
				},
				flash = {
					type = "toggle",
					name = L.flashScreen,
					desc = L.flashScreenDesc,
					order = 22,
				},
				chat = {
					type = "toggle",
					name = L.chatMessages,
					desc = L.chatMessagesDesc,
					order = 25,
					width = "full",
					get = function() return BigWigs:GetPlugin("Messages").db.profile.chat end,
					set = function(_, v) BigWigs:GetPlugin("Messages").db.profile.chat = v end,
				},
				separator3 = {
					type = "description",
					name = " ",
					order = 30,
					width = "full",
				},
				showZoneMessages = {
					type = "toggle",
					name = L.zoneMessages,
					desc = L.zoneMessagesDesc,
					order = 32,
					width = "full",
				},
				separator4 = {
					type = "description",
					name = " ",
					order = 40,
					width = "full",
				},
				fakeDBMVersion = {
					type = "toggle",
					name = L.dbmFaker,
					desc = L.dbmFakerDesc,
					order = 41,
					width = "full",
				},
				slashDescTitle = {
					type = "description",
					name = "\n".. L.slashDescTitle,
					fontSize = "large",
					order = 43,
					width = "full",
				},
				slashDescPull = {
					type = "description",
					name = "  ".. L.slashDescPull,
					fontSize = "medium",
					order = 44,
					width = "full",
				},
				slashDescBreak = {
					type = "description",
					name = "  ".. L.slashDescBreak,
					fontSize = "medium",
					order = 45,
					width = "full",
				},
				slashDescBar = {
					type = "description",
					name = "  ".. L.slashDescRaidBar,
					fontSize = "medium",
					order = 46,
					width = "full",
				},
				slashDescLocalBar = {
					type = "description",
					name = "  ".. L.slashDescLocalBar,
					fontSize = "medium",
					order = 47,
					width = "full",
				},
				slashDescRange = {
					type = "description",
					name = "  ".. L.slashDescRange,
					fontSize = "medium",
					order = 48,
					width = "full",
				},
				slashDescVersion = {
					type = "description",
					name = "  ".. L.slashDescVersion,
					fontSize = "medium",
					order = 49,
					width = "full",
				},
				slashDescConfig = {
					type = "description",
					name = "  ".. L.slashDescConfig,
					fontSize = "medium",
					order = 50,
					width = "full",
				},
				gitHubDesc = {
					type = "description",
					name = "\n".. L.gitHubDesc .."\n",
					fontSize = "medium",
					order = 51,
					width = "full",
				},
				discord = {
					type = "input",
					get = function() return "discord.gg/jGveg85" end,
					set = function() end,
					name = "Discord",
					order = 52,
					width = 0.75,
				},
				github = {
					type = "input",
					get = function() return "github.com/BigWigsMods" end,
					set = function() end,
					name = "GitHub",
					order = 53,
					width = 0.95,
				},
				curseforge = {
					type = "input",
					get = function() return "curseforge.com/wow/addons/big-wigs" end,
					set = function() end,
					name = "CurseForge",
					order = 54,
					width = 1.32,
				},
			},
		},
	},
}

do
	local addonName = ...
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	local function Initialize(_, _, addon)
		if addon ~= addonName then return end
		f:UnregisterEvent("ADDON_LOADED")

		acOptions.args.general.args.profileOptions = adbo:GetOptionsTable(BigWigs.db)
		acOptions.args.general.args.profileOptions.order = 1
		lds:EnhanceOptions(acOptions.args.general.args.profileOptions, BigWigs.db)

		acr:RegisterOptionsTable("BigWigs", getOptions, true)
		acd:SetDefaultSize("BigWigs", 858, 660)

		acr.RegisterCallback(options, "ConfigTableChange")

		colorModule = BigWigs:GetPlugin("Colors")
		soundModule = BigWigs:GetPlugin("Sounds")
		acr:RegisterOptionsTable("BigWigs: Colors Override", colorModule:SetColorOptions("dummy", "dummy"), true)
		acr:RegisterOptionsTable("BigWigs: Sounds Override", soundModule:SetSoundOptions("dummy", "dummy"), true)

		loader.RegisterMessage(options, "BigWigs_BossModuleRegistered", "Register")
		loader.RegisterMessage(options, "BigWigs_PluginRegistered", "Register")

		for name, module in BigWigs:IterateBossModules() do
			options:Register("BigWigs_BossModuleRegistered", name, module)
		end
		for name, module in BigWigs:IteratePlugins() do
			options:Register("BigWigs_PluginRegistered", name, module)
		end

		loader.RegisterMessage(options, "BigWigs_StartConfigureMode")
		loader.RegisterMessage(options, "BigWigs_StopConfigureMode")

		-- Wait with nilling, we don't know how many addons will load during this same execution.
		loader.CTimerAfter(5, function() f:SetScript("OnEvent", nil) end)
	end
	f:SetScript("OnEvent", Initialize)
end

function options:Open()
	if isOpen then
		isOpen:Hide()
	else
		options:OpenConfig()
	end
end

function options:IsOpen()
	return isOpen
end

-------------------------------------------------------------------------------
-- Plugin options
--

do
	local configMode = nil
	function options:InConfigureMode() return configMode end
	function options:BigWigs_StartConfigureMode()
		configMode = true
	end
	function options:BigWigs_StopConfigureMode()
		configMode = nil
	end
end

local function getMasterOption(self)
	local key = self:GetUserData("key")
	local module = self:GetUserData("module")
	if type(key) == "string" and key:find("^custom_") then
		return module.db.profile[key]
	end
	if type(module.db.profile[key]) ~= "number" then
		module.db.profile[key] = module.toggleDefaults[key]
	end
	if module.db.profile[key] == 0 then
		return false -- nothing go away
	end
	if bit.band(module.db.profile[key], module.toggleDefaults[key]) == module.toggleDefaults[key] then
		return true -- all default baby
	end
	return nil -- some options set
end

local notNumberError = "The option %q for module %q either has a mismatched current value (%q) or target value (%q)."
local function getSlaveOption(self)
	local key = self:GetUserData("key")
	local module = self:GetUserData("module")
	local flag = self:GetUserData("flag")
	local current = module.db.profile[key]
	if type(current) ~= "number" or type(flag) ~= "number" then
		error(notNumberError:format(tostringall(key, module.moduleName, current, flag)))
	end
	return bit.band(current, flag) == flag
end

local function masterOptionToggled(self, event, value)
	if value == nil then self:SetValue(false) end -- toggling the master toggles all (we just pretend to be a tristate)
	local key = self:GetUserData("key")
	local module = self:GetUserData("module")
	if type(key) == "string" and key:find("custom_", nil, true) then
		module.db.profile[key] = value or false
	else
		if value then
			-- If an option is disabled by default using the "OFF" toggle flag, then when we turn it on, we want all the default flags on also
			module.db.profile[key] = module.toggleDisabled and module.toggleDisabled[key] or module.toggleDefaults[key]
		else
			module.db.profile[key] = 0
		end
		local dropdown = self:GetUserData("dropdown")
		-- This data ONLY exists if we're looking at the advanced options tab,
		-- we force a refresh of all checkboxes when enabling/disabling the master option.
		if dropdown then
			local scrollFrame = self:GetUserData("scrollFrame")
			local bossOption = self:GetUserData("option")
			scrollFrame:ReleaseChildren()
			scrollFrame:AddChildren(getAdvancedToggleOption(scrollFrame, dropdown, module, bossOption))
			scrollFrame:PerformLayout()
		end
	end

	-- After :SetValue so it's not overwritten
	self.text:SetTextColor(1, 0.82, 0)
end

local function slaveOptionToggled(self, event, value)
	local key = self:GetUserData("key")
	local module = self:GetUserData("module")
	local flag = self:GetUserData("flag")
	local master = self:GetUserData("master")
	if value then
		module.db.profile[key] = module.db.profile[key] + flag
	else
		module.db.profile[key] = module.db.profile[key] - flag
	end
	master:SetValue(getMasterOption(master))

	-- After :SetValue so it's not overwritten
	master.text:SetTextColor(1, 0.82, 0)
	self.text:SetTextColor(1, 0.82, 0)
end

local function slaveOptionMouseOver(self, event, value)
	bwTooltip:SetOwner(self.frame, "ANCHOR_TOP")
	bwTooltip:AddLine(self:GetUserData("desc"), 1, 1, 1, true)
	bwTooltip:Show()
end

local function slaveOptionMouseLeave()
	bwTooltip:Hide()
end

local function getSlaveToggle(label, desc, key, module, flag, master, icon)
	local toggle = AceGUI:Create("CheckBox")
	toggle:SetLabel(label)
	-- Flags to have at half width
	if flag == C.PULSE then
		toggle:SetRelativeWidth(0.5)
	elseif flag == C.ME_ONLY or flag == C.ME_ONLY_EMPHASIZE or flag == C.CASTBAR then
		toggle:SetRelativeWidth(0.4)
	else
		toggle:SetRelativeWidth(0.3)
	end
	toggle:SetHeight(30)

	if icon then
		toggle:SetImage(icon)
	end
	toggle:SetUserData("key", key)
	toggle:SetUserData("desc", desc)
	toggle:SetUserData("module", module)
	toggle:SetUserData("flag", flag)
	toggle:SetUserData("master", master)
	toggle:SetCallback("OnValueChanged", slaveOptionToggled)
	toggle:SetCallback("OnEnter", slaveOptionMouseOver)
	toggle:SetCallback("OnLeave", slaveOptionMouseLeave)
	toggle:SetValue(getSlaveOption(toggle))
	toggle.text:SetTextColor(1, 0.82, 0) -- After :SetValue so it's not overwritten
	return toggle
end

-- Nozdor 3.3.5: the original retail values were numeric file-IDs and most of
-- them (Priest_spell_leapoffaith_b, Achievement_GarrisonQuests_0005, UI_Chat,
-- Warrior_DisruptingShout, ...) do not exist in the WotLK client, so the
-- checkbox icons rendered as red squares. Replaced with the actual vanilla /
-- WotLK texture paths shipped in the 3.3.5 client.
local icons = {
	MESSAGE = "Interface\\Icons\\INV_MISC_NOTE_06", -- note / scroll
	ME_ONLY = "Interface\\Icons\\ability_hunter_pathfinding", -- star marker ("on me")
	SOUND = "Interface\\Common\\VoiceChat-On", -- voice on
	ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- raid target marker
	FLASH = "Interface\\Icons\\Spell_Frost_FrostShock", -- frost bolt
	PULSE = "Interface\\Icons\\Spell_Arcane_Arcane04", -- arcane pulse
	PROXIMITY = "Interface\\Icons\\ability_warrior_charge", -- dart / charge
	ALTPOWER = "Interface\\Icons\\ability_hunter_pathfinding", -- empowered star
	INFOBOX = "Interface\\Icons\\inv_misc_pocketwatch_02", -- watch
	COUNTDOWN = "Interface\\Icons\\inv_misc_pocketwatch_02", -- watch
	SAY = "Interface\\Icons\\INV_MISC_NOTE_06", -- chat / note
	SAY_COUNTDOWN = "Interface\\Icons\\INV_MISC_NOTE_06", -- chat / note
	VOICE = "Interface\\Common\\VoiceChat-On", -- voice on
	NAMEPLATEBAR = "Interface\\Icons\\inv_misc_pocketwatch_02", -- watch
}

local function hasOptionFlag(dbKey, module, key)
	-- Check the actual option table instead of using toggleDefaults
	for _, opTbl in next, module.toggleOptions do
		if type(opTbl) == "table" and opTbl[1] == dbKey then
			for i = 2, #opTbl do
				if opTbl[i] == key then
					return true
				end
			end
		end
	end
end

local function advancedToggles(dbKey, module, check)
	local dbv = module.toggleDisabled and module.toggleDisabled[dbKey] or module.toggleDefaults[dbKey]
	local advancedOptions = {}

	if bit.band(dbv, C.MESSAGE) == C.MESSAGE then
		-- Emphasize & Countdown widgets
		advancedOptions[1] = getSlaveToggle(L.EMPHASIZE, L.EMPHASIZE_desc, dbKey, module, C.EMPHASIZE, check)
		advancedOptions[2] = getSlaveToggle(L.ME_ONLY_EMPHASIZE, L.ME_ONLY_EMPHASIZE_desc, dbKey, module, C.ME_ONLY_EMPHASIZE, check)
		advancedOptions[3] = getSlaveToggle(L.COUNTDOWN, L.COUNTDOWN_desc, dbKey, module, C.COUNTDOWN, check, icons["COUNTDOWN"])
		--

		-- Messages & Sound
		advancedOptions[4] = getSlaveToggle(L.MESSAGE, L.MESSAGE_desc, dbKey, module, C.MESSAGE, check, icons["MESSAGE"])
		advancedOptions[5] = getSlaveToggle(L.ME_ONLY, L.ME_ONLY_desc, dbKey, module, C.ME_ONLY, check, icons["ME_ONLY"])
		advancedOptions[6] = getSlaveToggle(L.SOUND, L.SOUND_desc, dbKey, module, C.SOUND, check, icons["SOUND"])
		--

		-- Bars
		advancedOptions[7] = getSlaveToggle(L.BAR, L.BAR_desc, dbKey, module, C.BAR, check)
		advancedOptions[8] = getSlaveToggle(L.CASTBAR, L.CASTBAR_desc, dbKey, module, C.CASTBAR, check)
		--
	end

	if bit.band(dbv, C.NAMEPLATEBAR) == C.NAMEPLATEBAR and hasOptionFlag(dbKey, module, "NAMEPLATEBAR") then
		advancedOptions[#advancedOptions + 1] = getSlaveToggle(L.NAMEPLATEBAR, L.NAMEPLATEBAR_desc, dbKey, module, C.NAMEPLATEBAR, check, icons["NAMEPLATEBAR"])
	end

	-- Flash & Pulse
	if bit.band(dbv, C.FLASH) == C.FLASH and hasOptionFlag(dbKey, module, "FLASH") then
		advancedOptions[#advancedOptions + 1] = getSlaveToggle(L.FLASH, L.FLASH_desc, dbKey, module, C.FLASH, check, icons["FLASH"])
		advancedOptions[#advancedOptions + 1] = getSlaveToggle(L.PULSE, L.PULSE_desc, dbKey, module, C.PULSE, check, icons["PULSE"])
	end
	--

	if bit.band(dbv, C.MESSAGE) == C.MESSAGE then
		if API:HasVoicePack() then
			advancedOptions[#advancedOptions + 1] = getSlaveToggle(L.VOICE, L.VOICE_desc, dbKey, module, C.VOICE, check, icons["VOICE"])
		end
	end

	for i, key in next, BigWigs:GetOptions() do
		local flag = C[key]
		if bit.band(dbv, flag) == flag then
			local name, desc = BigWigs:GetOptionDetails(key)
			-- All on by default, check if we should add a GUI widget
			if key == "ICON" or key == "SAY" or key == "SAY_COUNTDOWN" or key == "PROXIMITY" or key == "ALTPOWER" or key == "INFOBOX" then
				if hasOptionFlag(dbKey, module, key) then
					advancedOptions[#advancedOptions + 1] = getSlaveToggle(name, desc, dbKey, module, flag, check, icons[key])
				end
			elseif key ~= "MESSAGE" and key ~= "BAR" and key ~= "FLASH" and key ~= "VOICE" then
				advancedOptions[#advancedOptions + 1] = getSlaveToggle(name, desc, dbKey, module, flag, check)
			end
		end
	end

	return unpack(advancedOptions)
end

local function advancedTabSelect(widget, callback, tab)
	if widget:GetUserData("tab") == tab then return end
	widget:SetUserData("tab", tab)
	widget:PauseLayout()
	widget:ReleaseChildren()
	local module = widget:GetUserData("module")
	local key = widget:GetUserData("key")
	local master = widget:GetUserData("master")

	if tab == "options" then
		widget:AddChildren(advancedToggles(key, module, master))
	elseif tab == "sounds" then
		local group = AceGUI:Create("SimpleGroup")
		group:SetFullWidth(true)
		widget:AddChild(group)
		soundModule:SetSoundOptions(module.name, key, module.db.profile[key])
		acd:Open("BigWigs: Sounds Override", group)
	elseif tab == "colors" then
		local group = AceGUI:Create("SimpleGroup")
		group:SetFullWidth(true)
		widget:AddChild(group)
		colorModule:SetColorOptions(module.name, key, module.toggleDefaults[key])
		acd:Open("BigWigs: Colors Override", group)
	end
	widget:ResumeLayout()
	widget:GetUserData("scrollFrame"):PerformLayout()
	widget:PerformLayout()
end

local advancedTabs = {
	{
		text = L.advanced,
		value = "options",
	},
	{
		text = L.colors,
		value = "colors",
	},
	{
		text = L.sound,
		value = "sounds",
	},
}

function getAdvancedToggleOption(scrollFrame, dropdown, module, bossOption)
	local dbKey, name, desc, icon, alternativeName = BigWigs:GetBossOptionDetails(module, bossOption)
	local back = AceGUI:Create("Button")
	back:SetText(L.back)
	back:SetFullWidth(true)
	back:SetCallback("OnClick", function()
		showToggleOptions(dropdown, nil, dropdown:GetUserData("bossIndex"))
	end)

	local check = AceGUI:Create("CheckBox")
	check:SetLabel(alternativeName and L.alternativeName:format(name, alternativeName) or name)
	check:SetTriState(true)
	check:SetFullWidth(true)
	check:SetDescription(desc)
	check:SetUserData("key", dbKey)
	check:SetUserData("scrollFrame", scrollFrame)
	check:SetUserData("dropdown", dropdown)
	check:SetUserData("module", module)
	check:SetUserData("option", bossOption)
	check:SetCallback("OnValueChanged", masterOptionToggled)
	check:SetValue(getMasterOption(check))
	check.text:SetTextColor(1, 0.82, 0) -- After :SetValue so it's not overwritten
	if icon then
		check:SetImage(icon, 0.07, 0.93, 0.07, 0.93)
	end

	-- Create role-specific secondary checkbox
	local roleRestrictionCheckbox = nil
	for i, key in next, BigWigs:GetRoleOptions() do
		local flag = C[key]
		local dbv = module.toggleDisabled and module.toggleDisabled[dbKey] or module.toggleDefaults[dbKey]
		if bit.band(dbv, flag) == flag then
			local roleName, roleDesc = BigWigs:GetOptionDetails(key)
			roleRestrictionCheckbox = getSlaveToggle(roleName, roleDesc, dbKey, module, flag, check)
		end
	end

	local tabs = AceGUI:Create("TabGroup")
	tabs:SetLayout("Flow")
	tabs:SetTabs(advancedTabs)
	tabs:SetFullWidth(true)
	tabs:SetCallback("OnGroupSelected", advancedTabSelect)
	tabs:SetUserData("tab", "")
	tabs:SetUserData("key", dbKey)
	tabs:SetUserData("module", module)
	tabs:SetUserData("master", check)
	tabs:SetUserData("scrollFrame", scrollFrame)
	tabs:SelectTab("options")

	if roleRestrictionCheckbox then
		return back, check, roleRestrictionCheckbox, tabs
	else
		return back, check, tabs
	end
end

local spellUpdater = CreateFrame("Frame")
local needsUpdate, needsLayout = {}, {}

local function RefreshOnUpdate(self)
	local scrollFrame = nil
	for widget in next, needsLayout do
		needsLayout[widget] = nil
		scrollFrame = widget:GetUserData("scrollFrame")
		local module, bossOption = widget:GetUserData("module"), widget:GetUserData("option")
		local _, _, desc = BigWigs:GetBossOptionDetails(module, bossOption)
		widget:SetDescription(desc)
	end
	if scrollFrame then
		scrollFrame:PerformLayout()
	end
	self:SetScript("OnUpdate", nil)
end

spellUpdater:SetScript("OnEvent", function(self, event, spellId, success)
	if success and needsUpdate[spellId] then
		needsLayout[needsUpdate[spellId]] = true
		local desc = GetSpellDescription(spellId)
		self:SetScript("OnUpdate", RefreshOnUpdate)
	end
	needsUpdate[spellId] = nil
end)
spellUpdater:RegisterEvent("SPELL_DATA_LOAD_RESULT")

local function clearPendingUpdates()
	spellUpdater:SetScript("OnUpdate", nil)
	wipe(needsUpdate)
	wipe(needsLayout)
end

local function buttonClicked(widget)
	clearPendingUpdates()
	local scrollFrame = widget:GetUserData("scrollFrame")
	local dropdown = widget:GetUserData("dropdown")
	local module = widget:GetUserData("module")
	local bossOption = widget:GetUserData("bossOption")
	scrollFrame:ReleaseChildren()
	scrollFrame:SetScroll(0)
	scrollFrame:AddChildren(getAdvancedToggleOption(scrollFrame, dropdown, module, bossOption))
	scrollFrame:PerformLayout()
end

local function flagOnEnter(widget)
	bwTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
	bwTooltip:SetText(widget:GetUserData("tooltipText"), 1, 1, 1, true)
	bwTooltip:Show()
end

local function flagOnLeave()
	bwTooltip:Hide()
end

local function getDefaultToggleOption(scrollFrame, dropdown, module, bossOption)
	local dbKey, name, desc, icon, alternativeName = BigWigs:GetBossOptionDetails(module, bossOption)
	-- Nozdor 3.3.5: options without locale title/description must still render
	if name == nil then name = tostring(dbKey) end
	if desc == nil then desc = "" end

	local check = AceGUI:Create("CheckBox")
	check:SetLabel(alternativeName and L.alternativeName:format(name, alternativeName) or name)
	check:SetTriState(true)
	check:SetRelativeWidth(0.85)
	check:SetUserData("key", dbKey)
	check:SetUserData("module", module)
	check:SetUserData("option", bossOption)
	check:SetUserData("scrollFrame", scrollFrame)
	check:SetDescription(desc)
	check:SetCallback("OnValueChanged", masterOptionToggled)
	check:SetValue(getMasterOption(check))
	check.text:SetTextColor(1, 0.82, 0) -- After :SetValue so it's not overwritten
	if icon then check:SetImage(icon, 0.07, 0.93, 0.07, 0.93) end

	local spellId = nil
	if type(dbKey) == "number" then
		if dbKey < 0 then
			-- the "why did you use an ej id instead of the spell directly" check
			-- headers and other non-spell entries don't load async
			-- Nozdor 3.3.5: GetSectionInfo returns nil for these ids (no dungeon
			-- journal data on this client), so guard before indexing.
			local info = C_EncounterJournal and C_EncounterJournal.GetSectionInfo and C_EncounterJournal.GetSectionInfo(-dbKey)
			if info and info.spellID and info.spellID > 0 then
				spellId = info.spellID
			end
		else
			spellId = dbKey
		end
	else
		local L = module:GetLocale(true)
		local title, description = L[dbKey], L[dbKey .. "_desc"]
		if type(title) == "number" and not description then
			spellId = title
		elseif type(description) == "number" then
			spellId = description
		end
	end
	-- Nozdor 3.3.5: C_Spell (retail spell-data prefetch) may be absent / a no-op;
	-- guard so the options screen can never crash on a spell that isn't cached.
	if spellId and C_Spell and C_Spell.IsSpellDataCached and not C_Spell.IsSpellDataCached(spellId) then
		needsUpdate[spellId] = check
		if C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(spellId) end
	end

	if type(dbKey) == "string" and dbKey:find("^custom_") then
		return check   -- no ">>" button for custom toggles
	end

	local flagIcons = {}
	local showFlags = {
		"TANK_HEALER", "TANK", "HEALER", "DISPEL",
		"EMPHASIZE", "ME_ONLY", "ME_ONLY_EMPHASIZE", "COUNTDOWN", "FLASH", "ICON", "SAY", "SAY_COUNTDOWN",
		"PROXIMITY", "INFOBOX", "ALTPOWER", "NAMEPLATEBAR",
	}
	for i = 1, #showFlags do
		local key = showFlags[i]
		if hasOptionFlag(dbKey, module, key) and (key ~= "SAY_COUNTDOWN" or not hasOptionFlag(dbKey, module, "SAY")) then -- don't show both SAY and SAY_COUNTDOWN
			local icon = AceGUI:Create("Icon")
			icon:SetWidth(16)
			icon:SetImageSize(16, 16)
			icon:SetUserData("tooltipText", L[key])
			icon:SetCallback("OnEnter", flagOnEnter)
			icon:SetCallback("OnLeave", flagOnLeave)

			-- Nozdor 3.3.5: retail used numeric file-IDs into atlas textures that
			-- don't exist on the WotLK client (337497 = LFG PORTRAITROLES, 521749 =
			-- huge retail EncounterJournal atlas). WotLK did ship the LFG role atlas
			-- as a real texture file, so reference it by PATH instead of file-ID and
			-- keep the same sub-rectangles; Dispel/Emphasize get plain WotLK icons.
			local EJ_ICONS = "Interface\\EncounterJournal\\UI-EJ-Icons" -- NOT in 3.3.5
			local LFG_ROLES = "Interface\\LFGFRAME\\UI-LFG-ICON-PORTRAITROLES"
			if key == "TANK" then
				icon:SetImage(LFG_ROLES, 0, 0.296875, 0.34375, 0.640625)
			elseif key == "HEALER" then
				icon:SetImage(LFG_ROLES, 0.3125, 0.609375, 0.015625, 0.3125)
			elseif key == "TANK_HEALER" then
				-- add both "TANK" and "HEALER" icons
				local icon1 = AceGUI:Create("Icon")
				icon1:SetWidth(16)
				icon1:SetImage(LFG_ROLES, 0, 0.2968754, 0.34375, 0.640625) -- TANK
				icon1:SetImageSize(16, 16)
				icon1:SetUserData("tooltipText", L[key])
				icon1:SetCallback("OnEnter", flagOnEnter)
				icon1:SetCallback("OnLeave", flagOnLeave)
				icon1.frame:SetParent(check.frame)
				icon1.frame:Show()
				flagIcons[#flagIcons+1] = icon1
				-- first icon, don't bother with SetPoint

				icon:SetImage(LFG_ROLES, 0.3125, 0.609375, 0.015625, 0.3125) -- HEALER
			elseif key == "DISPEL" then
				icon:SetImage(icons["ME_ONLY"]) -- star marker, exists in WotLK
			-- elseif key == "INTERRUPT" then -- just incase :p EJ interrupt icon
			-- 	icon:SetImage(EJ_ICONS, 0.7734375, 0.8515625, 0.09375, 0.40625)
			elseif key == "EMPHASIZE" or key == "ME_ONLY_EMPHASIZE" then
				icon:SetImage(icons["FLASH"]) -- frost bolt, exists in WotLK
			else
				icon:SetImage(icons[key])
			end

			-- Combine the two SAY options
			if key == "SAY" and hasOptionFlag(dbKey, module, "SAY_COUNTDOWN") then
				icon:SetUserData("tooltipText", L[key] .. PLAYER_LIST_DELIMITER .. L["SAY_COUNTDOWN"])
			end

			icon.frame:SetParent(check.frame)
			icon.frame:Show()

			flagIcons[#flagIcons+1] = icon
			if #flagIcons > 1 then
				icon:SetPoint("LEFT", flagIcons[#flagIcons-1].frame, "RIGHT", 1, 0)
			end
		end
	end

	if #flagIcons > 0 then
		-- flagIcons[1]:SetPoint("LEFT", check.text, "RIGHT", -(#flagIcons * (16+1)) - 30, 0)
		flagIcons[1]:SetPoint("LEFT", check.text, "LEFT", check.text:GetStringWidth() + 5, 0)

		-- need to clean these up since they are not added to a container
		check:SetUserData("icons", flagIcons)
		check:SetCallback("OnRelease", function(widget)
			for _, icon in next, widget:GetUserData("icons") do
				icon:Release()
			end
		end)
	end

	local button = AceGUI:Create("Button")
	button:SetText(">>")
	button:SetRelativeWidth(0.15)
	button:SetUserData("scrollFrame", scrollFrame)
	button:SetUserData("dropdown", dropdown)
	button:SetUserData("module", module)
	button:SetUserData("bossOption", bossOption)
	button:SetCallback("OnClick", buttonClicked)

	return check, button
end

local listAbilitiesInChat = nil
do
	local SendChatMessage = loader.SendChatMessage
	local function output(channel, ...)
		if channel then
			SendChatMessage(strjoin(" ", ...), channel)
		else
			print(...)
		end
	end

	local function printList(channel, header, list)
		if #list == 0 then return end
		if header then output(channel, header, unpack(list))
		else output(channel, unpack(list)) end
	end

	function listAbilitiesInChat(widget)
		local module = widget:GetUserData("module")
		local channel = IsInGroup(2) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY"
		local abilities = {}
		local header = nil
		output(channel, "BigWigs: ", module.displayName or module.moduleName or module.name)
		local currentSize = 0
		for i, option in next, module.toggleOptions do
			local o = type(option) == "table" and option[1] or option

			if module.optionHeaders and module.optionHeaders[o] then
				-- print what we have so far
				printList(channel, header, abilities)
				wipe(abilities)
				header = module.optionHeaders[o]
				currentSize = #header
			end

			local link
			if type(o) == "number" then
				if o > 0 then
					local spellLink = GetSpellLink(o)
					if not spellLink then
						local spellName = GetSpellInfo(o)
						-- Nozdor 3.3.5: some ids have no name here, guard the format
						link = ("\124cff71d5ff\124Hspell:%d:0\124h[%s]\124h\124r"):format(o, spellName or tostring(o))
						--BigWigs:Error(("Failed to fetch the link for spell id %d, tell the authors."):format(o))
					else
						link = spellLink
					end
				else
					-- Nozdor 3.3.5: no journal data, so there is no link to build.
					local tbl = C_EncounterJournal and C_EncounterJournal.GetSectionInfo and C_EncounterJournal.GetSectionInfo(-o)
					if tbl and tbl.link then
						link = tbl.link
					end
				end
			elseif type(o) == "string" then -- Attempt to build links for strings that are just basic spell renaming
				local L = module:GetLocale()
				if L then
					local name, desc, icon = L[o], L[o.."_desc"], L[o.."_icon"]
					if name and type(desc) == "number" and desc == icon then
						if desc > 0 then
							local spellName = GetSpellInfo(desc)
							link = ("\124cff71d5ff\124Hspell:%d:0\124h[%s]\124h\124r"):format(desc, spellName)
						else
							-- EJ?
						end
					end
				end
			end

			if link then
				if currentSize + #link + 1 > 255 then
					printList(channel, header, abilities)
					wipe(abilities)
					currentSize = 0
				end
				abilities[#abilities + 1] = link
				currentSize = currentSize + #link + 1
			end
		end
		printList(channel, header, abilities)
	end
end

local function SecondsToTime(time)
	local m = floor(time/60)
	local s = mod(time, 60)
	return ("%d:%02d"):format(m, s)
end

local function populateToggleOptions(widget, module)
	clearPendingUpdates()
	local scrollFrame = widget:GetUserData("parent")
	scrollFrame:ReleaseChildren()
	scrollFrame:PauseLayout()

	local id = module.instanceId

	local sDB = BigWigsStatsDB
	if module.journalId and id and id > 0 and BigWigs:GetPlugin("Statistics").db.profile.enabled and sDB and sDB[id] and sDB[id][module.journalId] then
		sDB = sDB[id][module.journalId]

		if next(sDB) then -- Create statistics table
			local statGroup = AceGUI:Create("InlineGroup")
			statGroup:SetTitle(L.statistics)
			statGroup:SetLayout("Flow")
			statGroup:SetFullWidth(true)
			scrollFrame:AddChild(statGroup)

			local statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText("")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.lfr)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.normal)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.heroic)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.mythic)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetFullWidth(true)
			statistics:SetText("")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.wipes)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.LFR and sDB.LFR.wipes or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.normal and sDB.normal.wipes or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.heroic and sDB.heroic.wipes or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.mythic and sDB.mythic.wipes or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetFullWidth(true)
			statistics:SetText("")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.kills)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.LFR and sDB.LFR.kills or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.normal and sDB.normal.kills or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.heroic and sDB.heroic.kills or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.mythic and sDB.mythic.kills or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetFullWidth(true)
			statistics:SetText("")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(L.best)
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.LFR and sDB.LFR.best and SecondsToTime(sDB.LFR.best) or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.normal and sDB.normal.best and SecondsToTime(sDB.normal.best) or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.heroic and sDB.heroic.best and SecondsToTime(sDB.heroic.best) or "-")
			statGroup:AddChild(statistics)

			statistics = AceGUI:Create("Label")
			statistics:SetWidth(100)
			statistics:SetText(sDB.mythic and sDB.mythic.best and SecondsToTime(sDB.mythic.best) or "-")
			statGroup:AddChild(statistics)
		end -- End statistics table
	end

	if module.SetupOptions then
		local setupOk = pcall(module.SetupOptions, module)
		if not setupOk then
			BigWigs:Print(("Options for '%s' could not be loaded."):format(tostring(module.name)))
		end
	end
	if module.toggleOptions then
	for i, option in next, module.toggleOptions do
		local o = option
		if type(o) == "table" then o = option[1] end
		if module.optionHeaders and module.optionHeaders[o] then
			local header = AceGUI:Create("Heading")
			header:SetText(module.optionHeaders[o])
			header:SetFullWidth(true)
			scrollFrame:AddChild(header)
		end
		-- Nozdor 3.3.5: one malformed option must not wipe out the whole boss panel.
		-- AddChildren(nil) would crash inside AceGUI, so add only non-nil widgets.
		local ok, check, button = pcall(getDefaultToggleOption, scrollFrame, widget, module, option)
		if ok then
			if check then scrollFrame:AddChild(check) end
			if button then scrollFrame:AddChild(button) end
		end
	end
	end -- end toggleOptions guard
	local list = AceGUI:Create("Button")
	list:SetFullWidth(true)
	list:SetText(L.listAbilities)
	list:SetUserData("module", module)
	list:SetCallback("OnClick", listAbilitiesInChat)
	scrollFrame:AddChild(list)
	scrollFrame:SetScroll(0)
	scrollFrame:ResumeLayout()
	scrollFrame:PerformLayout()
end

function showToggleOptions(widget, event, group)
	local module = BigWigs:GetBossModule(group)
	widget:SetUserData("bossIndex", group)
	populateToggleOptions(widget, module)
end

local function onZoneShow(treeWidget, id)
	-- Make sure all the bosses for this zone are loaded.
	loader:LoadZone(id)

	-- Grab the module list from this zone
	local moduleList = loader:GetZoneMenus()[id]
	if type(moduleList) ~= "table" then return end -- No modules registered

	local zoneList, zoneSort = {}, {}
	for i = 1, #moduleList do
		local module = moduleList[i]
		zoneList[module.moduleName] = module.displayName
		zoneSort[i] = module.moduleName
	end

	local outerContainer = AceGUI:Create("SimpleGroup")
	outerContainer:PauseLayout() -- Stop drawing (improves performance) until we've added everything
	outerContainer:SetLayout("Fill")
	outerContainer:SetFullWidth(true)
	treeWidget:AddChild(outerContainer)

	local innerContainer = AceGUI:Create("DropdownGroup")
	innerContainer:SetTitle(L.selectEncounter)
	innerContainer:SetLayout("Flow")
	innerContainer:SetCallback("OnGroupSelected", showToggleOptions)
	innerContainer:SetUserData("zone", id)
	innerContainer:SetGroupList(zoneList, zoneSort)

	-- scroll is where we actually put stuff in case things
	-- overflow vertically
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	innerContainer:SetUserData("parent", scroll)
	innerContainer:AddChild(scroll)

	outerContainer:AddChild(innerContainer)

	outerContainer:ResumeLayout()
	outerContainer:PerformLayout() -- Everything added, gogo

	-- Find the first enabled module and select that in the dropdown if possible.
	local index = 1
	for i = 1, #zoneSort do
		local name = zoneSort[i]
		local m = BigWigs:GetBossModule(name)
		if m:IsEnabled() and m.journalId then
			index = i
			break
		end
	end
	innerContainer:SetGroup(zoneSort[index])
	innerContainer:DoLayout() -- One last refresh to adjust height
end

do
	local expansionHeader = {
		"Classic",
		"BurningCrusade",
		"WrathOfTheLichKing",
		"HeroicPlus",
		-- "MistsOfPandaria",
		-- "WarlordsOfDraenor",
		-- "Legion",
		-- "BattleForAzeroth",
		-- "Shadowlands"
	}

	-- Nozdor 3.3.5 compat: pick the default expansion header from the client's
	-- interface number instead of hardcoding it to the latest expansion.
	local function currentExpansion(toc)
		if toc > 90000 then return "Shadowlands"
		elseif toc >= 50000 then return "WarlordsOfDraenor"
		elseif toc >= 40000 then return "Cataclysm"
		elseif toc >= 30000 then return "WrathOfTheLichKing"
		elseif toc >= 20000 then return "BurningCrusade"
		else return "Classic" end
	end

	local defaultHeader = "BigWigs_" .. currentExpansion(toc)

	-- Nozdor 3.3.5 compat: GetAddOnEnableState does not exist (or has a different
	-- signature) on WotLK. Force a permissive check (treated as enabled) so the
	-- expansion branches always render regardless of the built-in's behavior.
	GetAddOnEnableState = function(player, addon) return 1 end

	local statusTable = {}
	local playerName = nil
	local GetBestMapForUnit = loader.GetBestMapForUnit
	local GetMapInfo = loader.GetMapInfo

	local function toggleAnchors()
		if not BigWigs:IsEnabled() then BigWigs:Enable() end
		if options:InConfigureMode() then
			options:SendMessage("BigWigs_StopConfigureMode")
		else
			options:SendMessage("BigWigs_StartConfigureMode")
		end
	end

	local function onControlEnter(widget)
		bwTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		bwTooltip:SetText(widget.text:GetText(), 1, 0.82, 0, true)
		bwTooltip:AddLine(widget:GetUserData("desc"), 1, 1, 1, true)
		bwTooltip:Show()
	end

	local function onControlLeave()
		bwTooltip:Hide()
	end

	local function onTreeGroupSelected(widget, event, value)
		widget:ReleaseChildren()
		local zoneId = value:match("\001(-?%d+)$")
		if zoneId then
			onZoneShow(widget, tonumber(zoneId))
		elseif value:match("^BigWigs_") and value ~= defaultHeader and GetAddOnEnableState(playerName, value) == 0 then
			local missing = AceGUI:Create("Label")
			missing:SetText(L.missingAddOn:format(value))
			missing:SetFontObject(GameFontHighlight)
			missing:SetFullWidth(true)
			widget:AddChild(missing)
		elseif value:match("^LittleWigs_") and GetAddOnEnableState(playerName, "LittleWigs") == 0 then
			local missing = AceGUI:Create("Label")
			missing:SetText(L.missingAddOn:format("LittleWigs"))
			missing:SetFontObject(GameFontHighlight)
			missing:SetFullWidth(true)
			widget:AddChild(missing)
		else
			statusTable.groups[value] = true
			widget:RefreshTree()
		end
	end

	local function onTabGroupSelected(widget, event, value)
		widget:ReleaseChildren()

		if value == "options" then
			-- Embed the AceConfig options in our AceGUI frame
			local container = AceGUI:Create("SimpleGroup")
			container.type = "BigWigsOptions" -- We want ACD to create a ScrollFrame, so we change the type to bypass it's group control check
			container:SetFullHeight(true)
			container:SetFullWidth(true)

			-- Have to use :Open instead of just :FeedGroup because some widget types (range, color) call :Open to refresh on change
			isPluginOpen = container
			acd:Open("BigWigs", container)

			widget:AddChild(container)
		else
			isPluginOpen = nil
			local treeTbl = {}
			local addonNameToHeader = {}
			local defaultHeader
			if value == "bigwigs" then
				defaultHeader = "BigWigs_" .. currentExpansion(toc)
				for i = 1, #expansionHeader do
					local value = "BigWigs_" .. expansionHeader[i]
					treeTbl[i] = {
						text = (expansionHeader[i] == "HeroicPlus" and "Heroic+" or EJ_GetTierInfo(i)),
						value = value,
						enabled = (value == defaultHeader or GetAddOnEnableState(playerName, value) > 0),
					}
					addonNameToHeader[value] = treeTbl[i]
				end
			elseif value == "littlewigs" then
				-- Nozdor: open the dungeons tree on Heroic+ by default.
				defaultHeader = "LittleWigs_HeroicPlus"
				local enabled = GetAddOnEnableState(playerName, "LittleWigs") > 0
				for i = 1, #expansionHeader do
					local value = "LittleWigs_" .. expansionHeader[i]
					treeTbl[i] = {
						text = (expansionHeader[i] == "HeroicPlus" and "Heroic+" or EJ_GetTierInfo(i)),
						value = value,
						enabled = enabled,
					}
					addonNameToHeader[value] = treeTbl[i]
				end
			end

			do
				-- Nozdor 3.3.5 fix: attach zones to their expansion tier by iterating the
				-- loader's authoritative zone table directly (id-first). The upstream
				-- name->id->addon two-pass broke on this client (zone names no longer
				-- round-trip through zoneToId), so raid zones never appeared in the tree.
				for rawId in next, loader:GetZoneMenus() do
					local id = tonumber(rawId)
					if id then
					local zone
					if id < 0 then
						local tbl = GetMapInfo(-id)
						if tbl then
							zone = tbl.name
						else
							zone = tostring(id)
						end
else
					-- Nozdor 3.3.5 fix: GetRealZoneText(id) and the C_Map* functions
					-- ignore the id on this client and return the player's current
					-- zone, so look the WotLK raids AND 5-man dungeons up from a
					-- static table instead. (Classic/TBC ids fall back to
					-- GetRealZoneText and are only shown if it cooperates.)
					zone = loader.zoneNames[id] or GetRealZoneText(id)
				end
					if zone and zone ~= "" then -- Protect live client from beta client ids
						local addon = loader.zoneTbl[id]
						-- Nozdor: addonNameToHeader maps straight to the expansion node now
						local treeParent = addon and addonNameToHeader[addon]
						if treeParent and treeParent.enabled then -- third-party plugins can add empty zones if you don't have the expansion addon enabled
							if not treeParent.children then treeParent.children = {} end -- Create sub menu table
							tinsert(treeParent.children, { -- Add new instance/zone sub menu
								value = id,
								text = zone,
							})
						end
					end
					end
				end

				for i = 1, #treeTbl do -- Sort each expansion's zones alphabetically
					local children = treeTbl[i] and treeTbl[i].children
					if children then
						sort(children, function(a, b) return tostring(a.text) < tostring(b.text) end)
					end
				end

				-- Nozdor 3.3.5: drop expansion headers that have no name (EJ_GetTierInfo
				-- returns nil for uninstalled expansions like Cataclysm+ on this client)
				-- or no zone modules at all. Otherwise the raid tree shows phantom
				-- blank expansion nodes that are just noise.
				local filtered = {}
				for i = 1, #treeTbl do
					local node = treeTbl[i]
					if node.text and node.children and #node.children > 0 then
						filtered[#filtered + 1] = node
					else
						addonNameToHeader[node.value] = nil
					end
				end
				treeTbl = filtered

				end

			local tree = AceGUI:Create("TreeGroup")
			tree:SetFullWidth(true)
			tree:SetFullHeight(true)
			tree:SetStatusTable(statusTable)
			tree:SetTree(treeTbl)
			tree:SetLayout("Fill")
			tree:SetCallback("OnGroupSelected", onTreeGroupSelected)

			-- Do we have content for the zone we're in? Then open straight to that zone.
			local _, instanceType, _, _, _, _, _, id = loader.GetInstanceInfo()
			local parent = loader.zoneTbl[id] and addonNameToHeader[loader.zoneTbl[id]]
			if instanceType == "none" then
				local mapId = GetBestMapForUnit("player")
				if mapId then
					id = loader.zoneTblWorld[-mapId]
					parent = loader.zoneTbl[id] and addonNameToHeader[loader.zoneTbl[id]]
				end
			end

			if parent then
				local moduleList = id and loader:GetZoneMenus()[id]
				local value = parent.value
				tree:SelectByValue(moduleList and ("%s\001%d"):format(value, id) or value)
			else
				-- Guard against a nil value: TreeGroup:SelectByValue crashes on split(nil).
				local selectValue = addonNameToHeader[defaultHeader] and defaultHeader or (treeTbl[1] and treeTbl[1].value)
				if selectValue then
					tree:SelectByValue(selectValue)
				end
			end

			widget:AddChild(tree)
		end
	end

	function options:OpenConfig()
		playerName = UnitName("player")

		local bw = AceGUI:Create("Frame")
		isOpen = bw
		bw:SetTitle("BigWigs")
		bw:SetStatusText(" "..loader:GetReleaseString())
		bw:SetWidth(858)
		bw:SetHeight(660)
		bw:EnableResize(false)
		bw:SetLayout("Flow")
		bw:SetCallback("OnClose", function(widget)
			AceGUI:Release(widget)
			wipe(statusTable)
			isPluginOpen = nil
			isOpen = nil
		end)

		local introduction = AceGUI:Create("Label")
		introduction:SetText(L.introduction)
		introduction:SetFontObject(GameFontHighlight)
		introduction:SetFullWidth(true)
		bw:AddChild(introduction)

		local anchors = AceGUI:Create("Button")
		anchors:SetText(L.toggleAnchorsBtn)
		anchors:SetUserData("desc", L.toggleAnchorsBtn_desc)
		anchors:SetRelativeWidth(0.5)
		anchors:SetCallback("OnClick", toggleAnchors)
		anchors:SetCallback("OnEnter", onControlEnter)
		anchors:SetCallback("OnLeave", onControlLeave)

		local testing = AceGUI:Create("Button")
		testing:SetText(L.testBarsBtn)
		testing:SetUserData("desc", L.testBarsBtn_desc)
		testing:SetRelativeWidth(0.5)
		testing:SetCallback("OnClick", BigWigs.Test)
		testing:SetCallback("OnEnter", onControlEnter)
		testing:SetCallback("OnLeave", onControlLeave)

		bw:AddChildren(anchors, testing)

		local tabs = AceGUI:Create("TabGroup")
		tabs:SetLayout("Flow")
		tabs:SetFullWidth(true)
		tabs:SetFullHeight(true)
		tabs:SetTabs({
			{ text = L.options, value = "options" },
			{ text = L.raidBosses, value = "bigwigs" },
			{ text = L.dungeonBosses, value = "littlewigs" },
		})
		tabs:SetCallback("OnGroupSelected", onTabGroupSelected)
		tabs:SelectTab("options")
		bw:AddChild(tabs)

		bw:Show()

		-- Nozdor 3.3.5: this client does not route ESC to CloseSpecialWindows()
		-- for addon-created frames, so the options window never closed on ESC.
		-- Existing addons (DBM, Details, ElvUI) close their windows by registering
		-- the frame name in UISpecialFrames; do the same here, and also enable
		-- keyboard input so ESC is consumed directly whenever the frame has focus.
		local bf = bw.frame
		if bf and bf.SetPropagateKeyboardInput then
			bf:EnableKeyboard(true)
			bf:SetPropagateKeyboardInput(true)
			bf:SetScript("OnKeyDown", function(self, key)
				if key == "ESCAPE" then
					self:SetPropagateKeyboardInput(false)
					self:Hide() -- fires the Frame widget's OnClose / bw OnClose handler
				else
					self:SetPropagateKeyboardInput(true)
				end
			end)
		end
		if not _G.BigWigsOptionsMainFrame then
			tinsert(UISpecialFrames, "BigWigsOptionsMainFrame")
		end
		_G.BigWigsOptionsMainFrame = bf
	end
end

do
	local registered, subPanelRegistry, pluginRegistry = {}, {}, {}
	function options:Register(_, _, module)
		if registered[module.name] then return end
		registered[module.name] = true
		if module.pluginOptions then
			if type(module.pluginOptions) == "function" then
				pluginRegistry[module.name] = module.pluginOptions
			else
				acOptions.args.general.args[module.name] = module.pluginOptions
			end
		elseif module.subPanelOptions then
			local key = module.subPanelOptions.key
			local opts = module.subPanelOptions.options
			if type(opts) == "function" then
				subPanelRegistry[key] = opts
			else
				acOptions.args[key] = opts
			end
		end
	end

	function getOptions()
		for key, opts in next, pluginRegistry do
			acOptions.args.general.args[key] = opts()
		end
		for key, opts in next, subPanelRegistry do
			acOptions.args[key] = opts()
		end
		return acOptions
	end
end

function options:ConfigTableChange(_, appName)
	if appName == "BigWigs" and isPluginOpen then
		acd:Open("BigWigs", isPluginOpen)
	end
end

BigWigsOptions = options -- Set global
