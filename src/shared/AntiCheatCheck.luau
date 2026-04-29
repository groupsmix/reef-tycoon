--!strict
--[[
	AntiCheatCheck — pure cash-velocity check function.

	`shouldKick(prevCash, prevTime, newCash, now, kickThreshold)` returns
	(shouldKick, rate, delta, dt). Extracted from AntiCheatService so the
	logic can be unit-tested without spawning a Roblox player.

	Negative deltas (cash spent) and zero/negative dt always return false.
]]

local AntiCheatCheck = {}

export type Sample = {
	cash: number,
	t: number,
}

function AntiCheatCheck.computeRate(prev: Sample, current: Sample): (number, number, number)
	local dt = current.t - prev.t
	local delta = current.cash - prev.cash
	if dt <= 0 then
		return 0, delta, dt
	end
	return delta / dt, delta, dt
end

function AntiCheatCheck.shouldKick(
	prev: Sample,
	current: Sample,
	kickThreshold: number
): (boolean, number, number, number)
	local rate, delta, dt = AntiCheatCheck.computeRate(prev, current)
	if dt <= 0 or delta <= 0 then
		return false, rate, delta, dt
	end
	return rate > kickThreshold, rate, delta, dt
end

return AntiCheatCheck
