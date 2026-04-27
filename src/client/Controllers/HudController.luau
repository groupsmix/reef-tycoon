--!strict
--[[
	HudController — top-bar HUD: cash, gems, prestige level, tank slots.

	Listens to `State.SnapshotChanged` and rebinds labels.
]]

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

local function label(parent, text, x, color)
	local frame = Instance.new("Frame")
	frame.Name = text
	frame.Size = UDim2.new(0, 160, 0, 36)
	frame.Position = UDim2.new(0, x, 0, 0)
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
	valLbl.Parent = frame

	return valLbl
end

function HudController.Mount(screen: ScreenGui, State)
	local root = Instance.new("Frame")
	root.Name = "Hud"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, 8)
	root.Size = UDim2.new(0, 720, 0, 36)
	root.BackgroundTransparency = 1
	root.Parent = screen

	local cash = label(root, "Cash", 0, Color3.fromRGB(120, 220, 120))
	local gems = label(root, "Gems", 180, Color3.fromRGB(120, 200, 255))
	local prestige = label(root, "Prestige", 360, Color3.fromRGB(255, 195, 60))
	local slots = label(root, "Slots", 540, Color3.fromRGB(220, 220, 220))

	local function render(snapshot)
		if not snapshot then
			return
		end
		cash.Text = "$ " .. fmt(snapshot.cash)
		gems.Text = "💎 " .. fmt(snapshot.gems)
		prestige.Text = "★ " .. snapshot.prestigeLevel
		slots.Text = "Slots " .. #snapshot.placedTanks .. "/" .. snapshot.tankSlots
	end

	render(State.snapshot)
	State.SnapshotChanged:Connect(render)
end

return HudController
