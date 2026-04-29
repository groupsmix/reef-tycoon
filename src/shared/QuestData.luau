--!strict
--[[
	QuestData — daily and weekly quest templates.

	Quests are the single source of live gem income outside the egg gacha,
	so pool design matters. Keep the pools small and meaningful; every
	quest should feel worth claiming.

	Metrics (counter names QuestService.Track listens for):
		cash_earned        — from EconomyService.CashChanged (positive delta)
		eggs_pulled        — one per GachaService.RollEgg (paid or mythic)
		epic_plus_rolled   — one per roll of Epic or higher
		legendary_rolled   — one per Legendary roll
		mythic_rolled      — one per Mythic roll
		prestige           — one per successful Prestige call
		daily_claim        — one per DailyRewardService claim
		tanks_placed       — one per successful TankService.PlaceTank

	DESIGN:
		- Daily pool picks 3 distinct quests per 24h rotation.
		- Weekly pool picks 3 distinct quests per 7-day rotation.
		- All daily rewards sum to roughly one free paid-egg worth of gems.
		- Weekly rewards sum to roughly a Mythic Egg worth.

	Balance may shift post-launch; LiveConfigService is the right place to
	override this at runtime without a code release (future work).
]]

local QuestData = {}

export type Quest = {
	id: string,
	kind: "daily" | "weekly",
	description: string,
	metric: string,
	goal: number,
	rewardGems: number,
}

QuestData.DAILY_POOL = {
	{
		id = "DAILY_CASH_SMALL",
		kind = "daily",
		description = "Earn 10,000 cash.",
		metric = "cash_earned",
		goal = 10_000,
		rewardGems = 150,
	},
	{
		id = "DAILY_CASH_BIG",
		kind = "daily",
		description = "Earn 100,000 cash.",
		metric = "cash_earned",
		goal = 100_000,
		rewardGems = 400,
	},
	{
		id = "DAILY_EGG_3",
		kind = "daily",
		description = "Open 3 eggs.",
		metric = "eggs_pulled",
		goal = 3,
		rewardGems = 100,
	},
	{
		id = "DAILY_EGG_10",
		kind = "daily",
		description = "Open 10 eggs.",
		metric = "eggs_pulled",
		goal = 10,
		rewardGems = 300,
	},
	{
		id = "DAILY_EPIC_1",
		kind = "daily",
		description = "Roll an Epic-or-better fish.",
		metric = "epic_plus_rolled",
		goal = 1,
		rewardGems = 150,
	},
	{
		id = "DAILY_PLACE_TANK",
		kind = "daily",
		description = "Place a tank.",
		metric = "tanks_placed",
		goal = 1,
		rewardGems = 75,
	},
	{
		id = "DAILY_CLAIM_LOGIN",
		kind = "daily",
		description = "Claim your daily login reward.",
		metric = "daily_claim",
		goal = 1,
		rewardGems = 50,
	},
} :: { Quest }

QuestData.WEEKLY_POOL = {
	{
		id = "WEEKLY_CASH_HUGE",
		kind = "weekly",
		description = "Earn 1,000,000 cash this week.",
		metric = "cash_earned",
		goal = 1_000_000,
		rewardGems = 1_500,
	},
	{
		id = "WEEKLY_CASH_MEGA",
		kind = "weekly",
		description = "Earn 5,000,000 cash this week.",
		metric = "cash_earned",
		goal = 5_000_000,
		rewardGems = 3_000,
	},
	{
		id = "WEEKLY_EGG_50",
		kind = "weekly",
		description = "Open 50 eggs this week.",
		metric = "eggs_pulled",
		goal = 50,
		rewardGems = 1_200,
	},
	{
		id = "WEEKLY_EGG_200",
		kind = "weekly",
		description = "Open 200 eggs this week.",
		metric = "eggs_pulled",
		goal = 200,
		rewardGems = 2_500,
	},
	{
		id = "WEEKLY_LEGENDARY_3",
		kind = "weekly",
		description = "Roll 3 Legendary fish this week.",
		metric = "legendary_rolled",
		goal = 3,
		rewardGems = 1_500,
	},
	{
		id = "WEEKLY_MYTHIC_1",
		kind = "weekly",
		description = "Roll a Mythic fish.",
		metric = "mythic_rolled",
		goal = 1,
		rewardGems = 1_500,
	},
	{
		id = "WEEKLY_PRESTIGE",
		kind = "weekly",
		description = "Prestige once this week.",
		metric = "prestige",
		goal = 1,
		rewardGems = 2_000,
	},
} :: { Quest }

-- Lookup: id → quest
QuestData.ById = {} :: { [string]: Quest }
for _, q in QuestData.DAILY_POOL do
	QuestData.ById[q.id] = q
end
for _, q in QuestData.WEEKLY_POOL do
	QuestData.ById[q.id] = q
end

-- Count of quests to assign per rotation period.
QuestData.DAILIES_PER_DAY = 3
QuestData.WEEKLIES_PER_WEEK = 3

return QuestData
