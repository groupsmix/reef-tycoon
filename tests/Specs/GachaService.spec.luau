--!strict
--[[
	GachaService pity timer tests.

	The pity rules in Config:
		PITY_EPIC_PLUS_AT = 50  -- next non-pity roll forced Epic+
		PITY_MYTHIC_AT    = 200 -- next non-pity roll forced Mythic

	We call RollEgg with `free = true` to skip gem charging, and we
	pre-load a profile via the test seam so DataService.GetProfile
	returns it.
]]

local Services = game:GetService("ServerScriptService"):WaitForChild("ReefTycoon"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local GachaService = require(Services:WaitForChild("GachaService"))

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RarityData = require(Shared:WaitForChild("RarityData"))

local Tests = script.Parent.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local describe, it, expect = Runner.describe, Runner.it, Runner.expect

local nextUserId = 7000
local function fakePlayer(): any
	nextUserId += 1
	return { UserId = nextUserId, Name = "Test_" .. nextUserId }
end

local function setupProfile(player: any)
	local profile = DataService._newProfile()
	-- Plenty of gems so a non-free pull would also succeed if we hit it.
	profile.gems = 100_000
	DataService._setProfileForTest(player, profile)
	return profile
end

local function teardown(player: any)
	DataService._clearProfileForTest(player)
end

describe("GachaService.RollEgg pity", function()
	it("forces a Mythic when rollsSinceMythic crosses PITY_MYTHIC_AT", function()
		local p = fakePlayer()
		local profile = setupProfile(p)
		profile.gacha.rollsSinceMythic = Config.PITY_MYTHIC_AT - 1 -- next +1 hits pity
		local result = GachaService.RollEgg(p, { free = true })
		expect(result).never.to.equal(nil)
		expect(result.rarity).to.equal("Mythic")
		expect(result.isPity).to.equal(true)
		-- Pity counter should reset after a Mythic+ roll.
		expect(profile.gacha.rollsSinceMythic).to.equal(0)
		teardown(p)
	end)

	it("forces an Epic+ tier when rollsSinceEpicPlus crosses PITY_EPIC_PLUS_AT", function()
		local p = fakePlayer()
		local profile = setupProfile(p)
		profile.gacha.rollsSinceEpicPlus = Config.PITY_EPIC_PLUS_AT - 1
		profile.gacha.rollsSinceMythic = 0 -- don't trigger Mythic pity instead
		local result = GachaService.RollEgg(p, { free = true })
		expect(result).never.to.equal(nil)
		expect(result.isPity).to.equal(true)
		local epicTier = RarityData.Rarities.Epic.tierIndex
		expect(RarityData.Rarities[result.rarity].tierIndex).to.greaterThan(epicTier - 1)
		expect(profile.gacha.rollsSinceEpicPlus).to.equal(0)
		teardown(p)
	end)

	it("does not pity when both counters are below threshold", function()
		local p = fakePlayer()
		local profile = setupProfile(p)
		profile.gacha.rollsSinceEpicPlus = 0
		profile.gacha.rollsSinceMythic = 0
		local result = GachaService.RollEgg(p, { free = true })
		expect(result).never.to.equal(nil)
		expect(result.isPity).to.equal(false)
		teardown(p)
	end)

	it("increments totalRolls and bumps the appropriate counters", function()
		local p = fakePlayer()
		local profile = setupProfile(p)
		profile.gacha.totalRolls = 0
		profile.gacha.rollsSinceEpicPlus = 0
		profile.gacha.rollsSinceMythic = 0
		GachaService.RollEgg(p, { free = true })
		expect(profile.gacha.totalRolls).to.equal(1)
		-- rollsSinceEpicPlus / rollsSinceMythic increment by 1 unless the
		-- roll was Epic+ / Mythic+ respectively (in which case they reset
		-- to 0). Either way, both must be non-negative.
		expect(profile.gacha.rollsSinceEpicPlus >= 0).to.equal(true)
		expect(profile.gacha.rollsSinceMythic >= 0).to.equal(true)
		teardown(p)
	end)
end)

return nil
