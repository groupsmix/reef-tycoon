--!strict
--[[
	Config — single source of truth for tunables.

	Anything you want to tweak post-launch (drop rates, prices, IDs, cadences)
	lives here so designers don't have to edit gameplay code.
]]

local Config = {}

Config.GAME_NAME = "Reef Tycoon"
Config.GAME_VERSION = "0.2.0"

-- ────────────────────────────────────────────────────────────────────────────
-- DataStore
-- ────────────────────────────────────────────────────────────────────────────

Config.DATASTORE_KEY_PRIMARY = "ReefTycoon_Player_v1"
Config.DATASTORE_KEY_SNAPSHOT = "ReefTycoon_Player_Snapshot_v1"
Config.DATASTORE_AUDIT_KEY = "ReefTycoon_Audit_v1"
Config.SAVE_INTERVAL_SECONDS = 60
Config.SNAPSHOT_INTERVAL_SECONDS = 3600
Config.SHUTDOWN_SAVE_TIMEOUT_SECONDS = 25
Config.SCHEMA_VERSION = 3

-- ────────────────────────────────────────────────────────────────────────────
-- Economy
-- ────────────────────────────────────────────────────────────────────────────

Config.STARTING_CASH = 100
Config.STARTING_GEMS = 50 -- one free pull on the first session
Config.STARTING_TANK_SLOTS = 4
Config.MAX_OFFLINE_HOURS = 12
Config.OFFLINE_RATE_FACTOR = 0.5

-- Tip rate per fish per second = base * rarityMultiplier * tankMultiplier
Config.BASE_TIP_PER_SECOND = 0.5

-- ────────────────────────────────────────────────────────────────────────────
-- Gacha
-- ────────────────────────────────────────────────────────────────────────────

Config.EGG_COST_GEMS = 100
Config.MYTHIC_EGG_COST_GEMS = 1500 -- guaranteed Mythic+, also a dev-product offer
Config.PITY_EPIC_PLUS_AT = 50
Config.PITY_MYTHIC_AT = 200

-- Anti-spam
Config.EGG_BURST_LIMIT = 5 -- in any 1s window
Config.EGG_SUSTAINED_LIMIT = 60 -- in any 60s window

-- ────────────────────────────────────────────────────────────────────────────
-- Prestige
-- ────────────────────────────────────────────────────────────────────────────

Config.PRESTIGE_UNLOCK_LIFETIME_CASH = 1_000_000
Config.PRESTIGE_BONUS_PER_LEVEL = 0.10 -- +10% tip multiplier per prestige
Config.PRESTIGE_MAX_LEVEL = 100

-- ────────────────────────────────────────────────────────────────────────────
-- Visitors
-- ────────────────────────────────────────────────────────────────────────────

Config.VISITOR_TICK_SECONDS = 1 -- how often we award accumulated tips
Config.VISITOR_SPAWN_INTERVAL_SECONDS = 8

-- ────────────────────────────────────────────────────────────────────────────
-- Server / Place
-- ────────────────────────────────────────────────────────────────────────────

Config.SERVER_SIZE = 12
Config.MAX_TANK_SLOTS = 50

-- ────────────────────────────────────────────────────────────────────────────
-- Monetization (replace these with the IDs you create in Creator Hub)
-- ────────────────────────────────────────────────────────────────────────────

Config.GAMEPASS_IDS = {
	DOUBLE_TIPS = 0, -- 499 R$
	AUTO_COLLECT = 0, -- 299 R$
	VIP = 0, -- 999 R$
	TRIPLE_LUCK = 0, -- 799 R$
	EXTRA_TANK_SLOTS = 0, -- 399 R$
}

Config.DEV_PRODUCT_IDS = {
	GEMS_1K = 0, -- 99 R$
	GEMS_5_5K = 0, -- 499 R$
	GEMS_12K = 0, -- 999 R$
	GEMS_30K = 0, -- 2499 R$
	GEMS_75K = 0, -- 4999 R$
	MYTHIC_EGG = 0, -- 1499 R$
	EVENT_PASS = 0, -- 799 R$
}

-- ────────────────────────────────────────────────────────────────────────────
-- Badges (create in Creator Hub, then paste the IDs here)
-- ────────────────────────────────────────────────────────────────────────────

Config.BADGE_IDS = {
	WELCOME = 0,
	FIRST_MYTHIC = 0,
	FIRST_LEGENDARY = 0,
	FIRST_PRESTIGE = 0,
	PRESTIGE_10 = 0,
}

-- ────────────────────────────────────────────────────────────────────────────
-- Sounds (create / upload in Creator Hub, then paste the asset IDs)
-- Free options on the Toolbox / Asset Library are fine.
-- ────────────────────────────────────────────────────────────────────────────

Config.SOUND_IDS = {
	AMBIENT_OCEAN = 0,
	BUBBLES = 0,
	MUSIC_CHILL = 0,
	TIP = 0,
	EGG_POP = 0,
	MYTHIC_STINGER = 0,
	LEGENDARY_STINGER = 0,
}

return Config
