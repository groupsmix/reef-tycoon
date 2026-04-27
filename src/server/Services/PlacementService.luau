--!strict
--[[
	PlacementService — wires ProximityPrompt clicks on plot pedestals
	(place a tank) and tank stands (remove a tank) to the gameplay
	services. Makes the world clickable without needing a UI overlay.

	Placement strategy: the prompt buys the highest-tier tank the player
	can currently afford. This makes progression feel automatic — when
	you can afford a Premium, your next pedestal click installs one.
	Players still pick specific tiers via the Shop UI which calls
	`PlaceTank` directly.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local TankData = require(Shared:WaitForChild("TankData"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local TankService = require(script.Parent:WaitForChild("TankService"))

local PlacementService = {}

local function bestAffordableTankId(profile): string?
	local ordered = {}
	for _, id in TankData.Order do
		ordered[#ordered + 1] = id
	end
	-- Walk highest tier first so an upgrade auto-installs the best one.
	for i = #ordered, 1, -1 do
		local id = ordered[i]
		local meta = TankData.Tanks[id]
		if meta and profile.cash >= meta.cost then
			return id
		end
	end
	return nil
end

local function onPedestalPrompt(player: Player, pedestal: BasePart)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	-- Server-side ownership check: only this plot's owner may place.
	local plot = pedestal:FindFirstAncestorOfClass("Model")
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end
	local pedIdx = pedestal:GetAttribute("Index")
	if typeof(pedIdx) ~= "number" then
		return
	end
	local tankId = bestAffordableTankId(profile)
	if not tankId then
		return
	end
	TankService.Place(player, tankId, pedIdx)
end

local function onTankPrompt(player: Player, prompt: ProximityPrompt)
	local stand = prompt.Parent
	if not stand or not stand:IsA("BasePart") then
		return
	end
	local model = stand:FindFirstAncestorOfClass("Model")
	local plot = model and model:FindFirstAncestorOfClass("Model") or nil
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end
	local pedIdx = prompt:GetAttribute("PedestalIndex")
	if typeof(pedIdx) ~= "number" then
		return
	end
	TankService.Remove(player, pedIdx)
end

function PlacementService.Init() end

function PlacementService.Start()
	-- Listen globally; we filter by part path inside the handler.
	local function descendantHandler(prompt: ProximityPrompt)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		prompt.Triggered:Connect(function(player)
			local parent = prompt.Parent
			if not parent or not parent:IsA("BasePart") then
				return
			end
			-- Pedestal prompts live on parts whose name starts with "Pedestal_".
			if parent.Name:sub(1, 9) == "Pedestal_" then
				onPedestalPrompt(player, parent)
			elseif parent.Name == "Stand" then
				onTankPrompt(player, prompt)
			end
		end)
	end

	-- Pre-existing prompts (the lobby just got built by WorldService).
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendantHandler(descendant)
		end
	end
	-- Future prompts (TankRenderService spawns these per tank).
	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			descendantHandler(descendant)
		end
	end)

	local _ = Players
end

return PlacementService
