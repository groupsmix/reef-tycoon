--!strict
local AntiCheatCheck = require("../../src/shared/AntiCheatCheck")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	describe("AntiCheatCheck.shouldKick", function()
		local THRESHOLD = 2_500_000

		it("ignores negative deltas (cash spent)", function()
			local prev = { cash = 1000, t = 0 }
			local now = { cash = 500, t = 1 }
			local kick = AntiCheatCheck.shouldKick(prev, now, THRESHOLD)
			expect(kick):beFalse()
		end)

		it("ignores zero or negative dt", function()
			local prev = { cash = 0, t = 5 }
			local now = { cash = 10_000_000, t = 5 }
			expect(AntiCheatCheck.shouldKick(prev, now, THRESHOLD)):beFalse()
		end)

		it("does not kick at rates below threshold", function()
			local prev = { cash = 0, t = 0 }
			local now = { cash = 1_000_000, t = 1 } -- 1M/sec, below 2.5M
			expect(AntiCheatCheck.shouldKick(prev, now, THRESHOLD)):beFalse()
		end)

		it("kicks above threshold", function()
			local prev = { cash = 0, t = 0 }
			local now = { cash = 100_000_000, t = 1 } -- 100M/sec
			expect(AntiCheatCheck.shouldKick(prev, now, THRESHOLD)):beTrue()
		end)

		it("returns the computed rate alongside the decision", function()
			local prev = { cash = 0, t = 0 }
			local now = { cash = 5_000_000, t = 2 } -- 2.5M/sec
			local _kick, rate = AntiCheatCheck.shouldKick(prev, now, THRESHOLD)
			expect(rate):equal(2_500_000)
		end)
	end)
end
