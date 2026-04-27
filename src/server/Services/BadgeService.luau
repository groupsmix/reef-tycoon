--!strict
--[[
	BadgeService — awards Roblox Badges on key milestones.

	Badge IDs come from `Config.BADGE_IDS`. Set them after creating
	badges in the Creator Hub. If left at 0, awards are no-op'd silently.

	We avoid double-awarding by checking `BadgeService:UserHasBadgeAsync`
	first (which is rate-limited but cached well by Roblox).
]]

local BadgeServiceRoblox = game:GetService("BadgeService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FishData = require(Shared:WaitForChild("FishData"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local BadgeService = {}

local function award(player: Player, badgeId: number)
	if badgeId == 0 or RunService:IsStudio() then
		return
	end
	task.spawn(function()
		local ok, has = pcall(function()
			return BadgeServiceRoblox:UserHasBadgeAsync(player.UserId, badgeId)
		end)
		if ok and has then
			return
		end
		pcall(function()
			BadgeServiceRoblox:AwardBadgeAsync(player.UserId, badgeId)
		end)
	end)
end

function BadgeService.Init()
	-- Inventory-based badges: first Mythic, first Legendary
	DataService.ProfileChanged:Connect(function(player: Player, profile)
		local hasMythic = false
		local hasLegendary = false
		for fishId, _ in profile.inventory do
			local meta = FishData.getById(fishId)
			if meta then
				if meta.rarity == "Mythic" then
					hasMythic = true
				elseif meta.rarity == "Legendary" then
					hasLegendary = true
				end
			end
		end
		if hasMythic then
			award(player, Config.BADGE_IDS.FIRST_MYTHIC)
		end
		if hasLegendary then
			award(player, Config.BADGE_IDS.FIRST_LEGENDARY)
		end
		if profile.prestigeLevel >= 1 then
			award(player, Config.BADGE_IDS.FIRST_PRESTIGE)
		end
		if profile.prestigeLevel >= 10 then
			award(player, Config.BADGE_IDS.PRESTIGE_10)
		end
	end)
	-- Welcome badge on join
	Players.PlayerAdded:Connect(function(player)
		award(player, Config.BADGE_IDS.WELCOME)
	end)
end

function BadgeService.Start() end

return BadgeService
