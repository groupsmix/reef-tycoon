--!strict
--[[
	VisitorService — drives idle income.

	We do NOT spawn a visitor NPC per fish; that's wasteful. Instead we
	model "active visitors" as a number per player and award accumulated
	tips on a tick. The lobby can render a *visual sample* of NPCs
	wandering — those are decorative and live in the client.

	Tips formula per player per tick:
		sum over placed tanks of:
			min(visitorCapacity, fishCount) * tankMultiplier
			    * sum(fishRarityMultiplier for fish in tank)
			    * baseTipsPerSec * tickSeconds
		* prestigeMultiplier
		* gamepassMultipliers (DOUBLE_TIPS, etc.)
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TankData = require(Shared:WaitForChild("TankData"))
local FishData = require(Shared:WaitForChild("FishData"))
local RarityData = require(Shared:WaitForChild("RarityData"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local VisitorService = {}

local function gamepassMultiplier(profile): number
	local m = 1
	if profile.gamepasses.DOUBLE_TIPS then
		m *= 2
	end
	return m
end

local function tickPlayer(player: Player, tickSeconds: number)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local total = 0
	for _, placed in profile.placedTanks do
		local tank = TankData.Tanks[placed.tankId]
		if not tank then
			continue
		end
		local fishCount = #placed.fish
		if fishCount == 0 then
			continue
		end
		local activeFish = math.min(tank.visitorCapacity, fishCount)
		local raritySum = 0
		-- Walk active fish in the order they were placed.
		for i = 1, activeFish do
			local fishId = placed.fish[i]
			local fishMeta = FishData.getById(fishId)
			if fishMeta then
				local rarity = RarityData.Rarities[fishMeta.rarity]
				if rarity then
					raritySum += rarity.tipMultiplier
				end
			end
		end
		total += raritySum * tank.tipMultiplier * Config.BASE_TIP_PER_SECOND * tickSeconds
	end
	if total <= 0 then
		return
	end
	total *= profile.prestigeMultiplier
	total *= gamepassMultiplier(profile)
	EconomyService.GrantCash(player, total, "visitor_tip")
end

local function calcOfflineEarnings(profile): number
	local now = os.time()
	local elapsed = math.max(0, now - (profile.lastSeenAt or now))
	local capped = math.min(elapsed, Config.MAX_OFFLINE_HOURS * 3600)
	-- One pseudo-tick of duration `capped`. We reuse the same accounting
	-- by passing capped as tickSeconds.
	if capped <= 0 or #profile.placedTanks == 0 then
		return 0
	end
	local total = 0
	for _, placed in profile.placedTanks do
		local tank = TankData.Tanks[placed.tankId]
		if not tank then
			continue
		end
		local activeFish = math.min(tank.visitorCapacity, #placed.fish)
		if activeFish == 0 then
			continue
		end
		local raritySum = 0
		for i = 1, activeFish do
			local fishId = placed.fish[i]
			local fishMeta = FishData.getById(fishId)
			if fishMeta then
				local rarity = RarityData.Rarities[fishMeta.rarity]
				if rarity then
					raritySum += rarity.tipMultiplier
				end
			end
		end
		total += raritySum * tank.tipMultiplier * Config.BASE_TIP_PER_SECOND * capped
	end
	total *= profile.prestigeMultiplier
	total *= gamepassMultiplier(profile)
	-- Offline earns at a reduced rate so live play still feels best.
	return math.floor(total * Config.OFFLINE_RATE_FACTOR)
end

function VisitorService.GrantOfflineEarnings(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return 0
	end
	local amount = calcOfflineEarnings(profile)
	if amount > 0 then
		EconomyService.GrantCash(player, amount, "offline_earnings")
	end
	return amount
end

function VisitorService.Init() end

function VisitorService.Start()
	task.spawn(function()
		while true do
			task.wait(Config.VISITOR_TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				tickPlayer(player, Config.VISITOR_TICK_SECONDS)
			end
		end
	end)
end

return VisitorService
