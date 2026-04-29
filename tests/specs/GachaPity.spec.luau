--!strict
local GachaPity = require("../../src/shared/GachaPity")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	local function newCounters()
		return { totalRolls = 0, rollsSinceEpicPlus = 0, rollsSinceMythic = 0 }
	end

	describe("GachaPity.bumpAndForcedRarity", function()
		it("does not force on the first roll", function()
			local c = newCounters()
			local forced = GachaPity.bumpAndForcedRarity(c, 200, 50)
			expect(forced):beNil()
			expect(c.totalRolls):equal(1)
			expect(c.rollsSinceEpicPlus):equal(1)
			expect(c.rollsSinceMythic):equal(1)
		end)

		it("forces Epic at the configured pity threshold", function()
			local c = newCounters()
			local forced
			for i = 1, 50 do
				forced = GachaPity.bumpAndForcedRarity(c, 200, 50)
			end
			expect(forced):equal("Epic")
			expect(c.rollsSinceEpicPlus):equal(50)
		end)

		it("forces Mythic at the configured pity threshold", function()
			local c = newCounters()
			local forced
			for i = 1, 200 do
				forced = GachaPity.bumpAndForcedRarity(c, 200, 50)
			end
			expect(forced):equal("Mythic")
		end)

		it("Mythic threshold takes precedence over Epic", function()
			local c = { totalRolls = 199, rollsSinceEpicPlus = 199, rollsSinceMythic = 199 }
			local forced = GachaPity.bumpAndForcedRarity(c, 200, 50)
			expect(forced):equal("Mythic")
		end)
	end)

	describe("GachaPity.applyResultRarity", function()
		it("resets epic counter when Epic+ is rolled", function()
			local c = { totalRolls = 1, rollsSinceEpicPlus = 49, rollsSinceMythic = 49 }
			GachaPity.applyResultRarity(c, 4, 4, 5) -- Epic
			expect(c.rollsSinceEpicPlus):equal(0)
			expect(c.rollsSinceMythic):equal(49)
		end)

		it("resets both counters when Mythic+ is rolled", function()
			local c = { totalRolls = 1, rollsSinceEpicPlus = 49, rollsSinceMythic = 199 }
			GachaPity.applyResultRarity(c, 5, 4, 5) -- Mythic
			expect(c.rollsSinceEpicPlus):equal(0)
			expect(c.rollsSinceMythic):equal(0)
		end)

		it("resets nothing when below Epic", function()
			local c = { totalRolls = 1, rollsSinceEpicPlus = 5, rollsSinceMythic = 5 }
			GachaPity.applyResultRarity(c, 3, 4, 5) -- Rare
			expect(c.rollsSinceEpicPlus):equal(5)
			expect(c.rollsSinceMythic):equal(5)
		end)
	end)
end
