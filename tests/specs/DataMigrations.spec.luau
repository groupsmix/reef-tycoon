--!strict
local DataMigrations = require("../../src/shared/DataMigrations")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	local function v1Profile()
		return {
			schemaVersion = 1,
			cash = 100,
			gems = 50,
			lifetimeCash = 0,
			tankSlots = 4,
			prestigeLevel = 0,
		}
	end

	describe("DataMigrations.run v1 -> v2", function()
		it("adds tutorialDone, dailyStreak, gacha counters", function()
			local p = v1Profile()
			DataMigrations.run(p, 2, 0.10)
			expect(p.schemaVersion):equal(2)
			expect(p.tutorialDone):beFalse()
			expect(p.dailyStreak):equal(0)
			expect(p.lastDailyClaimAt):equal(0)
			expect(type(p.gacha)):equal("table")
			expect(p.gacha.legendaryCount):equal(0)
			expect(p.gacha.mythicCount):equal(0)
		end)

		it("is idempotent on repeat run", function()
			local p = v1Profile()
			DataMigrations.run(p, 2, 0.10)
			p.dailyStreak = 7
			p.gacha.legendaryCount = 3
			DataMigrations.run(p, 2, 0.10)
			expect(p.schemaVersion):equal(2)
			expect(p.dailyStreak):equal(7)
			expect(p.gacha.legendaryCount):equal(3)
		end)

		it("recomputes prestigeMultiplier from level", function()
			local p = v1Profile()
			p.prestigeLevel = 5
			DataMigrations.run(p, 2, 0.10)
			expect(p.prestigeMultiplier):near(1.5, 1e-6)
		end)

		it("fills missing tables defensively", function()
			local p = { schemaVersion = 2 } :: any
			DataMigrations.run(p, 2, 0.10)
			expect(type(p.gamepasses)):equal("table")
			expect(type(p.inventory)):equal("table")
			expect(type(p.placedTanks)):equal("table")
		end)
	end)

	describe("DataMigrations.run v2 -> v3", function()
		it("adds quests bucket with empty daily/weekly", function()
			local p = v1Profile()
			DataMigrations.run(p, 3, 0.10)
			expect(p.schemaVersion):equal(3)
			expect(type(p.quests)):equal("table")
			expect(type(p.quests.daily)):equal("table")
			expect(type(p.quests.weekly)):equal("table")
			expect(p.quests.totalCompleted):equal(0)
			expect(p.quests.daily.resetAt):equal(0)
			expect(#p.quests.daily.assigned):equal(0)
			expect(#p.quests.weekly.assigned):equal(0)
		end)

		it("adds events bucket with empty participation map", function()
			local p = v1Profile()
			DataMigrations.run(p, 3, 0.10)
			expect(type(p.events)):equal("table")
			expect(type(p.events.participation)):equal("table")
			expect(type(p.events.eventFishObtained)):equal("table")
		end)

		it("preserves existing quest progress on rerun", function()
			local p = v1Profile()
			DataMigrations.run(p, 3, 0.10)
			-- Simulate live state
			p.quests.daily.resetAt = 1_000_000
			p.quests.daily.assigned = { "DAILY_CASH_SMALL" }
			p.quests.daily.progress = { DAILY_CASH_SMALL = { progress = 4_000, claimed = false } }
			p.quests.totalCompleted = 7
			p.events.participation = { SUMMER_FEST = { firstSeen = 12, lastClaimed = 0, progress = 3 } }

			DataMigrations.run(p, 3, 0.10)

			expect(p.schemaVersion):equal(3)
			expect(p.quests.daily.resetAt):equal(1_000_000)
			expect(p.quests.daily.assigned[1]):equal("DAILY_CASH_SMALL")
			expect(p.quests.daily.progress.DAILY_CASH_SMALL.progress):equal(4_000)
			expect(p.quests.totalCompleted):equal(7)
			expect(p.events.participation.SUMMER_FEST.progress):equal(3)
		end)

		it("upgrades a v2 profile in one shot", function()
			local p = v1Profile()
			DataMigrations.run(p, 2, 0.10)
			-- p is now schemaVersion 2 with no quests/events.
			expect(p.quests):beNil()
			expect(p.events):beNil()
			DataMigrations.run(p, 3, 0.10)
			expect(p.schemaVersion):equal(3)
			expect(type(p.quests)):equal("table")
			expect(type(p.events)):equal("table")
		end)

		it("upgrades v1 → v3 in one call", function()
			local p = v1Profile()
			DataMigrations.run(p, 3, 0.10)
			expect(p.schemaVersion):equal(3)
			-- v2 fields still present
			expect(p.tutorialDone):beFalse()
			expect(p.dailyStreak):equal(0)
			-- v3 fields present
			expect(type(p.quests)):equal("table")
			expect(type(p.events)):equal("table")
		end)
	end)
end
