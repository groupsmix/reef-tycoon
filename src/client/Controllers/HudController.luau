--!strict
--[[
	HudController — top-bar HUD: cash, gems, prestige level, tank slots.

	Listens to `State.SnapshotChanged` and rebinds labels.

	Mobile UI: laid out with UIListLayout so the row reflows on narrow
	devices instead of overflowing past 720px. The HUD is anchored at
	the top-center with a 44px offset to clear the Roblox top bar (we
	have IgnoreGuiInset = true on the parent ScreenGui, so we own that
	space). Each chip is at least 44 px tall so it meets the mobile
	tap-target minimum.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local HudController = {}

local function fmt(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.2fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.2fM", n / 1_000_000)
	elseif n >= 10_000 then
		return string.format("%.1fK", n / 1_000)
	else
		return tostring(math.floor(n))
	end
end

local function chip(parent: Instance, name: string, color: Color3): TextLabel
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.LayoutOrder = ({ Cash = 1, Gems = 2, Prestige = 3, Slots = 4 })[name] or 99
	frame.Size = UDim2.fromOffset(150, 44)
	frame.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.fromScale(1, 1)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Text = "0"
	valLbl.TextColor3 = color
	valLbl.TextSize = 18
	valLbl.TextScaled = false
	valLbl.Parent = frame

	return valLbl
end

function HudController.Mount(screen: ScreenGui, State)
	local root = Instance.new("Frame")
	root.Name = "Hud"
	root.AnchorPoint = Vector2.new(0.5, 0)
	-- 44px offset clears the Roblox top bar even with IgnoreGuiInset.
	root.Position = UDim2.new(0.5, 0, 0, 44)
	-- Width grows with content; capped to ~95% of the screen on narrow
	-- devices via the UISizeConstraint below so there's always margin.
	root.AutomaticSize = Enum.AutomaticSize.X
	root.Size = UDim2.new(0, 0, 0, 44)
	root.BackgroundTransparency = 1
	root.Parent = screen

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local sizeCap = Instance.new("UISizeConstraint")
	sizeCap.MaxSize = Vector2.new(900, 44)
	sizeCap.Parent = root

	local cash = chip(root, "Cash", Color3.fromRGB(120, 220, 120))
	local gems = chip(root, "Gems", Color3.fromRGB(120, 200, 255))
	local prestige = chip(root, "Prestige", Color3.fromRGB(255, 195, 60))
	local slots = chip(root, "Slots", Color3.fromRGB(220, 220, 220))

	local function render(snapshot)
		if not snapshot then
			return
		end
		cash.Text = Strings.get("hud.cash") .. " " .. fmt(snapshot.cash)
		gems.Text = Strings.get("hud.gems") .. " " .. fmt(snapshot.gems)
		prestige.Text = Strings.get("hud.prestige") .. " " .. snapshot.prestigeLevel
		slots.Text = Strings.get("hud.slots") .. " " .. #snapshot.placedTanks .. "/" .. snapshot.tankSlots
	end

	render(State.snapshot)
	State.SnapshotChanged:Connect(render)
end

return HudController
