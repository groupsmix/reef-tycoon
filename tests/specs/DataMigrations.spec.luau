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
end
