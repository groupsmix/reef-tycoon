--!strict
--[[
	EconomyService — the only place currency moves.

	Anywhere else in the codebase, you ask EconomyService to grant or charge.
	The client never sees these methods — it only renders mirrored values.

	Audit invariant: deltas are always integers (cash) or non-negative
	(gems). We refuse negative grants.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared:WaitForChild("Signal"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local EconomyService = {}
EconomyService.CashChanged = Signal.new() -- (player, newCash, delta)
EconomyService.GemsChanged = Signal.new() -- (player, newGems, delta)

local function getProfile(player: Player)
	return DataService.GetProfile(player)
end

function EconomyService.GrantCash(player: Player, amount: number, reason: string?): boolean
	if amount < 0 then
		return false
	end
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local rounded = math.floor(amount + 0.5)
	profile.cash += rounded
	profile.lifetimeCash += rounded
	EconomyService.CashChanged:Fire(player, profile.cash, rounded, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.SpendCash(player: Player, amount: number, reason: string?): boolean
	if amount < 0 then
		return false
	end
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local rounded = math.floor(amount + 0.5)
	if profile.cash < rounded then
		return false
	end
	profile.cash -= rounded
	EconomyService.CashChanged:Fire(player, profile.cash, -rounded, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.GrantGems(player: Player, amount: number, reason: string?): boolean
	if amount < 0 then
		return false
	end
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local rounded = math.floor(amount + 0.5)
	profile.gems += rounded
	EconomyService.GemsChanged:Fire(player, profile.gems, rounded, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.SpendGems(player: Player, amount: number, reason: string?): boolean
	if amount < 0 then
		return false
	end
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local rounded = math.floor(amount + 0.5)
	if profile.gems < rounded then
		return false
	end
	profile.gems -= rounded
	EconomyService.GemsChanged:Fire(player, profile.gems, -rounded, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.GetCash(player: Player): number
	local p = getProfile(player)
	return p and p.cash or 0
end

function EconomyService.GetGems(player: Player): number
	local p = getProfile(player)
	return p and p.gems or 0
end

function EconomyService.Init()
	-- nothing yet; reserved for future hooks (e.g. analytics)
	local _ = Players
end

function EconomyService.Start() end

return EconomyService
