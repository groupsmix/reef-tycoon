--!strict
--[[
	LiveConfigService — hot-loadable game config from DataStore.

	Key benefit: ship a new fish, tweak a rarity weight, or run a
	limited event without a code release.

	Fetches `ReefTycoon_LiveConfig_v1` on Init() and merges the result
	into the shared FishData / RarityData tables BEFORE Main builds
	the catalog. The shape is intentionally additive — anything in the
	live config overlays the static defaults.

	Schema:

		{
		    fishOverrides = {
		        REEF_TETRA = { primaryColor = {255, 200, 0} },  -- partial overrides
		    },
		    fishAdditions = {
		        EVENT_NEON_BETTA = {
		            id = "EVENT_NEON_BETTA",
		            name = "Neon Betta (Event)",
		            rarity = "Mythic",
		            meshAssetId = 0,
		            primaryColor = {255, 0, 200},
		            description = "Limited event fish.",
		            eventOnly = true,  -- excluded from default rolls
		        },
		    },
		    rarityWeightOverrides = {
		        Legendary = 2.0,  -- doubles legendary chances during this event
		    },
		    fishDisable = { "GHOST_HALIBUT" },
		}

	To deploy a config change:
	1. Open Studio with this experience.
	2. Run in Command Bar:
	   game:GetService("DataStoreService"):GetDataStore("ReefTycoon_LiveConfig_v1"):SetAsync("current", { ... })
	3. Restart all running servers (Creator Hub → Server Stop & Restart).

	Servers without a network path to DataStore (e.g. Studio without
	API access) silently skip and use the static defaults.
]]

local DataStoreService = game:GetService("DataStoreService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FishData = require(Shared:WaitForChild("FishData"))
local RarityData = require(Shared:WaitForChild("RarityData"))

local LiveConfigService = {}

local STORE_NAME = "ReefTycoon_LiveConfig_v1"
local STORE_KEY = "current"

local appliedConfig: { [string]: any }? = nil

local function color3FromArray(arr: { number }): Color3
	return Color3.fromRGB(arr[1] or 255, arr[2] or 255, arr[3] or 255)
end

local function applyFishOverrides(overrides: { [string]: any })
	for id, partial in overrides do
		local existing = FishData.Fish[id]
		if not existing then
			warn(("[LiveConfig] fishOverrides referenced unknown id %q"):format(id))
			continue
		end
		if partial.primaryColor and typeof(partial.primaryColor) == "table" then
			existing.primaryColor = color3FromArray(partial.primaryColor)
		end
		if typeof(partial.name) == "string" then
			existing.name = partial.name
		end
		if typeof(partial.description) == "string" then
			existing.description = partial.description
		end
		if typeof(partial.meshAssetId) == "number" then
			existing.meshAssetId = partial.meshAssetId
		end
		if typeof(partial.rarity) == "string" then
			-- Rarity changes also need ByRarity rebuild — handled below.
			existing.rarity = partial.rarity
		end
	end
end

local function applyFishAdditions(additions: { [string]: any })
	for id, fish in additions do
		if FishData.Fish[id] then
			warn(("[LiveConfig] fishAdditions tried to override existing %q; use fishOverrides"):format(id))
			continue
		end
		FishData.Fish[id] = {
			id = id,
			name = fish.name or id,
			rarity = fish.rarity or "Common",
			meshAssetId = fish.meshAssetId or 0,
			primaryColor = if typeof(fish.primaryColor) == "table"
				then color3FromArray(fish.primaryColor)
				else Color3.fromRGB(255, 255, 255),
			description = fish.description or "",
		} :: any
		-- eventOnly + other extra fields are stored verbatim for downstream services.
		if fish.eventOnly then
			(FishData.Fish[id] :: any).eventOnly = true
		end
	end
end

local function applyFishDisable(ids: { string })
	for _, id in ids do
		FishData.Fish[id] = nil
	end
end

local function applyRarityWeightOverrides(overrides: { [string]: number })
	for rarityName, weight in overrides do
		local r = RarityData.Rarities[rarityName]
		if not r then
			warn(("[LiveConfig] rarityWeightOverrides referenced unknown rarity %q"):format(rarityName))
			continue
		end
		if typeof(weight) == "number" and weight >= 0 then
			r.weight = weight
		end
	end
end

local function rebuildByRarity()
	-- FishData.ByRarity is a plain table — we rebuild it in-place so
	-- existing references stay valid.
	for k in FishData.ByRarity do
		FishData.ByRarity[k] = nil
	end
	for id, fish in FishData.Fish do
		if not FishData.ByRarity[fish.rarity] then
			FishData.ByRarity[fish.rarity] = {}
		end
		table.insert(FishData.ByRarity[fish.rarity], id)
	end
end

function LiveConfigService.GetApplied(): { [string]: any }?
	return appliedConfig
end

function LiveConfigService.Init()
	local store = DataStoreService:GetDataStore(STORE_NAME)
	local ok, result = pcall(function()
		return store:GetAsync(STORE_KEY)
	end)
	if not ok then
		warn(("[LiveConfig] could not fetch (%s); using static defaults"):format(tostring(result)))
		return
	end
	if not result then
		-- No config set yet; that's fine.
		return
	end
	if typeof(result.fishOverrides) == "table" then
		applyFishOverrides(result.fishOverrides)
	end
	if typeof(result.fishAdditions) == "table" then
		applyFishAdditions(result.fishAdditions)
	end
	if typeof(result.fishDisable) == "table" then
		applyFishDisable(result.fishDisable)
	end
	if typeof(result.rarityWeightOverrides) == "table" then
		applyRarityWeightOverrides(result.rarityWeightOverrides)
	end
	rebuildByRarity()
	appliedConfig = result
	print(
		("[LiveConfig] applied: %d overrides, %d additions, %d disabled, %d rarity tweaks"):format(
			(typeof(result.fishOverrides) == "table")
					and (function()
						local n = 0
						for _ in result.fishOverrides do
							n += 1
						end
						return n
					end)()
				or 0,
			(typeof(result.fishAdditions) == "table")
					and (function()
						local n = 0
						for _ in result.fishAdditions do
							n += 1
						end
						return n
					end)()
				or 0,
			(typeof(result.fishDisable) == "table") and #result.fishDisable or 0,
			(typeof(result.rarityWeightOverrides) == "table")
					and (function()
						local n = 0
						for _ in result.rarityWeightOverrides do
							n += 1
						end
						return n
					end)()
				or 0
		)
	)
end

function LiveConfigService.Start() end

return LiveConfigService
