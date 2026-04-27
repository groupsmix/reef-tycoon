--!strict
--[[
	Reef Tycoon — server bootstrap.

	1. Init services in dependency order (so each service's Init() runs
	   before any Start() runs).
	2. Wire up the GetPlayerSnapshot / GetCatalog read endpoints used by
	   the client to mirror state.
	3. Replicate profile diffs to the owning client on every change.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local FishData = require(Shared:WaitForChild("FishData"))
local TankData = require(Shared:WaitForChild("TankData"))
local RarityData = require(Shared:WaitForChild("RarityData"))
local GamepassData = require(Shared:WaitForChild("GamepassData"))
local DevProductData = require(Shared:WaitForChild("DevProductData"))

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local TankService = require(Services:WaitForChild("TankService"))
local VisitorService = require(Services:WaitForChild("VisitorService"))
local GachaService = require(Services:WaitForChild("GachaService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))
local PrestigeService = require(Services:WaitForChild("PrestigeService"))

local function buildCatalog()
	-- Strip mesh ids = 0 isn't an issue; we send full data.
	local rarities = {}
	for id, r in RarityData.Rarities do
		rarities[id] = {
			id = r.id,
			name = r.name,
			tierIndex = r.tierIndex,
			weight = r.weight,
			tipMultiplier = r.tipMultiplier,
			color = { r.color.R, r.color.G, r.color.B },
			pullEffect = r.pullEffect,
		}
	end
	local fish = {}
	for id, f in FishData.Fish do
		fish[id] = {
			id = f.id,
			name = f.name,
			rarity = f.rarity,
			meshAssetId = f.meshAssetId,
			primaryColor = { f.primaryColor.R, f.primaryColor.G, f.primaryColor.B },
			description = f.description,
		}
	end
	local tanks = {}
	for id, t in TankData.Tanks do
		tanks[id] = {
			id = t.id,
			name = t.name,
			tierIndex = t.tierIndex,
			cost = t.cost,
			visitorCapacity = t.visitorCapacity,
			tipMultiplier = t.tipMultiplier,
			slotCapacity = t.slotCapacity,
		}
	end
	local gamepasses = {}
	for id, g in GamepassData.Passes do
		gamepasses[id] = {
			id = g.id,
			name = g.name,
			priceRobux = g.priceRobux,
			description = g.description,
			productId = g.productId(),
		}
	end
	local devProducts = {}
	for id, dp in DevProductData.Products do
		devProducts[id] = {
			id = dp.id,
			name = dp.name,
			priceRobux = dp.priceRobux,
			productId = dp.productId(),
		}
	end
	return {
		rarities = rarities,
		fish = fish,
		tanks = tanks,
		gamepasses = gamepasses,
		devProducts = devProducts,
		fishOrder = (function()
			local list = {}
			for id, _ in FishData.Fish do
				table.insert(list, id)
			end
			table.sort(list)
			return list
		end)(),
		tankOrder = TankData.Order,
		rarityOrder = RarityData.Order,
		gamepassOrder = GamepassData.Order,
		devProductOrder = DevProductData.Order,
	}
end

local catalog = buildCatalog()

local function snapshot(player: Player)
	local profile = DataService.WaitForProfile(player, 5)
	if not profile then
		return nil
	end
	return {
		cash = profile.cash,
		gems = profile.gems,
		lifetimeCash = profile.lifetimeCash,
		tankSlots = profile.tankSlots,
		prestigeLevel = profile.prestigeLevel,
		prestigeMultiplier = profile.prestigeMultiplier,
		gamepasses = profile.gamepasses,
		inventory = profile.inventory,
		placedTanks = profile.placedTanks,
		gacha = profile.gacha,
	}
end

local function pushSnapshot(player: Player)
	local s = snapshot(player)
	if s then
		Remotes.Server().Events.PlayerDataReplicated:FireClient(player, s)
	end
end

-- ────────── Init phase ──────────
DataService.Init()
EconomyService.Init()
TankService.Init()
VisitorService.Init()
GachaService.Init()
MonetizationService.Init()
PrestigeService.Init()

-- Wire read endpoints
Remotes.Server().Functions.GetCatalog.OnServerInvoke = function(_player)
	return catalog
end
Remotes.Server().Functions.GetPlayerSnapshot.OnServerInvoke = function(player)
	return snapshot(player)
end

-- Replicate diffs to the owning client.
DataService.ProfileChanged:Connect(function(player, _profile)
	pushSnapshot(player)
end)

-- Grant offline earnings + first snapshot when the player joins.
Players.PlayerAdded:Connect(function(player)
	DataService.WaitForProfile(player, 10)
	VisitorService.GrantOfflineEarnings(player)
	pushSnapshot(player)
end)
for _, p in Players:GetPlayers() do
	task.spawn(function()
		DataService.WaitForProfile(p, 10)
		VisitorService.GrantOfflineEarnings(p)
		pushSnapshot(p)
	end)
end

-- ────────── Start phase ──────────
DataService.Start()
EconomyService.Start()
TankService.Start()
VisitorService.Start()
GachaService.Start()
MonetizationService.Start()
PrestigeService.Start()

print(("[ReefTycoon] server ready (v%s)"):format(require(Shared:WaitForChild("Config")).GAME_VERSION))
