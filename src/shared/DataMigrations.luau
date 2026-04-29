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

	-- v2 → v3: add `quests` and `events` sub-tables.
	-- Structure is intentionally minimal: QuestService / EventService will
	-- populate `assigned` / `progress` on first rotation. We only need to
	-- guarantee the containers exist so callers can index them without nil
	-- checks.
	[3] = function(p: any)
		if type(p.quests) ~= "table" then
			p.quests = { totalCompleted = 0 }
		end
		p.quests.totalCompleted = p.quests.totalCompleted or 0
		if type(p.quests.daily) ~= "table" then
			p.quests.daily = { resetAt = 0, assigned = {}, progress = {} }
		end
		if type(p.quests.weekly) ~= "table" then
			p.quests.weekly = { resetAt = 0, assigned = {}, progress = {} }
		end
		for _, bucket in { p.quests.daily, p.quests.weekly } do
			bucket.resetAt = bucket.resetAt or 0
			if type(bucket.assigned) ~= "table" then
				bucket.assigned = {}
			end
			if type(bucket.progress) ~= "table" then
				bucket.progress = {}
			end
		end

		if type(p.events) ~= "table" then
			p.events = {}
		end
		if type(p.events.participation) ~= "table" then
			p.events.participation = {}
		end
		if type(p.events.eventFishObtained) ~= "table" then
			p.events.eventFishObtained = {}
		end
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
	-- Quest / event containers are created by the v3 migration. We only
	-- backfill them here if the profile is already at v3+ so we don't
	-- accidentally manufacture v3 shape on a v2-targeted run.
	if (profile.schemaVersion or 1) >= 3 then
		if type(profile.quests) ~= "table" then
			profile.quests = { daily = {}, weekly = {}, totalCompleted = 0 }
		end
		profile.quests.totalCompleted = profile.quests.totalCompleted or 0
		if type(profile.quests.daily) ~= "table" then
			profile.quests.daily = { resetAt = 0, assigned = {}, progress = {} }
		end
		if type(profile.quests.weekly) ~= "table" then
			profile.quests.weekly = { resetAt = 0, assigned = {}, progress = {} }
		end
		if type(profile.events) ~= "table" then
			profile.events = { participation = {}, eventFishObtained = {} }
		end
		profile.events.participation = profile.events.participation or {}
		profile.events.eventFishObtained = profile.events.eventFishObtained or {}
	end
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
