--!strict
--[[
	ShopController — opens with a button on the right. Tabs: Tanks,
	Gamepasses, Gem Bundles. Buying a tank prompts the user for a
	pedestal index (UI placeholder — replace with click-to-place when
	the lobby is built).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopController = {}

local function makeButton(parent, text, y)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 40)
	btn.Position = UDim2.new(0, 8, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	return btn
end

local function makeTabFrame(parent, name)
	local f = Instance.new("ScrollingFrame")
	f.Name = name
	f.Size = UDim2.new(1, 0, 1, -56)
	f.Position = UDim2.new(0, 0, 0, 56)
	f.BackgroundTransparency = 1
	f.CanvasSize = UDim2.fromScale(0, 0)
	f.AutomaticCanvasSize = Enum.AutomaticSize.Y
	f.ScrollBarThickness = 4
	f.Visible = false
	f.Parent = parent
	return f
end

function ShopController.Mount(screen: ScreenGui, State)
	local toggle = Instance.new("TextButton")
	toggle.Name = "ShopToggle"
	toggle.AnchorPoint = Vector2.new(1, 0.5)
	toggle.Position = UDim2.new(1, -12, 0.5, -120)
	toggle.Size = UDim2.new(0, 84, 0, 84)
	toggle.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
	toggle.Text = "SHOP"
	toggle.Font = Enum.Font.GothamBlack
	toggle.TextSize = 18
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = toggle

	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -110, 0.5, 0)
	panel.Size = UDim2.new(0, 360, 0, 480)
	panel.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
	panel.Visible = false
	panel.Parent = screen
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 12)
	corner2.Parent = panel

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, 0, 0, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel

	local tankTab = makeTabFrame(panel, "Tanks")
	local gemsTab = makeTabFrame(panel, "Gems")
	local passesTab = makeTabFrame(panel, "Passes")

	local function showTab(which)
		tankTab.Visible = which == "Tanks"
		gemsTab.Visible = which == "Gems"
		passesTab.Visible = which == "Passes"
	end

	local tabs = { "Tanks", "Gems", "Passes" }
	for i, name in tabs do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1 / #tabs, -8, 1, -8)
		b.Position = UDim2.new((i - 1) / #tabs, 4, 0, 4)
		b.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = name
		b.Parent = tabBar
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b
		b.MouseButton1Click:Connect(function()
			showTab(name)
		end)
	end

	local layoutTanks = Instance.new("UIListLayout")
	layoutTanks.Padding = UDim.new(0, 6)
	layoutTanks.Parent = tankTab
	local layoutGems = Instance.new("UIListLayout")
	layoutGems.Padding = UDim.new(0, 6)
	layoutGems.Parent = gemsTab
	local layoutPasses = Instance.new("UIListLayout")
	layoutPasses.Padding = UDim.new(0, 6)
	layoutPasses.Parent = passesTab

	-- Render tank list
	for _, id in State.catalog.tankOrder do
		local t = State.catalog.tanks[id]
		local b = makeButton(tankTab, ("%s — $%d"):format(t.name, t.cost), 0)
		b.LayoutOrder = t.tierIndex
		b.MouseButton1Click:Connect(function()
			-- Demo flow: place at the next free pedestal index 1..tankSlots.
			local snap = State.snapshot
			if not snap then
				return
			end
			local taken = {}
			for _, placed in snap.placedTanks do
				taken[placed.pedestalIndex] = true
			end
			for idx = 1, snap.tankSlots do
				if not taken[idx] then
					Remotes.Client().Functions.PlaceTank:InvokeServer(id, idx)
					return
				end
			end
		end)
	end

	-- Render dev products (gems)
	for _, id in State.catalog.devProductOrder do
		local p = State.catalog.devProducts[id]
		local b = makeButton(gemsTab, ("%s — %d R$"):format(p.name, p.priceRobux), 0)
		b.LayoutOrder = p.priceRobux
		b.MouseButton1Click:Connect(function()
			if p.productId == 0 then
				warn("Dev product id is unset; configure Config.DEV_PRODUCT_IDS")
				return
			end
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, p.productId)
		end)
	end

	-- Render gamepasses
	for _, id in State.catalog.gamepassOrder do
		local g = State.catalog.gamepasses[id]
		local b = makeButton(passesTab, ("%s — %d R$"):format(g.name, g.priceRobux), 0)
		b.LayoutOrder = g.priceRobux
		b.MouseButton1Click:Connect(function()
			if g.productId == 0 then
				warn("Gamepass id is unset; configure Config.GAMEPASS_IDS")
				return
			end
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, g.productId)
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			showTab("Tanks")
		end
	end)
end

return ShopController
