--!strict
--[[
	TankService — buy / place / remove tanks, and assign fish to them.

	All mutations route through here so we only have one place to enforce
	invariants (slot caps, ownership, capacity).
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TankData = require(Shared:WaitForChild("TankData"))
local FishData = require(Shared:WaitForChild("FishData"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Util"):WaitForChild("Validate"))
local AntiCheatService = require(script.Parent:WaitForChild("AntiCheatService"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))

local TankService = {}

local function pedestalAvailable(profile, pedestalIndex: number): boolean
	if pedestalIndex < 1 or pedestalIndex > profile.tankSlots then
		return false
	end
	for _, t in profile.placedTanks do
		if t.pedestalIndex == pedestalIndex then
			return false
		end
	end
	return true
end

function TankService.Place(player: Player, tankId: string, pedestalIndex: number): boolean
	local meta = TankData.Tanks[tankId]
	if not meta then
		return false
	end
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	if not pedestalAvailable(profile, pedestalIndex) then
		return false
	end
	if not EconomyService.SpendCash(player, meta.cost, "tank:place:" .. tankId) then
		return false
	end
	table.insert(profile.placedTanks, {
		tankId = tankId,
		pedestalIndex = pedestalIndex,
		fish = {},
	})
	DataService.MarkChanged(player)
	QuestService.Track(player, "tanks_placed", 1)
	return true
end

function TankService.Remove(player: Player, pedestalIndex: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	for i, t in profile.placedTanks do
		if t.pedestalIndex == pedestalIndex then
			-- Return assigned fish to inventory (no refund of tank cost).
			for _, fishId in t.fish do
				local stack = profile.inventory[fishId]
				if stack then
					stack.count += 1
				else
					profile.inventory[fishId] = {
						id = fishId,
						count = 1,
						firstObtained = os.time(),
					}
				end
			end
			table.remove(profile.placedTanks, i)
			DataService.MarkChanged(player)
			return true
		end
	end
	return false
end

function TankService.AssignFish(player: Player, pedestalIndex: number, fishId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	local fishMeta = FishData.getById(fishId)
	if not fishMeta then
		return false
	end
	local placed
	for _, t in profile.placedTanks do
		if t.pedestalIndex == pedestalIndex then
			placed = t
			break
		end
	end
	if not placed then
		return false
	end
	local tankMeta = TankData.Tanks[placed.tankId]
	if not tankMeta then
		return false
	end
	if #placed.fish >= tankMeta.slotCapacity then
		return false
	end
	local stack = profile.inventory[fishId]
	if not stack or stack.count <= 0 then
		return false
	end
	stack.count -= 1
	if stack.count <= 0 then
		profile.inventory[fishId] = nil
	end
	table.insert(placed.fish, fishId)
	DataService.MarkChanged(player)
	return true
end

function TankService.UnassignFish(player: Player, pedestalIndex: number, slotIndex: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	for _, t in profile.placedTanks do
		if t.pedestalIndex == pedestalIndex then
			local fishId = t.fish[slotIndex]
			if not fishId then
				return false
			end
			table.remove(t.fish, slotIndex)
			local stack = profile.inventory[fishId]
			if stack then
				stack.count += 1
			else
				profile.inventory[fishId] = {
					id = fishId,
					count = 1,
					firstObtained = os.time(),
				}
			end
			DataService.MarkChanged(player)
			return true
		end
	end
	return false
end

function TankService.Init()
	local r = Remotes.Server()
	local banned = AntiCheatService.IsBanned

	r.Functions.PlaceTank.OnServerInvoke = Validate.wrap({ "string", "number" }, function(player, tankId, pedestalIndex)
		return TankService.Place(player, tankId, pedestalIndex)
	end, banned)

	r.Functions.RemoveTank.OnServerInvoke = Validate.wrap({ "number" }, function(player, pedestalIndex)
		return TankService.Remove(player, pedestalIndex)
	end, banned)

	r.Functions.AssignFishToTank.OnServerInvoke = Validate.wrap(
		{ "number", "string" },
		function(player, pedestalIndex, fishId)
			return TankService.AssignFish(player, pedestalIndex, fishId)
		end,
		banned
	)

	r.Functions.UnassignFishFromTank.OnServerInvoke = Validate.wrap(
		{ "number", "number" },
		function(player, pedestalIndex, slotIndex)
			return TankService.UnassignFish(player, pedestalIndex, slotIndex)
		end,
		banned
	)

	-- Reference Config so it doesn't drift unused
	local _ = Config.MAX_TANK_SLOTS
end

function TankService.Start() end

return TankService
