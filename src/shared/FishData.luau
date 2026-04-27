--!strict
--[[
	FishData — 30 species (5 per rarity tier).

	`meshAssetId` is left at 0 — fill in after generating each fish via Cube 4D.
	The game runs without meshes (it falls back to a colored bubble) so you can
	playtest before art is finished.
]]

export type Fish = {
	id: string,
	name: string,
	rarity: string,
	meshAssetId: number,
	primaryColor: Color3,
	description: string,
}

local Fish: { [string]: Fish } = {
	-- ──────────── Common ────────────
	REEF_TETRA = {
		id = "REEF_TETRA",
		name = "Reef Tetra",
		rarity = "Common",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 140, 60),
		description = "A tireless workhorse of the starter reef.",
	},
	SAND_GOBY = {
		id = "SAND_GOBY",
		name = "Sand Goby",
		rarity = "Common",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(220, 200, 130),
		description = "Loves to burrow. Visitors find it cute.",
	},
	GLOW_GUPPY = {
		id = "GLOW_GUPPY",
		name = "Glow Guppy",
		rarity = "Common",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(120, 220, 255),
		description = "A faint shimmer from its tail.",
	},
	CORAL_DAMSEL = {
		id = "CORAL_DAMSEL",
		name = "Coral Damsel",
		rarity = "Common",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 90, 130),
		description = "Aggressive but pretty.",
	},
	PEBBLE_WRASSE = {
		id = "PEBBLE_WRASSE",
		name = "Pebble Wrasse",
		rarity = "Common",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(140, 160, 180),
		description = "Cleans the tank gravel free of charge.",
	},

	-- ──────────── Uncommon ────────────
	LANTERN_TANG = {
		id = "LANTERN_TANG",
		name = "Lantern Tang",
		rarity = "Uncommon",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 200, 90),
		description = "Glows during evening hours.",
	},
	DAWN_CARDINAL = {
		id = "DAWN_CARDINAL",
		name = "Dawn Cardinal",
		rarity = "Uncommon",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 140, 160),
		description = "First to wake, last to sleep.",
	},
	MOSS_PLECO = {
		id = "MOSS_PLECO",
		name = "Moss Pleco",
		rarity = "Uncommon",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(80, 130, 70),
		description = "A walking algae filter.",
	},
	SUNSET_ANTHIAS = {
		id = "SUNSET_ANTHIAS",
		name = "Sunset Anthias",
		rarity = "Uncommon",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 110, 80),
		description = "Gradient orange-to-purple flank.",
	},
	WHISPER_BLENNY = {
		id = "WHISPER_BLENNY",
		name = "Whisper Blenny",
		rarity = "Uncommon",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(150, 200, 220),
		description = "Bobs gently from rock to rock.",
	},

	-- ──────────── Rare ────────────
	GLASS_LIONFISH = {
		id = "GLASS_LIONFISH",
		name = "Glass Lionfish",
		rarity = "Rare",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(220, 220, 250),
		description = "Translucent fins. Visitors gawk.",
	},
	EMBER_SURGEON = {
		id = "EMBER_SURGEON",
		name = "Ember Surgeon",
		rarity = "Rare",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 90, 50),
		description = "Hot orange. Hot tips.",
	},
	VELVET_MANDARIN = {
		id = "VELVET_MANDARIN",
		name = "Velvet Mandarin",
		rarity = "Rare",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(70, 100, 230),
		description = "Velvet-soft swimming pattern.",
	},
	SABER_TANG = {
		id = "SABER_TANG",
		name = "Saber Tang",
		rarity = "Rare",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(220, 220, 60),
		description = "Sharp tail, sharp profits.",
	},
	CHROME_TRIGGERFISH = {
		id = "CHROME_TRIGGERFISH",
		name = "Chrome Triggerfish",
		rarity = "Rare",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(200, 220, 240),
		description = "Mirror finish.",
	},

	-- ──────────── Epic ────────────
	AURORA_BOXFISH = {
		id = "AURORA_BOXFISH",
		name = "Aurora Boxfish",
		rarity = "Epic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(120, 220, 200),
		description = "Cube-shaped. Walking screensaver.",
	},
	FROSTFIN_GROUPER = {
		id = "FROSTFIN_GROUPER",
		name = "Frostfin Grouper",
		rarity = "Epic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(180, 220, 255),
		description = "Leaves a trail of cold mist.",
	},
	STORMCOAT_EEL = {
		id = "STORMCOAT_EEL",
		name = "Stormcoat Eel",
		rarity = "Epic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(80, 90, 200),
		description = "Crackling skin.",
	},
	TWILIGHT_SEAHORSE = {
		id = "TWILIGHT_SEAHORSE",
		name = "Twilight Seahorse",
		rarity = "Epic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(160, 100, 220),
		description = "Pulses purple in the dark.",
	},
	PRISM_WRASSE = {
		id = "PRISM_WRASSE",
		name = "Prism Wrasse",
		rarity = "Epic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 200, 240),
		description = "Refracts every light source.",
	},

	-- ──────────── Mythic ────────────
	GLASS_LEVIATHAN = {
		id = "GLASS_LEVIATHAN",
		name = "Glass Leviathan",
		rarity = "Mythic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(230, 250, 255),
		description = "A see-through giant. The reason TikTok knows your game.",
	},
	MAGMA_MANTA = {
		id = "MAGMA_MANTA",
		name = "Magma Manta",
		rarity = "Mythic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 70, 30),
		description = "Glides on heat currents.",
	},
	ASTRAL_OCTOPUS = {
		id = "ASTRAL_OCTOPUS",
		name = "Astral Octopus",
		rarity = "Mythic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(80, 60, 200),
		description = "Tentacles trace constellations.",
	},
	BLOOM_JELLYFISH = {
		id = "BLOOM_JELLYFISH",
		name = "Bloom Jellyfish",
		rarity = "Mythic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 130, 230),
		description = "Pulses in slow rainbows.",
	},
	HALO_ANGELSHARK = {
		id = "HALO_ANGELSHARK",
		name = "Halo Angelshark",
		rarity = "Mythic",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 230, 130),
		description = "Visitors stop to take photos.",
	},

	-- ──────────── Legendary ────────────
	REEF_GOD_KOI = {
		id = "REEF_GOD_KOI",
		name = "Reef God Koi",
		rarity = "Legendary",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 180, 100),
		description = "Server-wide announce on pull.",
	},
	ECLIPSE_DRAGON = {
		id = "ECLIPSE_DRAGON",
		name = "Eclipse Dragonfish",
		rarity = "Legendary",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(40, 30, 70),
		description = "The water dims when it swims past.",
	},
	AURORA_PHOENIXFISH = {
		id = "AURORA_PHOENIXFISH",
		name = "Aurora Phoenixfish",
		rarity = "Legendary",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(255, 100, 60),
		description = "Resets to fry once a year. Same flame.",
	},
	TIDESHAPER_WHALE = {
		id = "TIDESHAPER_WHALE",
		name = "Tideshaper Whale",
		rarity = "Legendary",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(80, 130, 200),
		description = "Bends the current to its mood.",
	},
	CRYSTAL_KRAKENFISH = {
		id = "CRYSTAL_KRAKENFISH",
		name = "Crystal Krakenfish",
		rarity = "Legendary",
		meshAssetId = 0,
		primaryColor = Color3.fromRGB(180, 240, 255),
		description = "Eight crystalline arms, each refracts light differently.",
	},
}

-- Build a fast lookup of fish ids per rarity.
local ByRarity: { [string]: { string } } = {}
for id, fish in Fish do
	if not ByRarity[fish.rarity] then
		ByRarity[fish.rarity] = {}
	end
	table.insert(ByRarity[fish.rarity], id)
end

local function getById(id: string): Fish?
	return Fish[id]
end

return {
	Fish = Fish,
	ByRarity = ByRarity,
	getById = getById,
}
