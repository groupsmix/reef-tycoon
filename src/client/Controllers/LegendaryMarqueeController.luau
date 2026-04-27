--!strict
--[[
	LegendaryMarqueeController — server-wide announcement banner that
	slides across the top of every player's screen when someone in the
	server pulls a Legendary fish. Pure FOMO/social proof feature.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local LegendaryMarqueeController = {}

local queue: { { name: string, fishName: string } } = {}
local running = false
local marqueeFrame: Frame?
local marqueeLabel: TextLabel?

local function build(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "LegendaryMarquee"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, -60)
	frame.Size = UDim2.fromOffset(620, 50)
	frame.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
	frame.BackgroundTransparency = 0
	frame.ZIndex = 80
	frame.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 100)
	stroke.Thickness = 2
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 18
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.ZIndex = 81
	label.Parent = frame

	marqueeFrame = frame
	marqueeLabel = label
end

local function processQueue()
	if running then
		return
	end
	running = true
	while #queue > 0 do
		local item = table.remove(queue, 1)
		if marqueeFrame and marqueeLabel and item then
			marqueeLabel.Text = ("LEGENDARY!  %s pulled %s"):format(item.name, item.fishName)
			TweenService:Create(marqueeFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 12),
			}):Play()
			task.wait(4)
			TweenService:Create(marqueeFrame, TweenInfo.new(0.4), {
				Position = UDim2.new(0.5, 0, 0, -60),
			}):Play()
			task.wait(0.5)
		end
	end
	running = false
end

function LegendaryMarqueeController.Mount(screen: ScreenGui, State)
	build(screen)
	Remotes.Client().Events.LegendaryAnnounce.OnClientEvent:Connect(function(payload)
		if not payload then
			return
		end
		local fishName = payload.fishId or "?"
		if State.catalog and State.catalog.fish and State.catalog.fish[payload.fishId] then
			fishName = State.catalog.fish[payload.fishId].name
		end
		table.insert(queue, { name = payload.name or "?", fishName = fishName })
		task.spawn(processQueue)
	end)
end

return LegendaryMarqueeController
