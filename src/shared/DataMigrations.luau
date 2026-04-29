--!strict
--[[
	DataMigrations — pure migration table extracted from DataService so it
	can be unit-tested without a Roblox runtime.

	Each migration mutates an old profile in-place from version (key-1) → key.
	Migrations MUST be idempotent: running the same migration twice on the
	same profile must be a no-op the second time.

	Usage:
		local DataMigrations = require(Shared.DataMigrations)
		profile = DataMigrations.run(profile, targetVersion)
]]

local DataMigrations = {}

DataMigrations.MIGRATIONS = {
	-- v1 → v2: add tutorialDone, dailyStreak, lastDailyClaimAt, gacha counters
	[2] = function(p: any)
		p.tutorialDone = p.tutorialDone or false
		p.dailyStreak = p.dailyStreak or 0
		p.lastDailyClaimAt = p.lastDailyClaimAt or 0
		p.gacha = p.gacha or { totalRolls = 0, rollsSinceEpicPlus = 0, rollsSinceMythic = 0 }
		p.gacha.legendaryCount = p.gacha.legendaryCount or 0
		p.gacha.mythicCount = p.gacha.mythicCount or 0
	end,
}

-- Defensive defaults applied after migrations finish. Safe to apply
-- multiple times; only fills missing keys.
function DataMigrations.applyDefaults(profile: any, prestigeBonusPerLevel: number)
	profile.prestigeMultiplier = 1 + (profile.prestigeLevel or 0) * prestigeBonusPerLevel
	profile.gamepasses = profile.gamepasses or {}
	profile.inventory = profile.inventory or {}
	profile.placedTanks = profile.placedTanks or {}
	profile.gacha = profile.gacha or { totalRolls = 0, rollsSinceEpicPlus = 0, rollsSinceMythic = 0 }
	profile.gacha.legendaryCount = profile.gacha.legendaryCount or 0
	profile.gacha.mythicCount = profile.gacha.mythicCount or 0
	profile.tutorialDone = profile.tutorialDone or false
	profile.dailyStreak = profile.dailyStreak or 0
	profile.lastDailyClaimAt = profile.lastDailyClaimAt or 0
end

function DataMigrations.run(profile: any, targetVersion: number, prestigeBonusPerLevel: number): any
	local from = profile.schemaVersion or 1
	for v = from + 1, targetVersion do
		local fn = DataMigrations.MIGRATIONS[v]
		if fn then
			fn(profile)
		end
		profile.schemaVersion = v
	end
	DataMigrations.applyDefaults(profile, prestigeBonusPerLevel)
	return profile
end

return DataMigrations
