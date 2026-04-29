--!strict
local WeightedRandom = require("../../src/shared/Util/WeightedRandom")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	describe("WeightedRandom.pick", function()
		it("returns nil for empty weights", function()
			expect(WeightedRandom.pick({})):beNil()
		end)

		it("returns nil if all weights are zero", function()
			expect(WeightedRandom.pick({ a = 0, b = 0 })):beNil()
		end)

		it("always returns the only non-zero key", function()
			for _ = 1, 50 do
				expect(WeightedRandom.pick({ a = 0, b = 1, c = 0 })):equal("b")
			end
		end)

		it("approximates the weight ratio over many draws", function()
			math.randomseed(42)
			local weights = { a = 1, b = 9 }
			local counts = { a = 0, b = 0 }
			local n = 5000
			for _ = 1, n do
				counts[WeightedRandom.pick(weights)] += 1
			end
			-- b should be ~9x more frequent than a; allow loose bounds for flake
			expect(counts.b / counts.a):beGreaterThan(6)
			expect(counts.b / counts.a):beLessThan(15)
		end)
	end)
end
