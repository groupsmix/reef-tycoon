--!strict
--[[
	EconomyOps — pure cash/gem mutations on a profile struct.

	Server services apply currency changes via these helpers so the
	integer-rounding, negative-rejection, and balance-floor rules are
	expressed in one testable place. The Roblox-facing EconomyService
	composes these with Signals, Players, and DataService.MarkChanged.
]]

local EconomyOps = {}

export type Profile = {
	cash: number,
	gems: number,
	lifetimeCash: number,
}

local function round(amount: number): number
	return math.floor(amount + 0.5)
end

-- Adds `amount` to cash. Returns (ok, delta). Rejects negative, NaN, infinite.
function EconomyOps.grantCash(profile: Profile, amount: number): (boolean, number)
	if amount ~= amount or amount == math.huge or amount == -math.huge then
		return false, 0
	end
	if amount < 0 then
		return false, 0
	end
	local rounded = round(amount)
	profile.cash += rounded
	profile.lifetimeCash += rounded
	return true, rounded
end

function EconomyOps.spendCash(profile: Profile, amount: number): (boolean, number)
	if amount ~= amount or amount == math.huge or amount == -math.huge then
		return false, 0
	end
	if amount < 0 then
		return false, 0
	end
	local rounded = round(amount)
	if profile.cash < rounded then
		return false, 0
	end
	profile.cash -= rounded
	return true, rounded
end

function EconomyOps.grantGems(profile: Profile, amount: number): (boolean, number)
	if amount ~= amount or amount == math.huge or amount == -math.huge then
		return false, 0
	end
	if amount < 0 then
		return false, 0
	end
	local rounded = round(amount)
	profile.gems += rounded
	return true, rounded
end

function EconomyOps.spendGems(profile: Profile, amount: number): (boolean, number)
	if amount ~= amount or amount == math.huge or amount == -math.huge then
		return false, 0
	end
	if amount < 0 then
		return false, 0
	end
	local rounded = round(amount)
	if profile.gems < rounded then
		return false, 0
	end
	profile.gems -= rounded
	return true, rounded
end

return EconomyOps
