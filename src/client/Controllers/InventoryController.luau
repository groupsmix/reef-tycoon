--!strict
--[[
	InventoryController — list of owned fish, sorted by rarity desc and
	name asc. Click a fish to assign it to the next free tank slot.

	The renderer is naïve (rebuilds on every snapshot). Fast enough for
	30 species; revisit if we go past a few hundred.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local InventoryController = {}

local RARITY_INDEX = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Mythic = 5,
	Legendary = 6,
}

function InventoryController.Mount(screen: ScreenGui, State)
	local toggle = Instance.new("TextButton")
	toggle.Name = "InventoryToggle"
	toggle.AnchorPoint = Vector2.new(1, 0.5)
	toggle.Position = UDim2.new(1, -12, 0.5, -20)
	toggle.Size = UDim2.fromOffset(72, 72)
	toggle.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	toggle.Text = "FISH"
	toggle.Font = Enum.Font.GothamBlack
	toggle.TextSize = 18
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Parent = screen
	local c1 = Instance.new("UICorner")
	c1.CornerRadius = UDim.new(0, 12)
	c1.Parent = toggle

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -110, 0.5, 0)
	panel.Size = UDim2.new(0.4, 0, 0.7, 0)
	panel.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
	panel.Visible = false
	panel.Parent = screen
	local sizeCap = Instance.new("UISizeConstraint")
	sizeCap.MinSize = Vector2.new(280, 360)
	sizeCap.MaxSize = Vector2.new(420, 540)
	sizeCap.Parent = panel
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 12)
	c2.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 36)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.Text = "My Reef"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -16, 1, -44)
	list.Position = UDim2.new(0, 8, 0, 40)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.new(0, 6, 0, 6)
	layout.CellSize = UDim2.new(0, 100, 0, 100)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function rebuild(snapshot)
		list:ClearAllChildren()
		layout.Parent = list
		if not snapshot then
			return
		end
		local items = {}
		for fishId, stack in snapshot.inventory do
			local fish = State.catalog.fish[fishId]
			if fish then
				table.insert(items, { id = fishId, count = stack.count, fish = fish })
			end
		end
		table.sort(items, function(a, b)
			local ai = RARITY_INDEX[a.fish.rarity] or 0
			local bi = RARITY_INDEX[b.fish.rarity] or 0
			if ai ~= bi then
				return ai > bi
			end
			return a.fish.name < b.fish.name
		end)
		for i, item in items do
			local card = Instance.new("TextButton")
			card.LayoutOrder = i
			card.BackgroundColor3 = Color3.fromRGB(35, 50, 70)
			card.AutoButtonColor = true
			card.Text = ""
			card.Parent = list
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(0, 8)
			cc.Parent = card

			local stroke = Instance.new("UIStroke")
			local rar = State.catalog.rarities[item.fish.rarity]
			if rar then
				stroke.Color = Color3.new(rar.color[1], rar.color[2], rar.color[3])
			end
			stroke.Thickness = 2
			stroke.Parent = card

			local nameLbl = Instance.new("TextLabel")
			nameLbl.BackgroundTransparency = 1
			nameLbl.Size = UDim2.new(1, -4, 0, 36)
			nameLbl.Position = UDim2.new(0, 2, 1, -56)
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 11
			nameLbl.TextWrapped = true
			nameLbl.TextColor3 = Color3.new(1, 1, 1)
			nameLbl.Text = item.fish.name
			nameLbl.Parent = card

			local countLbl = Instance.new("TextLabel")
			countLbl.BackgroundTransparency = 1
			countLbl.Size = UDim2.new(0, 36, 0, 22)
			countLbl.Position = UDim2.new(1, -38, 0, 4)
			countLbl.Font = Enum.Font.GothamBlack
			countLbl.TextSize = 14
			countLbl.TextColor3 = Color3.new(1, 1, 1)
			countLbl.Text = "x" .. item.count
			countLbl.Parent = card

			card.MouseButton1Click:Connect(function()
				-- Auto-assign to first tank with capacity.
				local snap = State.snapshot
				if not snap then
					return
				end
				for _, placed in snap.placedTanks do
					local tank = State.catalog.tanks[placed.tankId]
					if tank and #placed.fish < tank.slotCapacity then
						Remotes.Client().Functions.AssignFishToTank:InvokeServer(placed.pedestalIndex, item.id)
						return
					end
				end
			end)
		end
	end

	rebuild(State.snapshot)
	State.SnapshotChanged:Connect(rebuild)

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return InventoryController
