local name, addon = ...

--------------------------------------------------------------------------------
-- Locals
--

local tostring = tostring
local format = format
addon.SendMessage = BigWigsLoader.SendMessage

--------------------------------------------------------------------------------
-- Event Handlers
--

local path = "Interface\\AddOns\\BigWigs_Voice_RU\\Sounds\\%s"

local function play(base)
	return PlaySoundFile(base .. ".ogg", "Master")
		or PlaySoundFile(base .. ".mp3", "Master")
		or PlaySoundFile(base .. ".wav", "Master")
end

local function handler(event, module, key, sound, isOnMe)
	local base = format(path, tostring(key)) .. (isOnMe and "y" or "")
	if not play(base) then
		addon:SendMessage("BigWigs_Sound", module, key, sound)
	end
end

BigWigsLoader.RegisterMessage(addon, "BigWigs_Voice", handler)
BigWigsAPI.RegisterVoicePack("temp")
