local addonName, addon = ...

local CL = BigWigsAPI:GetLocale("BigWigs: Common")

-- Exports localized spell names for every BigWigs option key.
-- Usage: /bwvoice export  then  /reload
-- Result: WTF/Account/<account>/SavedVariables/BigWigs_Voice_RU.lua
-- BigWigsVoiceRUExport = { [12345] = "Название способности", ... }

local function export(silent)
	local data = {}
	local numeric, strings, modules = 0, 0, 0

	-- Boss modules live in zone/instance addons that are not loaded in town.
	for _, pack in ipairs({ "BigWigs_WrathOfTheLichKing", "BigWigs_Azeroth", "LittleWigs" }) do
		if not IsAddOnLoaded(pack) then
			LoadAddOn(pack)
		end
	end

	for moduleName, module in BigWigs:IterateBossModules() do
		modules = modules + 1
		-- toggleOptions is filled lazily by SetupOptions when a module is
		-- enabled or its options are opened. Most dungeon modules are never
		-- enabled in town, so call GetOptions() directly to export every key.
		local options = module.toggleOptions
		if not options and module.GetOptions then
			options = module:GetOptions(CL)
		end
		if options then
			for _, entry in ipairs(options) do
				local key = type(entry) == "table" and entry[1] or entry
				if type(key) == "number" and key > 0 then
					if not data[key] then
						local name = GetSpellInfo(key)
						if name and name ~= "" then
							data[key] = name
							numeric = numeric + 1
						end
					end
				elseif type(key) == "string" and not data[key] then
					local locale = module.GetLocale and module:GetLocale()
					local name = locale and locale[key]
					if type(name) == "string" and name ~= "" then
						data[key] = name
						strings = strings + 1
					end
				end
			end
		end
	end

	BigWigsVoiceRUExport = data
	if not silent then
		print(format("|cff33ff99BigWigs_Voice_RU|r: exported %d spell names and %d string keys from %d modules. Run /reload to save.", numeric, strings, modules))
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	export(true)
end)

local function testSound(key, extension)
	key = tostring(key or "190206"):gsub("%s+", "")
	extension = extension and extension ~= "" and extension or "ogg"
	local base = format("Interface\\AddOns\\BigWigs_Voice_RU\\Sounds\\%s", key)
	PlaySoundFile(base .. "." .. extension, "Master")
	print(format("|cff33ff99BigWigs_Voice_RU|r: playing %s.%s", base, extension))
end

SLASH_BIGWIGSVOICEEXPORT1 = "/bwvoice"
SlashCmdList["BIGWIGSVOICEEXPORT"] = function(msg)
	msg = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local command, argument = msg:match("^(%S*)%s*(.*)$")
	if command == "" or command == "status" then
		print(format("|cff33ff99BigWigs_Voice_RU|r: loaded=%s, voice pack=%s, sounds=ogg, use /bwvoice test <key>",
			tostring(IsAddOnLoaded("BigWigs_Voice_RU")), tostring(BigWigsAPI:HasVoicePack())))
	elseif command == "export" then
		export(false)
	elseif command == "test" then
		local key, extension = argument:match("^(%S+)%s*(%S*)$")
		testSound(key, extension)
	else
		print("|cff33ff99BigWigs_Voice_RU|r: usage /bwvoice status | /bwvoice export | /bwvoice test <spellId>")
	end
end
