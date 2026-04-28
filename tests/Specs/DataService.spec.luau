--!strict
local Services = game:GetService("ServerScriptService"):WaitForChild("ReefTycoon"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))

local Tests = script.Parent.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local describe, it, expect = Runner.describe, Runner.it, Runner.expect

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

-- A v1-shaped profile (the schema before we added tutorialDone, daily
-- streak, gacha counters, and processedReceipts).
local function v1Profile(): any
	return {
		schemaVersion = 1,
		cash = 100,
		gems = 50,
		lifetimeCash = 0,
		tankSlots = 4,
		prestigeLevel = 0,
		prestigeMultiplier = 1.0,
		gamepasses = {},
		inventory = {},
		placedTanks = {},
		gacha = {
			totalRolls = 0,
			rollsSinceEpicPlus = 0,
			rollsSinceMythic = 0,
		},
		lastSeenAt = 0,
		totalPlaytimeSec = 0,
		createdAt = 0,
	}
end

describe("DataService", function()
	describe("migrate", function()
		it("brings a v1 profile up to the current schema", function()
			local p = v1Profile()
			DataService._migrate(p)
			expect(p.schemaVersion).to.equal(Config.SCHEMA_VERSION)
			expect(p.tutorialDone).to.equal(false)
			expect(p.dailyStreak).to.equal(0)
			expect(p.lastDailyClaimAt).to.equal(0)
			expect(p.gacha.legendaryCount).to.equal(0)
			expect(p.gacha.mythicCount).to.equal(0)
			expect(p.processedReceipts).never.to.equal(nil)
		end)

		it("is idempotent — running it twice is a no-op", function()
			local p = v1Profile()
			DataService._migrate(p)
			-- Mutate to look like real gameplay state, then re-run.
			p.tutorialDone = true
			p.dailyStreak = 5
			p.gacha.legendaryCount = 2
			p.processedReceipts["receipt_abc"] = 12345
			local before = {
				schemaVersion = p.schemaVersion,
				tutorialDone = p.tutorialDone,
				dailyStreak = p.dailyStreak,
				legendaryCount = p.gacha.legendaryCount,
				processedReceiptsAbc = p.processedReceipts["receipt_abc"],
			}
			DataService._migrate(p)
			expect(p.schemaVersion).to.equal(before.schemaVersion)
			expect(p.tutorialDone).to.equal(before.tutorialDone)
			expect(p.dailyStreak).to.equal(before.dailyStreak)
			expect(p.gacha.legendaryCount).to.equal(before.legendaryCount)
			expect(p.processedReceipts["receipt_abc"]).to.equal(before.processedReceiptsAbc)
		end)

		it("upgrades v2 profiles to v3 by adding processedReceipts", function()
			local p = v1Profile()
			-- Step it up to v2 first.
			DataService._migrate(p)
			-- Pretend a v2 client wrote this save (no processedReceipts).
			p.schemaVersion = 2
			p.processedReceipts = nil :: any
			DataService._migrate(p)
			expect(p.schemaVersion).to.equal(Config.SCHEMA_VERSION)
			expect(typeof(p.processedReceipts)).to.equal("table")
		end)

		it("fills defensive defaults if fields were hand-edited away", function()
			local p = v1Profile()
			p.gamepasses = nil :: any
			p.inventory = nil :: any
			p.placedTanks = nil :: any
			DataService._migrate(p)
			expect(typeof(p.gamepasses)).to.equal("table")
			expect(typeof(p.inventory)).to.equal("table")
			expect(typeof(p.placedTanks)).to.equal("table")
		end)
	end)

	describe("_newProfile", function()
		it("uses the current schema version", function()
			local p = DataService._newProfile()
			expect(p.schemaVersion).to.equal(Config.SCHEMA_VERSION)
			expect(p.cash).to.equal(Config.STARTING_CASH)
			expect(p.gems).to.equal(Config.STARTING_GEMS)
			expect(p.tankSlots).to.equal(Config.STARTING_TANK_SLOTS)
			expect(typeof(p.processedReceipts)).to.equal("table")
		end)
	end)
end)

return nil
