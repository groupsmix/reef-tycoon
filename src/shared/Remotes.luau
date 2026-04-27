--!strict
--[[
	Remotes — registers and exposes named RemoteEvents and RemoteFunctions
	under ReplicatedStorage.Shared.RemoteRoot.

	Calling `Remotes:Server()` from server code creates the folder and
	instances on first call. Calling `Remotes:Client()` from client code
	waits for them to exist.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENT_NAMES = {
	"PlayerDataReplicated",
	"GachaPullResult",
	"VisitorTipDelta",
	"PrestigeAnnounce",
	"LegendaryAnnounce",
	"PromptDevProductPurchase",
	"PromptGamepassPurchase",
}

local FUNCTION_NAMES = {
	"PlaceTank",
	"RemoveTank",
	"AssignFishToTank",
	"UnassignFishFromTank",
	"BuyEgg",
	"BuyMythicEgg",
	"Prestige",
	"GetPlayerSnapshot",
	"GetCatalog",
}

local Remotes = {}

local function ensureRoot(): Folder
	local root = ReplicatedStorage:FindFirstChild("RemoteRoot")
	if root then
		return root :: Folder
	end
	if RunService:IsServer() then
		root = Instance.new("Folder")
		root.Name = "RemoteRoot"
		root.Parent = ReplicatedStorage
	else
		root = ReplicatedStorage:WaitForChild("RemoteRoot", 10)
		assert(root, "RemoteRoot never replicated to client")
	end
	return root :: Folder
end

local function buildServer()
	local root = ensureRoot()
	local events = {} :: { [string]: RemoteEvent }
	local funcs = {} :: { [string]: RemoteFunction }

	for _, name in EVENT_NAMES do
		local existing = root:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			events[name] = existing
		else
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = root
			events[name] = ev
		end
	end

	for _, name in FUNCTION_NAMES do
		local existing = root:FindFirstChild(name)
		if existing and existing:IsA("RemoteFunction") then
			funcs[name] = existing
		else
			local rf = Instance.new("RemoteFunction")
			rf.Name = name
			rf.Parent = root
			funcs[name] = rf
		end
	end

	return { Events = events, Functions = funcs }
end

local function buildClient()
	local root = ensureRoot()
	local events = {} :: { [string]: RemoteEvent }
	local funcs = {} :: { [string]: RemoteFunction }
	for _, name in EVENT_NAMES do
		events[name] = root:WaitForChild(name, 10) :: RemoteEvent
	end
	for _, name in FUNCTION_NAMES do
		funcs[name] = root:WaitForChild(name, 10) :: RemoteFunction
	end
	return { Events = events, Functions = funcs }
end

local cachedServer
local cachedClient

function Remotes.Server()
	if not cachedServer then
		cachedServer = buildServer()
	end
	return cachedServer
end

function Remotes.Client()
	if not cachedClient then
		cachedClient = buildClient()
	end
	return cachedClient
end

return Remotes
