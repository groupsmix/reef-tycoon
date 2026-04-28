--!strict
local Services = game:GetService("ServerScriptService"):WaitForChild("ReefTycoon"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))

local Tests = script.Parent.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local describe, it, expect = Runner.describe, Runner.it, Runner.expect

local nextUserId = 1000
local function fakePlayer(): any
	nextUserId += 1
	return { UserId = nextUserId, Name = "Test_" .. nextUserId }
end

local function setupProfile(player: any)
	local profile = DataService._newProfile()
	DataService._setProfileForTest(player, profile)
	return profile
end

describe("EconomyService", function()
	describe("GrantCash", function()
		it("rejects negative amounts", function()
			local p = fakePlayer()
			local profile = setupProfile(p)
			local before = profile.cash
			local ok = EconomyService.GrantCash(p, -50)
			expect(ok).to.equal(false)
			expect(profile.cash).to.equal(before)
			DataService._clearProfileForTest(p)
		end)

		it("returns false when no profile is loaded", function()
			local p = fakePlayer()
			-- Intentionally do NOT set a profile.
			expect(EconomyService.GrantCash(p, 100)).to.equal(false)
		end)

		it("increments cash and fires CashChanged with delta + reason", function()
			local p = fakePlayer()
			local profile = setupProfile(p)
			local before = profile.cash
			local fired: any = nil
			local conn = EconomyService.CashChanged:Connect(function(plr, newCash, delta, reason)
				fired = { plr = plr, newCash = newCash, delta = delta, reason = reason }
			end)
			local ok = EconomyService.GrantCash(p, 100, "tip")
			conn:Disconnect()
			expect(ok).to.equal(true)
			expect(profile.cash).to.equal(before + 100)
			expect(profile.lifetimeCash).to.equal(100)
			expect(fired).never.to.equal(nil)
			expect(fired.delta).to.equal(100)
			expect(fired.reason).to.equal("tip")
			expect(fired.newCash).to.equal(profile.cash)
			DataService._clearProfileForTest(p)
		end)

		it("rounds non-integer amounts to the nearest integer", function()
			local p = fakePlayer()
			local profile = setupProfile(p)
			local before = profile.cash
			EconomyService.GrantCash(p, 10.7)
			expect(profile.cash).to.equal(before + 11)
			DataService._clearProfileForTest(p)
		end)

		it("persists by calling DataService.MarkChanged", function()
			local p = fakePlayer()
			setupProfile(p)
			local original = DataService.MarkChanged
			local called = false
			local stub = function(plr: Player)
				called = true
				original(plr)
			end;
			(DataService :: any).MarkChanged = stub
			local ok = EconomyService.GrantCash(p, 100);
			(DataService :: any).MarkChanged = original
			expect(ok).to.equal(true)
			expect(called).to.equal(true)
			DataService._clearProfileForTest(p)
		end)
	end)

	describe("SpendCash", function()
		it("rejects negative amounts", function()
			local p = fakePlayer()
			setupProfile(p)
			expect(EconomyService.SpendCash(p, -10)).to.equal(false)
			DataService._clearProfileForTest(p)
		end)

		it("rejects when insufficient cash and leaves profile untouched", function()
			local p = fakePlayer()
			local profile = setupProfile(p)
			profile.cash = 50
			expect(EconomyService.SpendCash(p, 100)).to.equal(false)
			expect(profile.cash).to.equal(50)
			DataService._clearProfileForTest(p)
		end)

		it("deducts and fires signal with negative delta on success", function()
			local p = fakePlayer()
			local profile = setupProfile(p)
			profile.cash = 200
			local fired: any = nil
			local conn = EconomyService.CashChanged:Connect(function(_, newCash, delta, reason)
				fired = { newCash = newCash, delta = delta, reason = reason }
			end)
			local ok = EconomyService.SpendCash(p, 80, "buy")
			conn:Disconnect()
			expect(ok).to.equal(true)
			expect(profile.cash).to.equal(120)
			expect(fired).never.to.equal(nil)
			expect(fired.delta).to.equal(-80)
			expect(fired.reason).to.equal("buy")
			DataService._clearProfileForTest(p)
		end)
	end)
end)

return nil
