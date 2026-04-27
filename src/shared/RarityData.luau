--!strict
--[[
	RarityData — 6 rarity tiers, drop rates, and tip multipliers.

	The `weight` field is the gacha drop rate in basis points (10000 = 100%).
	Total must equal 10000.

	`tipMultiplier` follows tierIndex^2.5 to make Legendary tips ~178× a Common.
]]

export type Rarity = {
	id: string,
	name: string,
	tierIndex: number,
	weight: number,
	tipMultiplier: number,
	color: Color3,
	pullEffect: string,
}

local RarityData: { [string]: Rarity } = {
	Common = {
		id = "Common",
		name = "Common",
		tierIndex = 1,
		weight = 4500,
		tipMultiplier = 1.0,
		color = Color3.fromRGB(170, 170, 170),
		pullEffect = "fade",
	},
	Uncommon = {
		id = "Uncommon",
		name = "Uncommon",
		tierIndex = 2,
		weight = 2800,
		tipMultiplier = 5.66, -- 2^2.5
		color = Color3.fromRGB(80, 200, 100),
		pullEffect = "glow",
	},
	Rare = {
		id = "Rare",
		name = "Rare",
		tierIndex = 3,
		weight = 1500,
		tipMultiplier = 15.59, -- 3^2.5
		color = Color3.fromRGB(75, 150, 255),
		pullEffect = "beam",
	},
	Epic = {
		id = "Epic",
		name = "Epic",
		tierIndex = 4,
		weight = 800,
		tipMultiplier = 32.0, -- 4^2.5
		color = Color3.fromRGB(180, 90, 240),
		pullEffect = "particles",
	},
	Mythic = {
		id = "Mythic",
		name = "Mythic",
		tierIndex = 5,
		weight = 300,
		tipMultiplier = 55.9, -- 5^2.5
		color = Color3.fromRGB(255, 195, 60),
		pullEffect = "lightning",
	},
	Legendary = {
		id = "Legendary",
		name = "Legendary",
		tierIndex = 6,
		weight = 100,
		tipMultiplier = 88.18, -- 6^2.5
		color = Color3.fromRGB(255, 120, 220),
		pullEffect = "cinematic",
	},
}

-- Convenience: ordered list low→high.
local Order = { "Common", "Uncommon", "Rare", "Epic", "Mythic", "Legendary" }

return {
	Rarities = RarityData,
	Order = Order,
}
