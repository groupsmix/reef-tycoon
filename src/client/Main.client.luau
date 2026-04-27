--!strict
--[[
	Reef Tycoon — client bootstrap.

	Owns the player's mirrored snapshot of server state and forwards it
	to each controller. Controllers never call remotes for read state;
	they read from this module.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Signal = require(Shared:WaitForChild("Signal"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Controllers = script.Parent:WaitForChild("Controllers")
local HudController = require(Controllers:WaitForChild("HudController"))
local ShopController = require(Controllers:WaitForChild("ShopController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
local GachaController = require(Controllers:WaitForChild("GachaController"))

local State = {
	catalog = nil :: any,
	snapshot = nil :: any,
	SnapshotChanged = Signal.new(),
}

local r = Remotes.Client()

State.catalog = r.Functions.GetCatalog:InvokeServer()
State.snapshot = r.Functions.GetPlayerSnapshot:InvokeServer()

r.Events.PlayerDataReplicated.OnClientEvent:Connect(function(snapshot)
	State.snapshot = snapshot
	State.SnapshotChanged:Fire(snapshot)
end)

-- Build the persistent ScreenGui everyone hangs UI off.
local screen = Instance.new("ScreenGui")
screen.Name = "ReefTycoonGui"
screen.IgnoreGuiInset = false
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = PlayerGui

HudController.Mount(screen, State)
ShopController.Mount(screen, State)
InventoryController.Mount(screen, State)
GachaController.Mount(screen, State, r)

-- Forward Mythic+ pull events to the GachaController for the cinematic.
r.Events.GachaPullResult.OnClientEvent:Connect(function(result)
	GachaController.OnPullResult(result)
end)

r.Events.LegendaryAnnounce.OnClientEvent:Connect(function(payload)
	GachaController.OnLegendaryAnnounce(payload)
end)

print(
	("[ReefTycoon] client ready (v%s)"):format(
		State.catalog and require(Shared:WaitForChild("Config")).GAME_VERSION or "?"
	)
)
