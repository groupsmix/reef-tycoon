--!strict
--[[
	MonetizationService — gamepass + dev product fulfillment.

	On a successful dev product purchase, MarketplaceService.ProcessReceipt
	must return PurchaseGranted. We grant the effect first, save, THEN
	return — that way a server crash mid-grant still re-runs the
	fulfillment next session.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local GamepassData = require(Shared:WaitForChild("GamepassData"))
local DevProductData = require(Shared:WaitForChild("DevProductData"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local GachaService = require(script.Parent:WaitForChild("GachaService"))

local MonetizationService = {}

local function applyDevProductEffect(player: Player, effectId: string): boolean
	local product = DevProductData.Products[effectId]
	if not product then
		return false
	end
	if product.effect.gems then
		EconomyService.GrantGems(player, product.effect.gems, "dp:" .. effectId)
	end
	if product.effect.mythicEgg then
		GachaService.RollEgg(player, { force = "Mythic", free = true })
	end
	if product.effect.eventPass then
		local profile = DataService.GetProfile(player)
		if profile then
			profile.gamepasses.EVENT_PASS = true
			DataService.MarkChanged(player)
		end
	end
	return true
end

local function findDevProductByProductId(productId: number): string?
	for id, p in DevProductData.Products do
		if p.productId() == productId then
			return id
		end
	end
	return nil
end

local function findGamepassByProductId(productId: number): string?
	for id, p in GamepassData.Passes do
		if p.productId() == productId then
			return id
		end
	end
	return nil
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.WaitForProfile(player, 5)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Idempotency: if Roblox replays a receipt we've already granted (e.g.
	-- the previous server crashed mid-grant), short-circuit. processedReceipts
	-- is persisted to the profile, so this survives across server hops.
	local receiptId = tostring(receiptInfo.PurchaseId)
	if profile.processedReceipts[receiptId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local effectId = findDevProductByProductId(receiptInfo.ProductId)
	if not effectId then
		warn(("[Monetization] unknown ProductId %s"):format(tostring(receiptInfo.ProductId)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok = applyDevProductEffect(player, effectId)
	if ok then
		profile.processedReceipts[receiptId] = os.time()
		DataService.MarkChanged(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function refreshGamepasses(player: Player)
	local profile = DataService.WaitForProfile(player, 5)
	if not profile then
		return
	end
	for id, meta in GamepassData.Passes do
		local pid = meta.productId()
		if pid == 0 then
			continue
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pid)
		end)
		if ok and owns then
			profile.gamepasses[id] = true
		end
	end
	-- VIP grants extra tank slots
	if profile.gamepasses.EXTRA_TANK_SLOTS then
		profile.tankSlots = math.max(profile.tankSlots, Config.STARTING_TANK_SLOTS + 10)
	end
	DataService.MarkChanged(player)
end

-- Test-only seam.
function MonetizationService._processReceipt(receiptInfo)
	return processReceipt(receiptInfo)
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if not wasPurchased then
			return
		end
		local id = findGamepassByProductId(gamepassId)
		if not id then
			return
		end
		local profile = DataService.GetProfile(player)
		if not profile then
			return
		end
		profile.gamepasses[id] = true
		if id == "EXTRA_TANK_SLOTS" then
			profile.tankSlots = math.max(profile.tankSlots, Config.STARTING_TANK_SLOTS + 10)
		end
		DataService.MarkChanged(player)
	end)

	Players.PlayerAdded:Connect(refreshGamepasses)
	for _, p in Players:GetPlayers() do
		task.spawn(refreshGamepasses, p)
	end
end

function MonetizationService.Start() end

return MonetizationService
