--!strict
--[[
	DataService — owns the player profile lifecycle.

	- Loads the profile from a primary DataStore key on join.
	- Falls back to the snapshot key on primary failure.
	- Periodic auto-save + hourly snapshot to a separate key.
	- BindToClose flushes within Config.SHUTDOWN_SAVE_TIMEOUT_SECONDS.
	- Schema migrations: each integer schema version maps to a function
	  that mutates an old profile in-place. New versions are added by
	  appending to MIGRATIONS without changing existing entries.

	Profiles are intentionally JSON-shaped (no instances, no functions) so
	they round-trip through DataStores and can be re-shaped by future
	migrations.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Signal"))
local DataMigrations = require(Shared:WaitForChild("DataMigrations"))

export type FishStack = {
	id: string, -- fish species id (matches FishData)
	count: number,
	firstObtained: number, -- unix seconds
}

export type PlacedTank = {
	tankId: string, -- TankData id
	pedestalIndex: number, -- 1..N pedestal slot in the world
	fish: { string }, -- fish ids in this tank
}

export type Profile = {
	schemaVersion: number,
	cash: number,
	gems: number,
	lifetimeCash: number,
	tankSlots: number,
	prestigeLevel: number,
	prestigeMultiplier: number, -- cached: 1 + level * Config.PRESTIGE_BONUS_PER_LEVEL
	gamepasses: { [string]: boolean },
	inventory: { [string]: FishStack }, -- by fish id
	placedTanks: { PlacedTank },
	gacha: {
		totalRolls: number,
		rollsSinceEpicPlus: number,
		rollsSinceMythic: number,
		legendaryCount: number,
		mythicCount: number,
	},
	tutorialDone: boolean,
	dailyStreak: number,
	lastDailyClaimAt: number,
	lastSeenAt: number, -- unix seconds, used for offline earnings
	totalPlaytimeSec: number,
	createdAt: number,
}

local DataService = {}
DataService.ProfileChanged = Signal.new()

local primaryStore = DataStoreService:GetDataStore(Config.DATASTORE_KEY_PRIMARY)
local snapshotStore = DataStoreService:GetDataStore(Config.DATASTORE_KEY_SNAPSHOT)

local profiles: { [number]: Profile } = {}
local lastSnapshotAt: { [number]: number } = {}
local saving: { [number]: boolean } = {}

local function newProfile(): Profile
	return {
		schemaVersion = Config.SCHEMA_VERSION,
		cash = Config.STARTING_CASH,
		gems = Config.STARTING_GEMS,
		lifetimeCash = 0,
		tankSlots = Config.STARTING_TANK_SLOTS,
		prestigeLevel = 0,
		prestigeMultiplier = 1.0,
		gamepasses = {},
		inventory = {},
		placedTanks = {},
		gacha = {
			totalRolls = 0,
			rollsSinceEpicPlus = 0,
			rollsSinceMythic = 0,
			legendaryCount = 0,
			mythicCount = 0,
		},
		tutorialDone = false,
		dailyStreak = 0,
		lastDailyClaimAt = 0,
		lastSeenAt = os.time(),
		totalPlaytimeSec = 0,
		createdAt = os.time(),
	}
end

local function migrate(profile: any): Profile
	return DataMigrations.run(profile, Config.SCHEMA_VERSION, Config.PRESTIGE_BONUS_PER_LEVEL) :: Profile
end

local function key(userId: number): string
	return "u_" .. userId
end

local function load(userId: number): Profile
	if RunService:IsStudio() then
		local ok, result = pcall(function()
			return primaryStore:GetAsync(key(userId))
		end)
		if ok and result then
			return migrate(result)
		end
		return newProfile()
	end

	local ok, result = pcall(function()
		return primaryStore:GetAsync(key(userId))
	end)
	if ok and result then
		return migrate(result)
	end
	if not ok then
		warn(("[DataService] primary load failed for %d: %s"):format(userId, tostring(result)))
		local snapOk, snapResult = pcall(function()
			return snapshotStore:GetAsync(key(userId))
		end)
		if snapOk and snapResult then
			warn(("[DataService] recovered %d from snapshot"):format(userId))
			return migrate(snapResult)
		end
	end
	return newProfile()
end

local function save(userId: number, profile: Profile, isSnapshot: boolean?): boolean
	if saving[userId] and not isSnapshot then
		return false
	end
	saving[userId] = true
	local store = isSnapshot and snapshotStore or primaryStore
	local ok, err = pcall(function()
		store:UpdateAsync(key(userId), function(_old)
			return profile
		end)
	end)
	saving[userId] = false
	if not ok then
		warn(("[DataService] save failed for %d (snapshot=%s): %s"):format(userId, tostring(isSnapshot), tostring(err)))
	end
	return ok
end

function DataService.GetProfile(player: Player): Profile?
	return profiles[player.UserId]
end

function DataService.WaitForProfile(player: Player, timeoutSec: number?): Profile?
	local deadline = os.clock() + (timeoutSec or 10)
	while not profiles[player.UserId] and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player.UserId]
end

function DataService.MarkChanged(player: Player)
	local profile = profiles[player.UserId]
	if profile then
		DataService.ProfileChanged:Fire(player, profile)
	end
end

function DataService._onPlayerAdded(player: Player)
	local profile = load(player.UserId)
	profile.lastSeenAt = os.time()
	profiles[player.UserId] = profile
	lastSnapshotAt[player.UserId] = os.clock()
	DataService.ProfileChanged:Fire(player, profile)
end

function DataService._onPlayerRemoving(player: Player)
	local profile = profiles[player.UserId]
	if profile then
		profile.lastSeenAt = os.time()
		save(player.UserId, profile)
		profiles[player.UserId] = nil
		lastSnapshotAt[player.UserId] = nil
	end
end

function DataService._tick()
	local now = os.clock()
	for userId, profile in profiles do
		profile.lastSeenAt = os.time()
		save(userId, profile)
		local last = lastSnapshotAt[userId] or 0
		if now - last >= Config.SNAPSHOT_INTERVAL_SECONDS then
			save(userId, profile, true)
			lastSnapshotAt[userId] = now
		end
	end
end

function DataService.Init()
	Players.PlayerAdded:Connect(DataService._onPlayerAdded)
	Players.PlayerRemoving:Connect(DataService._onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(DataService._onPlayerAdded, p)
	end
end

function DataService.Start()
	task.spawn(function()
		while true do
			task.wait(Config.SAVE_INTERVAL_SECONDS)
			DataService._tick()
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		local deadline = os.clock() + Config.SHUTDOWN_SAVE_TIMEOUT_SECONDS
		for userId, profile in profiles do
			if os.clock() >= deadline then
				break
			end
			profile.lastSeenAt = os.time()
			task.spawn(save, userId, profile)
		end
		while os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
