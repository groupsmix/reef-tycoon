--!strict
--[[
	AntiCheatService — flag accounts that gain cash faster than physically
	possible.

	The maximum theoretical tip rate per second is bounded by:

		max_total_tip_rate
		    = N_tanks(50) * tank.tipMultiplier(10)
		      * tank.slotCapacity(20) * legendary.tipMultiplier(~88)
		      * gamepass(2x) * prestige(11x at level 100)
		      * BASE_TIP_PER_SECOND(0.5)

	~ 484,000 tips/sec at the absolute maximum (full Reef Gods, all
	Legendaries, max prestige, 2× tips). We add 5× headroom and treat
	2.4M+/sec as definitely an exploit.

	We don't ban automatically — we kick + log to the audit store so a
	human can review.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local AntiCheatService = {}

local THEORETICAL_MAX_PER_SEC = 500_000
local HEADROOM = 5
local KICK_THRESHOLD = THEORETICAL_MAX_PER_SEC * HEADROOM

local windowSize = 5
local cashHistory: { [number]: { cash: number, t: number } } = {}
local bannedSet: { [number]: boolean } = {}

local store = DataStoreService:GetDataStore(Config.DATASTORE_AUDIT_KEY)
local banStore = DataStoreService:GetDataStore("ReefTycoon_Bans_v1")

function AntiCheatService.IsBanned(userId: number): boolean
	return bannedSet[userId] == true
end

-- Test-only seam: returns true if the given cash-per-second rate would
-- trigger a kick. Pure function over the configured threshold.
function AntiCheatService._exceedsThreshold(rate: number): boolean
	return rate > KICK_THRESHOLD
end

function AntiCheatService._kickThreshold(): number
	return KICK_THRESHOLD
end

local function loadBan(userId: number)
	if RunService:IsStudio() then
		return
	end
	task.spawn(function()
		local ok, value = pcall(function()
			return banStore:GetAsync("ban_" .. userId)
		end)
		if ok and value then
			bannedSet[userId] = true
			local player = Players:GetPlayerByUserId(userId)
			if player then
				player:Kick("Account suspended.")
			end
		end
	end)
end

local function recordAndCheck(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local now = os.clock()
	local prev = cashHistory[player.UserId]
	cashHistory[player.UserId] = { cash = profile.cash, t = now }
	if not prev then
		return
	end
	local dt = now - prev.t
	if dt <= 0 then
		return
	end
	local delta = profile.cash - prev.cash
	if delta <= 0 then
		return
	end
	local rate = delta / dt
	if rate > KICK_THRESHOLD then
		warn(
			("[AntiCheat] %s gained %d cash in %.2fs (%.0f/sec, threshold %d)"):format(
				player.Name,
				delta,
				dt,
				rate,
				KICK_THRESHOLD
			)
		)
		if not RunService:IsStudio() then
			task.spawn(function()
				pcall(function()
					store:SetAsync(("ac_%d_%d"):format(player.UserId, os.time()), {
						t = os.time(),
						a = "cash_velocity_kick",
						userId = player.UserId,
						delta = delta,
						dt = dt,
						rate = rate,
					})
				end)
			end)
			player:Kick("Suspicious account activity. If this is a mistake, please contact support.")
		end
	end
end

function AntiCheatService.Init()
	EconomyService.CashChanged:Connect(function(player: Player, _new, _delta, _reason)
		recordAndCheck(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		loadBan(player.UserId)
	end)
	for _, p in Players:GetPlayers() do
		loadBan(p.UserId)
	end
	Players.PlayerRemoving:Connect(function(player)
		cashHistory[player.UserId] = nil
		bannedSet[player.UserId] = nil
	end)

	-- Periodic sweep for slow-cooked exploits that don't trip per-event.
	task.spawn(function()
		while true do
			task.wait(windowSize)
			for _, p in Players:GetPlayers() do
				recordAndCheck(p)
			end
		end
	end)
end

function AntiCheatService.Start() end

return AntiCheatService
