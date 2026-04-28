--!strict
--[[
	MonetizationService.ProcessReceipt — duplicate ReceiptId is a no-op.

	We can't rely on real Roblox receipts in a test environment so we
	exercise the exposed `_processReceipt` seam with a synthetic
	receiptInfo and a fake player + injected profile.
]]

local Players = game:GetService("Players")
local Services = game:GetService("ServerScriptService"):WaitForChild("ReefTycoon"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DevProductData = require(Shared:WaitForChild("DevProductData"))

local Tests = script.Parent.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local describe, it, expect = Runner.describe, Runner.it, Runner.expect

local nextUserId = 5000
local function fakePlayer(): any
	nextUserId += 1
	return { UserId = nextUserId, Name = "Test_" .. nextUserId }
end

-- Override Players:GetPlayerByUserId so MonetizationService can find our
-- fake player. Save and restore.
local originalGetPlayerByUserId = Players.GetPlayerByUserId
local fakeRegistry: { [number]: any } = {}
local function patchPlayers()
	(Players :: any).GetPlayerByUserId = function(_, userId: number)
		return fakeRegistry[userId]
	end
end
local function unpatchPlayers()
	(Players :: any).GetPlayerByUserId = originalGetPlayerByUserId
end

describe("MonetizationService.ProcessReceipt", function()
	-- We need a known dev product ID so processReceipt can look up the
	-- effect. Temporarily set GEMS_1K's ProductId in Config; restore on
	-- teardown.
	local TEST_PRODUCT_ID = 999_001
	local originalGems1k = Config.DEV_PRODUCT_IDS.GEMS_1K

	local function withTestProductId(fn: () -> ())
		Config.DEV_PRODUCT_IDS.GEMS_1K = TEST_PRODUCT_ID
		patchPlayers()
		local ok, err = pcall(fn)
		unpatchPlayers()
		Config.DEV_PRODUCT_IDS.GEMS_1K = originalGems1k
		if not ok then
			error(err, 0)
		end
	end

	it("grants the dev product effect on first receipt", function()
		withTestProductId(function()
			local p = fakePlayer()
			fakeRegistry[p.UserId] = p
			local profile = DataService._newProfile()
			DataService._setProfileForTest(p, profile)

			local before = profile.gems
			local decision = MonetizationService._processReceipt({
				PlayerId = p.UserId,
				ProductId = TEST_PRODUCT_ID,
				PurchaseId = "receipt_first",
				CurrencyType = Enum.CurrencyType.Robux,
				CurrencySpent = 99,
				PlaceIdWherePurchased = 0,
			})
			expect(decision).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(profile.gems).to.equal(before + DevProductData.Products.GEMS_1K.effect.gems)
			expect(profile.processedReceipts["receipt_first"]).never.to.equal(nil)

			fakeRegistry[p.UserId] = nil
			DataService._clearProfileForTest(p)
		end)
	end)

	it("treats a duplicate ReceiptId as a no-op (idempotent replay)", function()
		withTestProductId(function()
			local p = fakePlayer()
			fakeRegistry[p.UserId] = p
			local profile = DataService._newProfile()
			DataService._setProfileForTest(p, profile)

			local receipt = {
				PlayerId = p.UserId,
				ProductId = TEST_PRODUCT_ID,
				PurchaseId = "receipt_dup",
				CurrencyType = Enum.CurrencyType.Robux,
				CurrencySpent = 99,
				PlaceIdWherePurchased = 0,
			}

			local decision1 = MonetizationService._processReceipt(receipt)
			local cashAfterFirst = profile.gems
			local decision2 = MonetizationService._processReceipt(receipt)
			local decision3 = MonetizationService._processReceipt(receipt)

			expect(decision1).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(decision2).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(decision3).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(profile.gems).to.equal(cashAfterFirst)

			fakeRegistry[p.UserId] = nil
			DataService._clearProfileForTest(p)
		end)
	end)

	it("returns NotProcessedYet for unknown ProductIds", function()
		withTestProductId(function()
			local p = fakePlayer()
			fakeRegistry[p.UserId] = p
			DataService._setProfileForTest(p, DataService._newProfile())
			local decision = MonetizationService._processReceipt({
				PlayerId = p.UserId,
				ProductId = 1, -- not registered
				PurchaseId = "receipt_unknown",
				CurrencyType = Enum.CurrencyType.Robux,
				CurrencySpent = 99,
				PlaceIdWherePurchased = 0,
			})
			expect(decision).to.equal(Enum.ProductPurchaseDecision.NotProcessedYet)
			fakeRegistry[p.UserId] = nil
			DataService._clearProfileForTest(p)
		end)
	end)

	it("returns NotProcessedYet when the player has left", function()
		withTestProductId(function()
			-- No player registered for UserId 9_999_999
			local decision = MonetizationService._processReceipt({
				PlayerId = 9_999_999,
				ProductId = TEST_PRODUCT_ID,
				PurchaseId = "receipt_offline",
				CurrencyType = Enum.CurrencyType.Robux,
				CurrencySpent = 99,
				PlaceIdWherePurchased = 0,
			})
			expect(decision).to.equal(Enum.ProductPurchaseDecision.NotProcessedYet)
		end)
	end)
end)

return nil
