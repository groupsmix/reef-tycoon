--!strict
--[[
	LoadingController — covers the UI until the catalog + first snapshot
	have arrived. Without it, players see a half-built HUD for ~1s on
	join, which feels cheap.
]]

local TweenService = game:GetService("TweenService")

local LoadingController = {}

local function buildLoading(screen: ScreenGui): { frame: Frame, dots: TextLabel }
	local frame = Instance.new("Frame")
	frame.Name = "LoadingScreen"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(8, 18, 30)
	frame.BackgroundTransparency = 0
	frame.ZIndex = 100
	frame.Parent = screen

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.45, 0)
	title.Size = UDim2.fromOffset(600, 80)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 56
	title.TextColor3 = Color3.fromRGB(120, 220, 255)
	title.Text = "REEF TYCOON"
	title.ZIndex = 101
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.55, 0)
	subtitle.Size = UDim2.fromOffset(600, 32)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 18
	subtitle.TextColor3 = Color3.fromRGB(180, 200, 220)
	subtitle.Text = "loading the reef..."
	subtitle.ZIndex = 101
	subtitle.Parent = frame

	return { frame = frame, dots = subtitle }
end

function LoadingController.Mount(screen: ScreenGui, State)
	local ui = buildLoading(screen)

	-- Animate a "..." pulse so the user knows we're alive.
	task.spawn(function()
		local dotsTexts = { "loading the reef.", "loading the reef..", "loading the reef..." }
		local idx = 0
		while ui.frame.Parent do
			idx = (idx % #dotsTexts) + 1
			ui.dots.Text = dotsTexts[idx]
			task.wait(0.4)
		end
	end)

	local function hideIfReady()
		if State.catalog and State.snapshot then
			TweenService:Create(ui.frame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(ui.dots, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			task.delay(0.55, function()
				ui.frame:Destroy()
			end)
		end
	end

	State.SnapshotChanged:Connect(hideIfReady)
	hideIfReady()
end

return LoadingController
