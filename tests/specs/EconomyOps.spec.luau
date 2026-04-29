--!strict
local EconomyOps = require("../../src/shared/EconomyOps")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	describe("EconomyOps.grantCash", function()
		it("rejects negative amounts", function()
			local p = { cash = 100, gems = 0, lifetimeCash = 0 }
			local ok = EconomyOps.grantCash(p, -50)
			expect(ok):beFalse()
			expect(p.cash):equal(100)
		end)

		it("rejects NaN and infinity", function()
			local p = { cash = 100, gems = 0, lifetimeCash = 0 }
			expect(EconomyOps.grantCash(p, 0 / 0)):beFalse()
			expect(EconomyOps.grantCash(p, math.huge)):beFalse()
			expect(p.cash):equal(100)
		end)

		it("rounds fractional grants and updates lifetime", function()
			local p = { cash = 0, gems = 0, lifetimeCash = 0 }
			local ok, delta = EconomyOps.grantCash(p, 7.6)
			expect(ok):beTrue()
			expect(delta):equal(8)
			expect(p.cash):equal(8)
			expect(p.lifetimeCash):equal(8)
		end)

		it("accumulates across multiple grants", function()
			local p = { cash = 0, gems = 0, lifetimeCash = 0 }
			EconomyOps.grantCash(p, 5)
			EconomyOps.grantCash(p, 3)
			expect(p.cash):equal(8)
			expect(p.lifetimeCash):equal(8)
		end)
	end)

	describe("EconomyOps.spendCash", function()
		it("rejects negative amounts", function()
			local p = { cash = 100, gems = 0, lifetimeCash = 0 }
			local ok = EconomyOps.spendCash(p, -10)
			expect(ok):beFalse()
			expect(p.cash):equal(100)
		end)

		it("rejects insufficient balance", function()
			local p = { cash = 5, gems = 0, lifetimeCash = 0 }
			local ok = EconomyOps.spendCash(p, 10)
			expect(ok):beFalse()
			expect(p.cash):equal(5)
		end)

		it("does not touch lifetimeCash when spending", function()
			local p = { cash = 100, gems = 0, lifetimeCash = 100 }
			EconomyOps.spendCash(p, 30)
			expect(p.cash):equal(70)
			expect(p.lifetimeCash):equal(100)
		end)
	end)

	describe("EconomyOps.grantGems / spendGems", function()
		it("symmetric with cash but no lifetime tracking", function()
			local p = { cash = 0, gems = 50, lifetimeCash = 0 }
			expect(EconomyOps.grantGems(p, 10)):beTrue()
			expect(p.gems):equal(60)
			expect(EconomyOps.spendGems(p, 70)):beFalse()
			expect(p.gems):equal(60)
			expect(EconomyOps.spendGems(p, 60)):beTrue()
			expect(p.gems):equal(0)
		end)
	end)
end
