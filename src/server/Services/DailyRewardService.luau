--!strict
--[[
	DailyRewardService — return-tomorrow hook.

	On join, if `lastDailyClaimAt` is more than 20h ago, the player can
	claim. If less than 36h, their streak increments; if more, it
	resets to 1.

	Reward escalates with streak:
		Day 1 → 100 gems
		Day 2 → 200
		Day 3 → 350
		Day 4 → 500
		Day 5 → 750
		Day 6 → 1000
		Day 7+ → 1500 (caps; resets after day 7)
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local DailyRewardService = {}

local STREAK_REWARDS = { 100, 200, 350, 500, 750, 1000, 1500 }

local function rewardForStreak(streak: number): number
	local idx = math.clamp(streak, 1, #STREAK_REWARDS)
	return STREAK_REWARDS[idx]
end

local function getStreakState(profile)
	-- Stored on profile as `dailyStreak` and `lastDailyClaimAt` — see
	-- DataService.newProfile / migrate. We initialize defensively here
	-- so legacy profiles still work.
	if profile.dailyStreak == nil then
		profile.dailyStreak = 0
	end
	if profile.lastDailyClaimAt == nil then
		profile.lastDailyClaimAt = 0
	end
	return profile
end

function DailyRewardService.GetStatus(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil
	end
	getStreakState(profile)
	local elapsed = os.time() - (profile.lastDailyClaimAt or 0)
	local canClaim = elapsed >= 20 * 3600
	local streak = profile.dailyStreak or 0
	local nextStreak: number
	if elapsed >= 36 * 3600 then
		nextStreak = 1
	else
		nextStreak = streak + 1
	end
	return {
		canClaim = canClaim,
		streak = streak,
		nextStreak = nextStreak,
		nextReward = rewardForStreak(nextStreak),
		secondsUntilClaim = math.max(0, 20 * 3600 - elapsed),
	}
end

function DailyRewardService.Claim(player: Player): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	getStreakState(profile)
	local elapsed = os.time() - (profile.lastDailyClaimAt or 0)
	if elapsed < 20 * 3600 then
		return false
	end
	local nextStreak: number
	if elapsed >= 36 * 3600 then
		nextStreak = 1
	else
		nextStreak = (profile.dailyStreak or 0) + 1
	end
	local reward = rewardForStreak(nextStreak)
	profile.dailyStreak = nextStreak
	profile.lastDailyClaimAt = os.time()
	EconomyService.GrantGems(player, reward, "daily_reward_streak_" .. nextStreak)
	DataService.MarkChanged(player)
	return true
end

function DailyRewardService.Init()
	local r = Remotes.Server()
	r.Functions.GetDailyStatus.OnServerInvoke = function(player)
		return DailyRewardService.GetStatus(player)
	end
	r.Functions.ClaimDaily.OnServerInvoke = function(player)
		return DailyRewardService.Claim(player)
	end
end

function DailyRewardService.Start() end

return DailyRewardService
