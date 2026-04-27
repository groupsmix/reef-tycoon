--!strict
--[[
	PrestigeService — Rebuild Reef.

	Wipes cash + non-Mythic+ fish + placed tanks. Grants +bonus_per_level%
	tip multiplier. Capped at PRESTIGE_MAX_LEVEL.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FishData = require(Shared:WaitForChild("FishData"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Util"):WaitForChild("Validate"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local AntiCheatService = require(script.Parent:WaitForChild("AntiCheatService"))

local PrestigeService = {}

local auditStore = DataStoreService:GetDataStore(Config.DATASTORE_AUDIT_KEY)

local KEEP_RARITIES = {
	Mythic = true,
	Legendary = true,
}

local function eligible(profile): boolean
	if profile.prestigeLevel >= Config.PRESTIGE_MAX_LEVEL then
		return false
	end
	return profile.lifetimeCash >= Config.PRESTIGE_UNLOCK_LIFETIME_CASH
end

function PrestigeService.Prestige(player: Player): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	if not eligible(profile) then
		return false
	end

	-- Wipe cash + tanks. Keep Mythic+ fish.
	profile.cash = Config.STARTING_CASH
	profile.placedTanks = {}
	for fishId, _ in profile.inventory do
		local meta = FishData.getById(fishId)
		if not meta or not KEEP_RARITIES[meta.rarity] then
			profile.inventory[fishId] = nil
		end
	end

	profile.prestigeLevel += 1
	profile.prestigeMultiplier = 1 + profile.prestigeLevel * Config.PRESTIGE_BONUS_PER_LEVEL

	DataService.MarkChanged(player)

	if not RunService:IsStudio() then
		task.spawn(function()
			pcall(function()
				auditStore:SetAsync(("u_%d_p_%d"):format(player.UserId, os.time()), {
					t = os.time(),
					a = "prestige",
					level = profile.prestigeLevel,
				})
			end)
		end)
	end

	pcall(function()
		Remotes.Server().Events.PrestigeAnnounce:FireAllClients({
			userId = player.UserId,
			name = player.Name,
			level = profile.prestigeLevel,
		})
	end)

	return true
end

function PrestigeService.Init()
	local r = Remotes.Server()
	r.Functions.Prestige.OnServerInvoke = Validate.zeroArgs(function(player)
		return PrestigeService.Prestige(player)
	end, AntiCheatService.IsBanned)
end

function PrestigeService.Start() end

return PrestigeService
