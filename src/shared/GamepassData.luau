--!strict
--[[
	GamepassData — declarative metadata for the 5 launch gamepasses.

	IDs come from `Config.GAMEPASS_IDS` (set those after creating the passes
	in the Creator Hub). Effects are applied in MonetizationService.
]]

local Config = require(script.Parent.Config)

export type GamepassMeta = {
	id: string,
	name: string,
	priceRobux: number,
	icon: string,
	description: string,
	productId: () -> number,
}

local Passes: { [string]: GamepassMeta } = {
	DOUBLE_TIPS = {
		id = "DOUBLE_TIPS",
		name = "2× Tips Forever",
		priceRobux = 499,
		icon = "rbxassetid://0",
		description = "Permanently doubles the tips you earn from visitors.",
		productId = function()
			return Config.GAMEPASS_IDS.DOUBLE_TIPS
		end,
	},
	AUTO_COLLECT = {
		id = "AUTO_COLLECT",
		name = "Auto-Collect Tips",
		priceRobux = 299,
		icon = "rbxassetid://0",
		description = "Tips drop straight into your wallet — no clicking.",
		productId = function()
			return Config.GAMEPASS_IDS.AUTO_COLLECT
		end,
	},
	VIP = {
		id = "VIP",
		name = "VIP",
		priceRobux = 999,
		icon = "rbxassetid://0",
		description = "Badge, chat tag, and an exclusive cosmetic fish.",
		productId = function()
			return Config.GAMEPASS_IDS.VIP
		end,
	},
	TRIPLE_LUCK = {
		id = "TRIPLE_LUCK",
		name = "3× Luck on Eggs",
		priceRobux = 799,
		icon = "rbxassetid://0",
		description = "3× the odds of high-rarity rolls.",
		productId = function()
			return Config.GAMEPASS_IDS.TRIPLE_LUCK
		end,
	},
	EXTRA_TANK_SLOTS = {
		id = "EXTRA_TANK_SLOTS",
		name = "+10 Tank Slots",
		priceRobux = 399,
		icon = "rbxassetid://0",
		description = "Adds 10 placement slots to your reef.",
		productId = function()
			return Config.GAMEPASS_IDS.EXTRA_TANK_SLOTS
		end,
	},
}

local Order = { "DOUBLE_TIPS", "AUTO_COLLECT", "VIP", "TRIPLE_LUCK", "EXTRA_TANK_SLOTS" }

return {
	Passes = Passes,
	Order = Order,
}
