--!strict
--[[
	DevProductData — consumable products. Real revenue is here.

	Effect functions return a table the MonetizationService applies to the
	player's profile when fulfillment succeeds.
]]

local Config = require(script.Parent.Config)

export type DevProductEffect = {
	gems: number?,
	mythicEgg: boolean?,
	eventPass: boolean?,
}

export type DevProductMeta = {
	id: string,
	name: string,
	priceRobux: number,
	icon: string,
	productId: () -> number,
	effect: DevProductEffect,
}

local Products: { [string]: DevProductMeta } = {
	GEMS_1K = {
		id = "GEMS_1K",
		name = "1,000 Gems",
		priceRobux = 99,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.GEMS_1K
		end,
		effect = { gems = 1_000 },
	},
	GEMS_5_5K = {
		id = "GEMS_5_5K",
		name = "5,500 Gems",
		priceRobux = 499,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.GEMS_5_5K
		end,
		effect = { gems = 5_500 },
	},
	GEMS_12K = {
		id = "GEMS_12K",
		name = "12,000 Gems",
		priceRobux = 999,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.GEMS_12K
		end,
		effect = { gems = 12_000 },
	},
	GEMS_30K = {
		id = "GEMS_30K",
		name = "30,000 Gems",
		priceRobux = 2_499,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.GEMS_30K
		end,
		effect = { gems = 30_000 },
	},
	GEMS_75K = {
		id = "GEMS_75K",
		name = "75,000 Gems",
		priceRobux = 4_999,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.GEMS_75K
		end,
		effect = { gems = 75_000 },
	},
	MYTHIC_EGG = {
		id = "MYTHIC_EGG",
		name = "Single Mythic Egg",
		priceRobux = 1_499,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.MYTHIC_EGG
		end,
		effect = { mythicEgg = true },
	},
	EVENT_PASS = {
		id = "EVENT_PASS",
		name = "Event Pass",
		priceRobux = 799,
		icon = "rbxassetid://0",
		productId = function()
			return Config.DEV_PRODUCT_IDS.EVENT_PASS
		end,
		effect = { eventPass = true },
	},
}

local Order = { "GEMS_1K", "GEMS_5_5K", "GEMS_12K", "GEMS_30K", "GEMS_75K", "MYTHIC_EGG", "EVENT_PASS" }

return {
	Products = Products,
	Order = Order,
}
