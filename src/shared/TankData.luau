--!strict
--[[
	TankData — 5 tank tiers with cost / capacity / multiplier curves.
]]

export type Tank = {
	id: string,
	name: string,
	tierIndex: number,
	cost: number,
	visitorCapacity: number,
	tipMultiplier: number,
	slotCapacity: number,
	primaryColor: Color3,
}

local Tanks: { [string]: Tank } = {
	STARTER = {
		id = "STARTER",
		name = "Starter Tank",
		tierIndex = 1,
		cost = 100,
		visitorCapacity = 1,
		tipMultiplier = 1.0,
		slotCapacity = 1,
		primaryColor = Color3.fromRGB(180, 200, 220),
	},
	PREMIUM = {
		id = "PREMIUM",
		name = "Premium Tank",
		tierIndex = 2,
		cost = 2_500,
		visitorCapacity = 3,
		tipMultiplier = 1.5,
		slotCapacity = 3,
		primaryColor = Color3.fromRGB(150, 200, 255),
	},
	LUXURY = {
		id = "LUXURY",
		name = "Luxury Tank",
		tierIndex = 3,
		cost = 50_000,
		visitorCapacity = 8,
		tipMultiplier = 2.5,
		slotCapacity = 6,
		primaryColor = Color3.fromRGB(100, 220, 220),
	},
	MYTHIC_TANK = {
		id = "MYTHIC_TANK",
		name = "Mythic Tank",
		tierIndex = 4,
		cost = 1_000_000,
		visitorCapacity = 20,
		tipMultiplier = 5.0,
		slotCapacity = 10,
		primaryColor = Color3.fromRGB(255, 200, 60),
	},
	REEF_GOD = {
		id = "REEF_GOD",
		name = "Reef God Tank",
		tierIndex = 5,
		cost = 25_000_000,
		visitorCapacity = 50,
		tipMultiplier = 10.0,
		slotCapacity = 20,
		primaryColor = Color3.fromRGB(255, 130, 230),
	},
}

local Order = { "STARTER", "PREMIUM", "LUXURY", "MYTHIC_TANK", "REEF_GOD" }

return {
	Tanks = Tanks,
	Order = Order,
}
