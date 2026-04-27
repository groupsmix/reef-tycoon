--!strict
--[[
	Reef Tycoon — server bootstrap.

	1. Init services in dependency order (so each service's Init() runs
	   before any Start() runs).
	2. Wire the GetPlayerSnapshot / GetCatalog read endpoints used by the
	   client to mirror state.
	3. Replicate profile diffs to the owning client on every change.
	4. Grant offline earnings + fire OfflineEarnings event on join so the
	   client can show the welcome-back panel.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Util"):WaitForChild("Validate"))
local FishData = require(Shared:WaitForChild("FishData"))
local TankData = require(Shared:WaitForChild("TankData"))
local RarityData = require(Shared:WaitForChild("RarityData"))
local GamepassData = require(Shared:WaitForChild("GamepassData"))
local DevProductData = require(Shared:WaitForChild("DevProductData"))

local Services = script.Parent:WaitForChild("Services")

local DataService = require(Services:WaitForChild("DataService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local WorldService = require(Services:WaitForChild("WorldService"))
local TankService = require(Services:WaitForChild("TankService"))
local TankRenderService = require(Services:WaitForChild("TankRenderService"))
local PlacementService = require(Services:WaitForChild("PlacementService"))
local VisitorService = require(Services:WaitForChild("VisitorService"))
local VisitorRenderService = require(Services:WaitForChild("VisitorRenderService"))
local GachaService = require(Services:WaitForChild("GachaService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))
local PrestigeService = require(Services:WaitForChild("PrestigeService"))
local BadgeService = require(Services:WaitForChild("BadgeService"))
local AnalyticsService = require(Services:WaitForChild("AnalyticsService"))
local AntiCheatService = require(Services:WaitForChild("AntiCheatService"))
local DailyRewardService = require(Services:WaitForChild("DailyRewardService"))
local LeaderboardService = require(Services:WaitForChild("LeaderboardService"))
local SoundService = require(Services:WaitForChild("SoundService"))

local function buildCatalog()
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
		config = {
			eggCostGems = Config.EGG_COST_GEMS,
			mythicEggCostGems = Config.MYTHIC_EGG_COST_GEMS,
			pityEpicAt = Config.PITY_EPIC_PLUS_AT,
			pityMythicAt = Config.PITY_MYTHIC_AT,
			prestigeUnlock = Config.PRESTIGE_UNLOCK_LIFETIME_CASH,
			prestigeBonus = Config.PRESTIGE_BONUS_PER_LEVEL,
		},
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
		tutorialDone = profile.tutorialDone,
		dailyStreak = profile.dailyStreak,
	}
end

local function pushSnapshotImmediate(player: Player)
	local s = snapshot(player)
	if s then
		Remotes.Server().Events.PlayerDataReplicated:FireClient(player, s)
	end
end

-- Debounce snapshot replication to ~3 Hz (333ms). Without this, every
-- visitor tip call (potentially many per second per player) would fire
-- a full PlayerDataReplicated which is the heaviest payload on the
-- wire. Coalescing trailing-edge keeps the perceived latency under
-- 350ms while cutting bandwidth by an order of magnitude in the
-- 12-player full-server case.
local SNAPSHOT_DEBOUNCE_SEC = 0.333
local pendingSnapshot: { [number]: boolean } = {}
local lastSnapshotAt: { [number]: number } = {}

local function pushSnapshot(player: Player)
	local userId = player.UserId
	local now = os.clock()
	local last = lastSnapshotAt[userId] or 0
	if now - last >= SNAPSHOT_DEBOUNCE_SEC then
		lastSnapshotAt[userId] = now
		pushSnapshotImmediate(player)
		return
	end
	if pendingSnapshot[userId] then
		return
	end
	pendingSnapshot[userId] = true
	local wait = SNAPSHOT_DEBOUNCE_SEC - (now - last)
	task.delay(wait, function()
		pendingSnapshot[userId] = nil
		if not player.Parent then
			return
		end
		lastSnapshotAt[userId] = os.clock()
		pushSnapshotImmediate(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	pendingSnapshot[player.UserId] = nil
	lastSnapshotAt[player.UserId] = nil
end)

-- ────────── Init phase ──────────
DataService.Init()
EconomyService.Init()
WorldService.Init()
SoundService.Init()
TankService.Init()
TankRenderService.Init()
PlacementService.Init()
VisitorService.Init()
VisitorRenderService.Init()
GachaService.Init()
MonetizationService.Init()
PrestigeService.Init()
BadgeService.Init()
AnalyticsService.Init()
AntiCheatService.Init()
DailyRewardService.Init()
LeaderboardService.Init()

-- Wire read endpoints
Remotes.Server().Functions.GetCatalog.OnServerInvoke = function(_player)
	return catalog
end
Remotes.Server().Functions.GetPlayerSnapshot.OnServerInvoke = function(player)
	return snapshot(player)
end
Remotes.Server().Functions.GetTopCash.OnServerInvoke = function(_player)
	return LeaderboardService.GetTopCash()
end
Remotes.Server().Functions.MarkTutorialDone.OnServerInvoke = Validate.zeroArgs(function(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	profile.tutorialDone = true
	DataService.MarkChanged(player)
	AnalyticsService.Track(player, "tutorial_done", nil)
	return true
end, AntiCheatService.IsBanned)

-- Replicate diffs to the owning client.
DataService.ProfileChanged:Connect(function(player, _profile)
	pushSnapshot(player)
end)

-- Grant offline earnings + first snapshot when the player joins.
Players.PlayerAdded:Connect(function(player)
	DataService.WaitForProfile(player, 10)
	local granted = VisitorService.GrantOfflineEarnings(player)
	pushSnapshot(player)
	if granted > 0 then
		Remotes.Server().Events.OfflineEarnings:FireClient(player, granted)
	end
	AnalyticsService.Track(player, "session_start", { offlineEarnings = granted })
end)
for _, p in Players:GetPlayers() do
	task.spawn(function()
		DataService.WaitForProfile(p, 10)
		local granted = VisitorService.GrantOfflineEarnings(p)
		pushSnapshot(p)
		if granted > 0 then
			Remotes.Server().Events.OfflineEarnings:FireClient(p, granted)
		end
	end)
end

-- ────────── Start phase ──────────
DataService.Start()
EconomyService.Start()
WorldService.Start()
SoundService.Start()
TankService.Start()
TankRenderService.Start()
PlacementService.Start()
VisitorService.Start()
VisitorRenderService.Start()
GachaService.Start()
MonetizationService.Start()
PrestigeService.Start()
BadgeService.Start()
AnalyticsService.Start()
AntiCheatService.Start()
DailyRewardService.Start()
LeaderboardService.Start()

print(("[ReefTycoon] server ready (v%s)"):format(Config.GAME_VERSION))
