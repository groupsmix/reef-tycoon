--!strict
local Services = game:GetService("ServerScriptService"):WaitForChild("ReefTycoon"):WaitForChild("Services")
local AntiCheatService = require(Services:WaitForChild("AntiCheatService"))

local Tests = script.Parent.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local describe, it, expect = Runner.describe, Runner.it, Runner.expect

describe("AntiCheatService", function()
	describe("_exceedsThreshold", function()
		local threshold = AntiCheatService._kickThreshold()

		it("ignores rates well below the configured threshold", function()
			expect(AntiCheatService._exceedsThreshold(0)).to.equal(false)
			expect(AntiCheatService._exceedsThreshold(1)).to.equal(false)
			expect(AntiCheatService._exceedsThreshold(threshold * 0.5)).to.equal(false)
		end)

		it("ignores rates exactly at the threshold (boundary)", function()
			-- The check is strictly `>`, so rate == threshold is allowed.
			expect(AntiCheatService._exceedsThreshold(threshold)).to.equal(false)
		end)

		it("kicks rates above the threshold", function()
			expect(AntiCheatService._exceedsThreshold(threshold + 1)).to.equal(true)
			expect(AntiCheatService._exceedsThreshold(threshold * 10)).to.equal(true)
		end)
	end)

	describe("threshold magnitude", function()
		it("is at least 5x the documented theoretical max (~500k/sec)", function()
			-- Sanity guard: if someone tunes the constant down, this catches
			-- it before legitimate whales get auto-kicked.
			expect(AntiCheatService._kickThreshold()).to.equal(500_000 * 5)
		end)
	end)
end)

return nil
