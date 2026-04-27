--!strict
--[[
	GachaService — egg pulls and pity timers.

	An egg costs `Config.EGG_COST_GEMS`. A "Mythic Egg" guarantees Mythic+
	and is sold as a dev product (consumed via MonetizationService) or
	bought directly with `Config.MYTHIC_EGG_COST_GEMS` gems.

	Output (returned to caller and streamed via GachaPullResult event):
		{ fishId = "...", rarity = "Rare", isPity = false }
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FishData = require(Shared:WaitForChild("FishData"))
local RarityData = require(Shared:WaitForChild("RarityData"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local RateLimiter = require(Shared:WaitForChild("Util"):WaitForChild("RateLimiter"))
local WeightedRandom = require(Shared:WaitForChild("Util"):WaitForChild("WeightedRandom"))
local Validate = require(Shared:WaitForChild("Util"):WaitForChild("Validate"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local AntiCheatService = require(script.Parent:WaitForChild("AntiCheatService"))

local GachaService = {}

local rng = Random.new()
local auditStore = DataStoreService:GetDataStore(Config.DATASTORE_AUDIT_KEY)

local limiter = RateLimiter.new({
	burst = Config.EGG_BURST_LIMIT,
	sustained = Config.EGG_SUSTAINED_LIMIT,
	window = 60,
})

local RARITY_INDEX = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Mythic = 5,
	Legendary = 6,
}

local function rarityWeights(luckMultiplier: number)
	local weights = {}
	for id, r in RarityData.Rarities do
		local w = r.weight
		-- Apply luck only above Common.
		if id ~= "Common" then
			w *= luckMultiplier
		end
		weights[id] = w
	end
	return weights
end

local function rollRarity(luckMultiplier: number, forceMinTier: string?): string
	local weights = rarityWeights(luckMultiplier)
	if forceMinTier then
		local minIdx = RARITY_INDEX[forceMinTier]
		for id, _ in weights do
			if RARITY_INDEX[id] < minIdx then
				weights[id] = 0
			end
		end
	end
	local pick = WeightedRandom.pick(weights, rng)
	return pick or "Common"
end

local function pickFishOfRarity(rarity: string): string
	local pool = FishData.ByRarity[rarity]
	if not pool or #pool == 0 then
		return "REEF_TETRA"
	end
	return pool[rng:NextInteger(1, #pool)]
end

local function audit(userId: number, payload)
	if RunService:IsStudio() then
		return
	end
	task.spawn(function()
		local key = ("u_%d_%d"):format(userId, os.time())
		pcall(function()
			auditStore:SetAsync(key, payload)
		end)
	end)
end

function GachaService.RollEgg(
	player: Player,
	options: { force: string?, free: boolean? }?
): { fishId: string, rarity: string, isPity: boolean }?
	options = options or {}
	if not limiter:TryConsume(player.UserId) then
		return nil
	end
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil
	end

	local force = (options :: any).force
	local free = (options :: any).free

	if not free then
		if not EconomyService.SpendGems(player, Config.EGG_COST_GEMS, "egg_open") then
			return nil
		end
	end

	local luck = profile.gamepasses.TRIPLE_LUCK and 3 or 1

	local rolledRarity: string
	local isPity = false

	if force then
		rolledRarity = rollRarity(luck, force)
	else
		profile.gacha.totalRolls += 1
		profile.gacha.rollsSinceEpicPlus += 1
		profile.gacha.rollsSinceMythic += 1

		if profile.gacha.rollsSinceMythic >= Config.PITY_MYTHIC_AT then
			rolledRarity = "Mythic"
			isPity = true
		elseif profile.gacha.rollsSinceEpicPlus >= Config.PITY_EPIC_PLUS_AT then
			rolledRarity = rollRarity(luck, "Epic")
			isPity = true
		else
			rolledRarity = rollRarity(luck)
		end
	end

	-- Pity bookkeeping
	if RARITY_INDEX[rolledRarity] >= RARITY_INDEX.Epic then
		profile.gacha.rollsSinceEpicPlus = 0
	end
	if RARITY_INDEX[rolledRarity] >= RARITY_INDEX.Mythic then
		profile.gacha.rollsSinceMythic = 0
		profile.gacha.mythicCount = (profile.gacha.mythicCount or 0) + 1
	end
	if rolledRarity == "Legendary" then
		profile.gacha.legendaryCount = (profile.gacha.legendaryCount or 0) + 1
	end

	local fishId = pickFishOfRarity(rolledRarity)
	local stack = profile.inventory[fishId]
	if stack then
		stack.count += 1
	else
		profile.inventory[fishId] = {
			id = fishId,
			count = 1,
			firstObtained = os.time(),
		}
	end

	DataService.MarkChanged(player)

	-- Audit Mythic+ pulls for dupe-investigation.
	if RARITY_INDEX[rolledRarity] >= RARITY_INDEX.Mythic then
		audit(player.UserId, {
			t = os.time(),
			a = "gacha_pull",
			fishId = fishId,
			rarity = rolledRarity,
			pity = isPity,
			rolls = profile.gacha.totalRolls,
		})
	end

	local result = { fishId = fishId, rarity = rolledRarity, isPity = isPity }
	pcall(function()
		Remotes.Server().Events.GachaPullResult:FireClient(player, result)
		if rolledRarity == "Legendary" then
			Remotes.Server().Events.LegendaryAnnounce:FireAllClients({
				userId = player.UserId,
				name = player.Name,
				fishId = fishId,
			})
		end
	end)
	return result
end

function GachaService.Init()
	local r = Remotes.Server()
	local banned = AntiCheatService.IsBanned
	r.Functions.BuyEgg.OnServerInvoke = Validate.zeroArgs(function(player)
		return GachaService.RollEgg(player)
	end, banned)
	r.Functions.BuyMythicEgg.OnServerInvoke = Validate.zeroArgs(function(player)
		local profile = DataService.GetProfile(player)
		if not profile then
			return nil
		end
		if not EconomyService.SpendGems(player, Config.MYTHIC_EGG_COST_GEMS, "mythic_egg_buy") then
			return nil
		end
		return GachaService.RollEgg(player, { force = "Mythic", free = true })
	end, banned)
end

function GachaService.Start() end

return GachaService
