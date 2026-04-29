--!strict
--[[
	QuestService — daily + weekly quest engine.

	Rotation cadence:
		daily  → next UTC midnight
		weekly → next UTC Monday 00:00

	On first observation for a given bucket (or when os.time() >= resetAt),
	RotateIfDue() picks `DAILIES_PER_DAY` / `WEEKLIES_PER_WEEK` distinct
	quests from the pool, seeds empty progress entries, and writes the
	next resetAt. Re-entry within the same period is a no-op.

	Scoring:
		Callers in other services report a counter via
			QuestService.Track(player, "cash_earned", amount)
		QuestService finds all *assigned* quests whose metric matches and
		whose progress isn't claimed yet, then adds `amount` to each. A
		quest is "completed" when `progress >= goal`; it stays unclaimed
		until the player taps the claim button, which awards gems and
		marks the entry as claimed.

	Why track and not auto-claim?
		Auto-claim would make the UI reactive (gems appear mid-gameplay,
		player confused where they came from). Requiring an explicit
		claim gives us a ritual moment for celebration and a clear
		audit boundary (one remote call = one reward grant).
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local QuestData = require(Shared:WaitForChild("QuestData"))
local Validate = require(Shared:WaitForChild("Util"):WaitForChild("Validate"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local AntiCheatService = require(script.Parent:WaitForChild("AntiCheatService"))

local QuestService = {}

local SECONDS_PER_DAY = 86_400
local SECONDS_PER_WEEK = SECONDS_PER_DAY * 7

local rng = Random.new()

-- Next UTC midnight strictly after `now`.
local function nextDailyReset(now: number): number
	return math.floor(now / SECONDS_PER_DAY) * SECONDS_PER_DAY + SECONDS_PER_DAY
end

-- Next UTC Monday 00:00 strictly after `now`.
-- Unix epoch 1970-01-01 was a Thursday, so Monday-aligned weeks start at
-- (epoch + 4 days) mod 7 == 0. We align by subtracting 4 days worth of
-- seconds, flooring to weeks, then adding them back.
local WEEK_OFFSET = 4 * SECONDS_PER_DAY
local function nextWeeklyReset(now: number): number
	local shifted = now - WEEK_OFFSET
	local nextStart = math.floor(shifted / SECONDS_PER_WEEK) * SECONDS_PER_WEEK + SECONDS_PER_WEEK
	return nextStart + WEEK_OFFSET
end

local function pickDistinct(pool, count: number): { string }
	-- Shallow copy of ids so we can shuffle without mutating the pool.
	local ids = {}
	for _, q in pool do
		table.insert(ids, q.id)
	end
	-- Fisher-Yates up to `count` items.
	local take = math.min(count, #ids)
	for i = 1, take do
		local j = rng:NextInteger(i, #ids)
		ids[i], ids[j] = ids[j], ids[i]
	end
	local picked = {}
	for i = 1, take do
		table.insert(picked, ids[i])
	end
	return picked
end

local function rotateBucket(bucket, pool, count: number, nextResetAt: number)
	bucket.assigned = pickDistinct(pool, count)
	bucket.progress = {}
	for _, id in bucket.assigned do
		bucket.progress[id] = { progress = 0, claimed = false }
	end
	bucket.resetAt = nextResetAt
end

function QuestService.RotateIfDue(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local now = os.time()
	local dirty = false
	if now >= (profile.quests.daily.resetAt or 0) then
		rotateBucket(profile.quests.daily, QuestData.DAILY_POOL, QuestData.DAILIES_PER_DAY, nextDailyReset(now))
		dirty = true
	end
	if now >= (profile.quests.weekly.resetAt or 0) then
		rotateBucket(profile.quests.weekly, QuestData.WEEKLY_POOL, QuestData.WEEKLIES_PER_WEEK, nextWeeklyReset(now))
		dirty = true
	end
	if dirty then
		DataService.MarkChanged(player)
	end
end

local function bucketForKind(profile, kind: string)
	if kind == "daily" then
		return profile.quests.daily
	end
	return profile.quests.weekly
end

-- Track a counter against every assigned quest whose metric matches.
function QuestService.Track(player: Player, metric: string, amount: number)
	if amount <= 0 then
		return
	end
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	QuestService.RotateIfDue(player)

	local changed = false
	for _, bucket in { profile.quests.daily, profile.quests.weekly } do
		for _, questId in bucket.assigned do
			local quest = QuestData.ById[questId]
			if quest and quest.metric == metric then
				local entry = bucket.progress[questId]
				if entry and not entry.claimed and entry.progress < quest.goal then
					entry.progress = math.min(quest.goal, entry.progress + amount)
					changed = true
				end
			end
		end
	end
	if changed then
		DataService.MarkChanged(player)
	end
end

-- Return a client-safe snapshot of the player's quests.
function QuestService.GetQuests(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil
	end
	QuestService.RotateIfDue(player)

	local function serializeBucket(bucket, kind: string)
		local items = {}
		for _, questId in bucket.assigned do
			local quest = QuestData.ById[questId]
			local entry = bucket.progress[questId] or { progress = 0, claimed = false }
			if quest then
				table.insert(items, {
					id = quest.id,
					kind = kind,
					description = quest.description,
					goal = quest.goal,
					rewardGems = quest.rewardGems,
					progress = entry.progress,
					claimed = entry.claimed,
					completed = entry.progress >= quest.goal,
				})
			end
		end
		return {
			items = items,
			resetAt = bucket.resetAt,
			secondsUntilReset = math.max(0, bucket.resetAt - os.time()),
		}
	end

	return {
		daily = serializeBucket(profile.quests.daily, "daily"),
		weekly = serializeBucket(profile.quests.weekly, "weekly"),
		totalCompleted = profile.quests.totalCompleted or 0,
	}
end

-- Claim a completed quest. Returns true on success.
function QuestService.ClaimQuest(player: Player, questId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	local quest = QuestData.ById[questId]
	if not quest then
		return false
	end
	QuestService.RotateIfDue(player)

	local bucket = bucketForKind(profile, quest.kind)
	-- Must be currently assigned — prevents claiming a quest that rolled
	-- off the list before the client got the update.
	local isAssigned = false
	for _, id in bucket.assigned do
		if id == questId then
			isAssigned = true
			break
		end
	end
	if not isAssigned then
		return false
	end

	local entry = bucket.progress[questId]
	if not entry then
		return false
	end
	if entry.claimed then
		return false
	end
	if entry.progress < quest.goal then
		return false
	end

	entry.claimed = true
	profile.quests.totalCompleted = (profile.quests.totalCompleted or 0) + 1
	EconomyService.GrantGems(player, quest.rewardGems, "quest_claim_" .. questId)
	DataService.MarkChanged(player)
	return true
end

function QuestService.Init()
	local r = Remotes.Server()
	local banned = AntiCheatService.IsBanned

	r.Functions.GetQuests.OnServerInvoke = Validate.zeroArgs(function(player)
		return QuestService.GetQuests(player)
	end, banned)

	r.Functions.ClaimQuest.OnServerInvoke = Validate.wrap({ "string" }, function(player, questId: string)
		return QuestService.ClaimQuest(player, questId)
	end, banned)

	-- Cash-earned metric is sourced from EconomyService's signal so every
	-- path that grants cash (visitor tips, offline earnings, dev gifts)
	-- flows through QuestService automatically.
	EconomyService.CashChanged:Connect(function(player: Player, _newCash, delta, _reason)
		if typeof(delta) == "number" and delta > 0 then
			QuestService.Track(player, "cash_earned", delta)
		end
	end)
end

function QuestService.Start() end

return QuestService
