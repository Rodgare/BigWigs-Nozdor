local name, addon = ...

--------------------------------------------------------------------------------
-- Locals
--

local format = format

--------------------------------------------------------------------------------
-- Event Handlers
--

local path = "Interface\\AddOns\\BigWigs_Voice_RU\\Sounds\\%s"

local function play(base)
	PlaySoundFile(base .. ".ogg", "Master")
end

local function handler(event, module, key, sound, isOnMe)
	-- The pack has no per-player "y" variants yet; use the base clip for both
	-- personal and group announcements instead of staying silent on "on you".
	local base = format(path, tostring(key))
	play(base)
end

BigWigsLoader.RegisterMessage(addon, "BigWigs_Voice", handler)
BigWigsAPI.RegisterVoicePack("temp")
