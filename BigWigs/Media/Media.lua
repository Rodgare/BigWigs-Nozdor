
local L = BigWigsAPI:GetLocale("BigWigs")
local media = LibStub("BW-LibSharedMedia-3.0")

-- Bar Textures
do
	local STATUSBAR = media.MediaType and media.MediaType.STATUSBAR or "statusbar"
	media:Register(STATUSBAR, "Otravi", "Interface\\AddOns\\BigWigs\\Media\\Textures\\Otravi")
	media:Register(STATUSBAR, "Smooth", "Interface\\AddOns\\BigWigs\\Media\\Textures\\Smooth")
	media:Register(STATUSBAR, "Smooth v2", "Interface\\AddOns\\BigWigs\\Media\\Textures\\Smoothv2")
	media:Register(STATUSBAR, "Glaze", "Interface\\AddOns\\BigWigs\\Media\\Textures\\Glaze")
	media:Register(STATUSBAR, "Charcoal", "Interface\\AddOns\\BigWigs\\Media\\Textures\\Charcoal")
	media:Register(STATUSBAR, "BantoBar", "Interface\\AddOns\\BigWigs\\Media\\Textures\\BantoBar")
end

-- Sounds
do
	-- Ours
	local SOUND = media.MediaType and media.MediaType.SOUND or "sound"
	media:Register(SOUND, "BigWigs: Long", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Long.ogg")
	media:Register(SOUND, "BigWigs: Info", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Info.ogg")
	media:Register(SOUND, "BigWigs: Alert", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Alert.ogg")
	media:Register(SOUND, "BigWigs: Alarm", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Alarm.ogg")

	-- Ingame sounds that DBM uses for DBM converts
	media:Register(SOUND, "BigWigs: [DBM] ".. L.FlagTaken, C_RaidLocks and 569200 or "Sound\\Spells\\PVPFlagTaken.ogg")
	media:Register(SOUND, "BigWigs: [DBM] ".. L.Beware, C_RaidLocks and 543587 or "Sound\\Creature\\AlgalonTheObserver\\UR_Algalon_BHole01.ogg")
	media:Register(SOUND, "BigWigs: [DBM] ".. L.Destruction, C_RaidLocks and 553193 or "Sound\\Creature\\KilJaeden\\KILJAEDEN02.ogg")
	media:Register(SOUND, "BigWigs: [DBM] ".. L.RunAway, C_RaidLocks and 552035 or "Sound\\Creature\\HoodWolf\\HoodWolfTransformPlayer01.ogg")

	-- Ingame sounds used by Blizzard
	media:Register(SOUND, "BigWigs: Raid Warning", C_RaidLocks and 567397 or "Sound\\Interface\\RaidWarning.ogg")
	media:Register(SOUND, "BigWigs: Raid Boss Whisper", C_RaidLocks and 876098 or "Sound\\Interface\\UI_RaidBossWhisperWarning.ogg")

	-- Victory
	media:Register(SOUND, "BigWigs: Victory", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Victory.ogg")
	media:Register(SOUND, "BigWigs: Victory Long", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\VictoryLong.ogg")
	media:Register(SOUND, "BigWigs: Victory Classic", "Interface\\AddOns\\BigWigs\\Media\\Sounds\\VictoryClassic.ogg")

	if GetAddOnInfo and GetAddOnInfo("DBM-Core") then
		local path = "Interface\\AddOns\\DBM-Core\\sounds\\"
		local function dbm(name, file)
			media:Register(SOUND, "DBM: " .. name, path .. file)
		end

		dbm("Long", "Long.mp3")
		dbm("Alert", "Alert.mp3")
		dbm("Info", "Info.mp3")
		dbm("Air Horn", "AirHorn.ogg")
		dbm("Alarm", "Alarm.ogg")
		dbm("Alarm Clock Beeps", "alarmclockbeeps.ogg")
		dbm("Beware", "beware.ogg")
		dbm("Blip", "blip_8.ogg")
		dbm("Tick", "Tick.mp3")
		dbm("3 to 1 Countdown", "3to1.mp3")
		dbm("5 to 1 Countdown", "5to1.mp3")
		dbm("Thrall Phase 2", "phase2Trall.ogg")

		dbm("Jaina: Beware", "SoundClips\\beware.ogg")
		dbm("Jaina: Beware (reverb)", "SoundClips\\beware_with_reverb.ogg")
		dbm("Thrall: Incredible", "SoundClips\\incredible.ogg")
		dbm("Saurfang: Don't Die", "SoundClips\\dontdie.ogg")

		dbm("Blakbyrd Alert 1", "BlakbyrdAlerts\\Alert1.ogg")
		dbm("Blakbyrd Alert 2", "BlakbyrdAlerts\\Alert2.ogg")
		dbm("Blakbyrd Alert 3", "BlakbyrdAlerts\\Alert3.ogg")

		dbm("Shadowmeld", "PlayerAbilities\\Shadowmeld.ogg")
		dbm("Vanish", "PlayerAbilities\\Vanish.ogg")

		dbm("Raid: Bone Spike Cast", "RaidAbilities\\Bone_Spike_cast.mp3")
		dbm("Raid: Bone Storm Cast", "RaidAbilities\\Bone_Storm_cast.mp3")
		dbm("Raid: Choking", "RaidAbilities\\choking.mp3")
		dbm("Raid: Choking Soon", "RaidAbilities\\choking_soon.mp3")
		dbm("Raid: Defile on You", "RaidAbilities\\defileOnYou.mp3")
		dbm("Raid: Empowered Orb on You", "RaidAbilities\\EmpoweredOrbOnYou.mp3")
		dbm("Raid: Empowered Vortex", "RaidAbilities\\EmpoweredVortex.mp3")
		dbm("Raid: Infest Soon", "RaidAbilities\\infestSoon.mp3")
		dbm("Raid: Kinetic Spawn", "RaidAbilities\\KineticSpawn.mp3")
		dbm("Raid: Malleable", "RaidAbilities\\malleable.mp3")
		dbm("Raid: Malleable Soon", "RaidAbilities\\malleable_soon.mp3")
		dbm("Raid: Necrotic on You", "RaidAbilities\\necroticOnYou.mp3")
		dbm("Raid: Puddle Cast", "RaidAbilities\\puddle_cast.mp3")
		dbm("Raid: Soul Reaper Soon", "RaidAbilities\\soulreaperSoon.mp3")
		dbm("Raid: Spirits", "RaidAbilities\\spirits.mp3")
		dbm("Raid: Suppressors Spawned", "RaidAbilities\\suppressersSpawned.mp3")
		dbm("Raid: Unchained", "RaidAbilities\\unchained.mp3")
		dbm("Raid: Vortex Near", "RaidAbilities\\vortexNear.mp3")

		dbm("Timer Tick", "Timer\\TempMono.ogg")
		dbm("BG Countdown Timer", "Timer\\UI_BattlegroundCountdown_Timer.ogg")
		dbm("BG Countdown End", "Timer\\UI_BattlegroundCountdown_End.ogg")

		dbm("Victory: Alarak", "Victory\\AlarakRakshir.ogg")
		dbm("Victory: Battleground", "Victory\\bbvictory.ogg")
		dbm("Victory: Fanfare", "Victory\\SmoothMcGroove_Fanfare.ogg")
		dbm("Victory: Vorazun GG", "Victory\\VorazunGG.ogg")
		dbm("Victory: Vorazun History", "Victory\\VorazunHistory.ogg")
	end
end

-- Fonts
do
	local FONT = media.MediaType and media.MediaType.FONT or "font"
	-- Nozdor 3.3.5: loading the large full-Unicode Noto TTFs makes the
	-- client's text renderer flaky — random fontstrings (in BigWigs and
	-- ElvUI menus alike) stop rendering until /reload clears the font cache.
	-- Point the Noto keys at the stock client font so Noto is never fetched.
	local stockFont = STANDARD_FONT or "Fonts\\FRIZQT__.TTF"
	media:Register(FONT, "Noto Sans Regular", stockFont, 130) -- 130 latin + cyr
	media:Register(FONT, "Noto Sans SemiCondensed", stockFont, 130) -- 130 latin + cyr
end
