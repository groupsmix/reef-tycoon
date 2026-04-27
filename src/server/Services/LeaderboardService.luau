--!strict
--[[
	LeaderboardService — `leaderstats` per player + a global top-10
	OrderedDataStore for cash and prestige.

	Ordered DataStore writes are throttled so we don't burn quota: we
	push new values once every 60s per player.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent:WaitForChild("DataService"))

local LeaderboardService = {}

local cashStore = DataStoreService:GetOrderedDataStore("ReefTycoon_Cash_v1")
local prestigeStore = DataStoreService:GetOrderedDataStore("ReefTycoon_Prestige_v1")

local lastWrite: { [number]: number } = {}

local function ensureLeaderstats(player: Player)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		return existing
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats

	local prestige = Instance.new("IntValue")
	prestige.Name = "Prestige"
	prestige.Parent = stats

	stats.Parent = player
	return stats
end

local function refreshLeaderstats(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local stats = ensureLeaderstats(player)
	local cash = stats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cash.Value = math.clamp(profile.cash, -2_147_483_647, 2_147_483_647)
	end
	local prestige = stats:FindFirstChild("Prestige")
	if prestige and prestige:IsA("IntValue") then
		prestige.Value = profile.prestigeLevel
	end
end

local function maybeWrite(player: Player)
	if RunService:IsStudio() then
		return
	end
	local now = os.clock()
	if (lastWrite[player.UserId] or 0) > now - 60 then
		return
	end
	lastWrite[player.UserId] = now
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	task.spawn(function()
		pcall(function()
			cashStore:SetAsync(tostring(player.UserId), math.clamp(profile.lifetimeCash, 0, 2 ^ 31 - 1))
		end)
		pcall(function()
			prestigeStore:SetAsync(tostring(player.UserId), profile.prestigeLevel)
		end)
	end)
end

function LeaderboardService.GetTopCash(): { { userId: number, cash: number } }
	if RunService:IsStudio() then
		return {}
	end
	local result = {}
	pcall(function()
		local pages = cashStore:GetSortedAsync(false, 10)
		local page = pages:GetCurrentPage()
		for _, entry in page do
			table.insert(result, {
				userId = tonumber(entry.key) or 0,
				cash = entry.value,
			})
		end
	end)
	return result
end

function LeaderboardService.Init()
	Players.PlayerAdded:Connect(ensureLeaderstats)
	for _, p in Players:GetPlayers() do
		ensureLeaderstats(p)
	end
end

function LeaderboardService.Start()
	DataService.ProfileChanged:Connect(function(player: Player, _profile)
		refreshLeaderstats(player)
		maybeWrite(player)
	end)
end

return LeaderboardService
