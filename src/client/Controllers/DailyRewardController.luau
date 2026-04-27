--!strict
--[[
	DailyRewardController — small floating button that shows the player's
	daily login state. When ready, clicking it claims the reward and
	plays a brief flash.
]]

local TweenService = game:GetService("TweenService")
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local DailyRewardController = {}

local function fmtTime(secs: number): string
	if secs <= 0 then
		return "READY"
	end
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	if h > 0 then
		return ("%dh %dm"):format(h, m)
	end
	return ("%dm"):format(m)
end

local function build(screen: ScreenGui)
	local btn = Instance.new("TextButton")
	btn.Name = "DailyRewardButton"
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.Position = UDim2.new(1, -12, 0, 84)
	btn.Size = UDim2.fromOffset(180, 56)
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 14
	btn.BackgroundColor3 = Color3.fromRGB(255, 195, 60)
	btn.TextColor3 = Color3.fromRGB(20, 30, 50)
	btn.Text = "DAILY REWARD"
	btn.ZIndex = 25
	btn.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(0.5, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0, 18)
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 12
	sub.TextColor3 = Color3.fromRGB(20, 30, 50)
	sub.Text = "..."
	sub.ZIndex = 26
	sub.Parent = btn

	return { btn = btn, sub = sub }
end

function DailyRewardController.Mount(screen: ScreenGui, _State)
	local ui = build(screen)
	local r = Remotes.Client()

	local cachedStatus

	local function render()
		if not cachedStatus then
			ui.sub.Text = "..."
			ui.btn.AutoButtonColor = false
			ui.btn.BackgroundColor3 = Color3.fromRGB(120, 130, 150)
			return
		end
		if cachedStatus.canClaim then
			ui.btn.BackgroundColor3 = Color3.fromRGB(255, 195, 60)
			ui.btn.AutoButtonColor = true
			ui.sub.Text = ("+%d gems · day %d"):format(cachedStatus.nextReward, cachedStatus.nextStreak)
		else
			ui.btn.BackgroundColor3 = Color3.fromRGB(120, 130, 150)
			ui.btn.AutoButtonColor = false
			ui.sub.Text = ("next in %s · day %d"):format(fmtTime(cachedStatus.secondsUntilClaim), cachedStatus.streak)
		end
	end

	local function refresh()
		task.spawn(function()
			local ok, status = pcall(function()
				return r.Functions.GetDailyStatus:InvokeServer()
			end)
			if ok and status then
				cachedStatus = status
				render()
			end
		end)
	end

	ui.btn.MouseButton1Click:Connect(function()
		if not cachedStatus or not cachedStatus.canClaim then
			return
		end
		task.spawn(function()
			local ok, result = pcall(function()
				return r.Functions.ClaimDaily:InvokeServer()
			end)
			if ok and result then
				-- Brief flash
				local origColor = ui.btn.BackgroundColor3
				TweenService:Create(ui.btn, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				}):Play()
				task.delay(0.18, function()
					TweenService:Create(ui.btn, TweenInfo.new(0.3), {
						BackgroundColor3 = origColor,
					}):Play()
				end)
				refresh()
			end
		end)
	end)

	-- Refresh every 30s and on snapshot changes (for streak display)
	refresh()
	task.spawn(function()
		while ui.btn.Parent do
			task.wait(30)
			refresh()
		end
	end)
end

return DailyRewardController
