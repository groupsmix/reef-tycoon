--!strict
--[[
	OfflineEarningsController — welcome-back panel.

	Server fires `OfflineEarnings(amount)` once per join. We show a
	one-shot panel telling the player how much they accumulated while
	away.
]]

local TweenService = game:GetService("TweenService")
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local OfflineEarningsController = {}

local function fmt(n: number): string
	-- Add k / m suffixes for readability.
	if n >= 1_000_000 then
		return ("%.1fM"):format(n / 1_000_000)
	elseif n >= 1_000 then
		return ("%.1fk"):format(n / 1_000)
	end
	return tostring(n)
end

function OfflineEarningsController.Mount(screen: ScreenGui, _State)
	Remotes.Client().Events.OfflineEarnings.OnClientEvent:Connect(function(amount)
		if not amount or amount <= 0 then
			return
		end
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.35, 0)
		frame.Size = UDim2.fromOffset(440, 140)
		frame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
		frame.BackgroundTransparency = 0.05
		frame.ZIndex = 40
		frame.Parent = screen
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 195, 60)
		stroke.Thickness = 2
		stroke.Parent = frame

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0, 36)
		title.Position = UDim2.new(0, 0, 0, 12)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 26
		title.TextColor3 = Color3.fromRGB(255, 195, 60)
		title.Text = "WELCOME BACK!"
		title.ZIndex = 41
		title.Parent = frame

		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, -32, 0, 60)
		body.Position = UDim2.new(0, 16, 0, 56)
		body.Font = Enum.Font.GothamMedium
		body.TextSize = 18
		body.TextWrapped = true
		body.TextColor3 = Color3.new(1, 1, 1)
		body.Text = ("While you were away, your reef earned $%s"):format(fmt(amount))
		body.ZIndex = 41
		body.Parent = frame

		task.delay(4, function()
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(body, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.45)
			frame:Destroy()
		end)
	end)
end

return OfflineEarningsController
