--!strict
--[[
	EconomyService — the only place currency moves.

	Anywhere else in the codebase, you ask EconomyService to grant or charge.
	The client never sees these methods — it only renders mirrored values.

	The rounding / non-negative invariants live in EconomyOps so they can
	be unit-tested without a Roblox runtime.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared:WaitForChild("Signal"))
local EconomyOps = require(Shared:WaitForChild("EconomyOps"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local EconomyService = {}
EconomyService.CashChanged = Signal.new() -- (player, newCash, delta)
EconomyService.GemsChanged = Signal.new() -- (player, newGems, delta)

local function getProfile(player: Player)
	return DataService.GetProfile(player)
end

function EconomyService.GrantCash(player: Player, amount: number, reason: string?): boolean
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local ok, delta = EconomyOps.grantCash(profile, amount)
	if not ok then
		return false
	end
	EconomyService.CashChanged:Fire(player, profile.cash, delta, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.SpendCash(player: Player, amount: number, reason: string?): boolean
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local ok, delta = EconomyOps.spendCash(profile, amount)
	if not ok then
		return false
	end
	EconomyService.CashChanged:Fire(player, profile.cash, -delta, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.GrantGems(player: Player, amount: number, reason: string?): boolean
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local ok, delta = EconomyOps.grantGems(profile, amount)
	if not ok then
		return false
	end
	EconomyService.GemsChanged:Fire(player, profile.gems, delta, reason)
	DataService.MarkChanged(player)
	return true
end

function EconomyService.SpendGems(player: Player, amount: number, reason: string?): boolean
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local ok, delta = EconomyOps.spendGems(profile, amount)
	if not ok then
		return false
	end
	EconomyService.GemsChanged:Fire(player, profile.gems, -delta, reason)
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
