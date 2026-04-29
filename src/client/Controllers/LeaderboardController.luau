--!strict
--[[
	LeaderboardController — top-right pane showing the global top 10
	by lifetime cash, refreshed every 60s.

	Reads from `Remotes.Functions.GetTopCash`, which `LeaderboardService`
	already exposes server-side. Players see their own row highlighted
	if they're in the top 10.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local LeaderboardController = {}

local REFRESH_INTERVAL_SECONDS = 60

local function fmt(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.2fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.2fM", n / 1_000_000)
	elseif n >= 10_000 then
		return string.format("%.1fK", n / 1_000)
	end
	return tostring(n)
end

function LeaderboardController.Mount(screen: ScreenGui, _State, r)
	local panel = Instance.new("Frame")
	panel.Name = "Leaderboard"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 56)
	panel.Size = UDim2.fromOffset(220, 320)
	panel.BackgroundColor3 = Color3.fromRGB(15, 25, 38)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(255, 215, 80)
	title.Text = Strings.get("leaderboard.title")
	title.Parent = panel

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.new(0, 8, 0, 32)
	list.Size = UDim2.new(1, -16, 1, -40)
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = list

	local empty = Instance.new("TextLabel")
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.new(1, 0, 0, 24)
	empty.Font = Enum.Font.Gotham
	empty.TextSize = 13
	empty.TextColor3 = Color3.fromRGB(180, 200, 225)
	empty.Text = Strings.get("leaderboard.empty")
	empty.Parent = list

	local function row(idx: number, name: string, cash: number, isMe: boolean): Frame
		local frame = Instance.new("Frame")
		frame.LayoutOrder = idx
		frame.Size = UDim2.new(1, 0, 0, 24)
		frame.BackgroundColor3 = isMe and Color3.fromRGB(40, 70, 110) or Color3.fromRGB(20, 35, 55)
		frame.BackgroundTransparency = isMe and 0.1 or 0.4
		frame.BorderSizePixel = 0
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 4)
		fc.Parent = frame

		local rank = Instance.new("TextLabel")
		rank.BackgroundTransparency = 1
		rank.Size = UDim2.new(0, 28, 1, 0)
		rank.Font = Enum.Font.GothamMedium
		rank.TextSize = 12
		rank.TextColor3 = Color3.fromRGB(255, 215, 80)
		rank.Text = "#" .. idx
		rank.Parent = frame

		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 32, 0, 0)
		nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
		nameLbl.Font = Enum.Font.Gotham
		nameLbl.TextSize = 12
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextColor3 = Color3.fromRGB(230, 240, 255)
		nameLbl.Text = name
		nameLbl.Parent = frame

		local cashLbl = Instance.new("TextLabel")
		cashLbl.BackgroundTransparency = 1
		cashLbl.AnchorPoint = Vector2.new(1, 0)
		cashLbl.Position = UDim2.new(1, -4, 0, 0)
		cashLbl.Size = UDim2.new(0.4, 0, 1, 0)
		cashLbl.Font = Enum.Font.GothamMedium
		cashLbl.TextSize = 12
		cashLbl.TextXAlignment = Enum.TextXAlignment.Right
		cashLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
		cashLbl.Text = "$" .. fmt(cash)
		cashLbl.Parent = frame

		return frame
	end

	local function refresh()
		local ok, top = pcall(function()
			return r.Functions.GetTopCash:InvokeServer()
		end)
		if not ok or type(top) ~= "table" then
			return
		end
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		empty.Visible = #top == 0
		local me = Players.LocalPlayer
		for i, entry in top do
			local username = "—"
			local lookup = pcall(function()
				username = Players:GetNameFromUserIdAsync(entry.userId)
			end)
			if not lookup then
				username = ("user_%d"):format(entry.userId)
			end
			row(i, username, entry.cash, me and entry.userId == me.UserId).Parent = list
		end
	end

	task.spawn(function()
		while panel.Parent do
			refresh()
			task.wait(REFRESH_INTERVAL_SECONDS)
		end
	end)
end

return LeaderboardController
