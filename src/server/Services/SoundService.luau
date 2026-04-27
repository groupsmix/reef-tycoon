--!strict
--[[
	SoundService — registers a small set of named Sounds in
	SoundService and exposes `Play` to other server code (mostly for
	server-wide cues like Legendary announcements).

	Asset IDs are loaded from `Config.SOUND_IDS`. If left at 0 the
	sound is created but with no asset — `Play` no-ops cleanly.
]]

local SoundServiceRoblox = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local SoundService = {}

local function ensureSound(name: string, soundId: number, looped: boolean, volume: number)
	local existing = SoundServiceRoblox:FindFirstChild(name)
	if existing and existing:IsA("Sound") then
		return existing
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = if soundId ~= 0 then ("rbxassetid://" .. soundId) else ""
	s.Looped = looped
	s.Volume = volume
	s.Parent = SoundServiceRoblox
	return s
end

function SoundService.Play(name: string)
	local s = SoundServiceRoblox:FindFirstChild(name)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s:Play()
	end
end

function SoundService.Init()
	ensureSound("AmbientOcean", Config.SOUND_IDS.AMBIENT_OCEAN, true, 0.4)
	ensureSound("Bubbles", Config.SOUND_IDS.BUBBLES, true, 0.2)
	ensureSound("MusicChill", Config.SOUND_IDS.MUSIC_CHILL, true, 0.25)
	ensureSound("Tip", Config.SOUND_IDS.TIP, false, 0.4)
	ensureSound("EggPop", Config.SOUND_IDS.EGG_POP, false, 0.5)
	ensureSound("MythicStinger", Config.SOUND_IDS.MYTHIC_STINGER, false, 0.7)
	ensureSound("LegendaryStinger", Config.SOUND_IDS.LEGENDARY_STINGER, false, 0.85)
	-- Auto-start ambient loops on startup.
	SoundService.Play("AmbientOcean")
	SoundService.Play("MusicChill")
end

function SoundService.Start() end

return SoundService
