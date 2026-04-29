--!strict
--[[
	GachaPity — pure pity-timer logic extracted from GachaService.

	`bumpAndForcedRarity(counters, mythicAt, epicAt)` increments the
	rolls-since counters and returns the forced rarity (or nil) before
	the random roll. After the roll, call `applyResultRarity(counters,
	rarityIndex, mythicIdx, epicIdx)` to reset counters appropriately.

	This module knows nothing about RNG or fish — it only manages the
	pity counters so unit tests can drive it deterministically.
]]

local GachaPity = {}

export type Counters = {
	totalRolls: number,
	rollsSinceEpicPlus: number,
	rollsSinceMythic: number,
}

-- Increments counters and returns the forced minimum rarity (Mythic
-- guaranteed, Epic+ guaranteed) or nil if no pity triggered.
function GachaPity.bumpAndForcedRarity(counters: Counters, mythicAt: number, epicAt: number): (string?, boolean)
	counters.totalRolls += 1
	counters.rollsSinceEpicPlus += 1
	counters.rollsSinceMythic += 1

	if counters.rollsSinceMythic >= mythicAt then
		return "Mythic", true
	elseif counters.rollsSinceEpicPlus >= epicAt then
		return "Epic", true
	end
	return nil, false
end

-- Resets counters based on the rarity that was actually rolled.
-- `rarityIndex` is the integer tier of the rolled rarity. `epicIndex`
-- and `mythicIndex` are the integer tiers for Epic and Mythic.
function GachaPity.applyResultRarity(counters: Counters, rarityIndex: number, epicIndex: number, mythicIndex: number)
	if rarityIndex >= epicIndex then
		counters.rollsSinceEpicPlus = 0
	end
	if rarityIndex >= mythicIndex then
		counters.rollsSinceMythic = 0
	end
end

return GachaPity
