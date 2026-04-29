--!strict
--[[
	Strings — string-table lookup for player-facing copy.

	UI controllers should never hardcode user-facing strings. They call
	`Strings.get("hud.cash")` and the locale layer returns the resolved
	value. At launch we ship en-US only; localized tables live next to
	this module and load lazily once the player's locale is known.

	Keys use dotted namespaces (`hud.cash`, `shop.buy`, `tutorial.step1`)
	so we can grep-find them and so they don't collide with feature flags
	or asset names.

	The fallback chain is:
		current locale → en-US → key (verbatim)

	Returning the key verbatim if a translation is missing makes missing
	strings visible without hard-crashing.
]]

local Strings = {}

local SUPPORTED = {
	["en-US"] = true,
	-- Add additional locales here when they ship. The table layouts
	-- live next to this module (Strings_<locale>.luau).
}

local TABLES: { [string]: { [string]: string } } = {
	["en-US"] = {
		-- HUD
		["hud.cash"] = "$",
		["hud.gems"] = "💎",
		["hud.prestige"] = "★",
		["hud.slots"] = "Slots",

		-- Shop
		["shop.title"] = "Shop",
		["shop.buy"] = "Buy",
		["shop.gems_pack"] = "Gem Pack",
		["shop.mythic_egg"] = "Mythic Egg (guaranteed)",

		-- Inventory
		["inventory.title"] = "Inventory",
		["inventory.empty"] = "No fish yet — buy an egg!",

		-- Gacha
		["gacha.button"] = "Open Egg",
		["gacha.mythic_button"] = "Open Mythic Egg",
		["gacha.cost"] = "Cost: %d gems",
		["gacha.pity_msg_epic"] = "Pity timer guaranteed Epic+!",
		["gacha.pity_msg_mythic"] = "Pity timer guaranteed Mythic!",

		-- Tutorial
		["tutorial.welcome"] = "Welcome to the reef. Let's get your first fish.",
		["tutorial.place_tank"] = "Step on a free pedestal and place a tank.",
		["tutorial.open_egg"] = "Open the shop and crack your first egg.",
		["tutorial.assign_fish"] = "Assign your fish to a tank to start earning tips.",
		["tutorial.done"] = "You're all set! Visitors will start tipping.",

		-- Daily reward
		["daily.title"] = "Daily Reward",
		["daily.streak"] = "Day %d streak",
		["daily.claim"] = "Claim",
		["daily.come_back"] = "Come back in %s",

		-- Offline earnings
		["offline.title"] = "Welcome back!",
		["offline.summary"] = "You earned $%s while away.",

		-- Settings
		["settings.title"] = "Settings",
		["settings.audio"] = "Audio",
		["settings.audio.music"] = "Music",
		["settings.audio.sfx"] = "Sound effects",
		["settings.locale"] = "Language",
		["settings.privacy"] = "Privacy notice",
		["settings.terms"] = "Terms of use",

		-- Leaderboard
		["leaderboard.title"] = "Top Reefs",
		["leaderboard.empty"] = "No data yet — check back soon.",

		-- Generic
		["common.close"] = "Close",
		["common.confirm"] = "Confirm",
		["common.cancel"] = "Cancel",
		["common.error"] = "Something went wrong.",
	},
}

local currentLocale = "en-US"

function Strings.setLocale(locale: string)
	if SUPPORTED[locale] then
		currentLocale = locale
	else
		warn(("[Strings] unsupported locale %s, falling back to en-US"):format(locale))
		currentLocale = "en-US"
	end
end

function Strings.getLocale(): string
	return currentLocale
end

function Strings.supportedLocales(): { string }
	local list = {}
	for k in SUPPORTED do
		table.insert(list, k)
	end
	table.sort(list)
	return list
end

function Strings.get(key: string, ...: any): string
	local table_ = TABLES[currentLocale] or TABLES["en-US"]
	local raw = table_[key]
	if not raw then
		raw = (TABLES["en-US"] :: any)[key]
	end
	if not raw then
		return key
	end
	if select("#", ...) == 0 then
		return raw
	end
	return string.format(raw, ...)
end

return Strings
