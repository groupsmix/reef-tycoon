--!strict
--[[
	TutorialController — 3-step new-player onboarding.

	Steps:
	1. "Walk to your reef and place a tank."
	2. "Open an egg to get your first fish."
	3. "Place the fish in your tank to start earning tips."

	The tutorial is dismissed when:
	- The player marks it done (server records `tutorialDone`).
	- The player has any fish in any placed tank (auto-skip for returning
	  players who somehow lost the flag).

	Only shown when `snapshot.tutorialDone == false`.
]]

local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local TutorialController = {}

local STEPS = {
	{ title = "Step 1 / 3", body = "Walk to your reef plot and press E on a pedestal to place a starter tank." },
	{ title = "Step 2 / 3", body = "Open an egg from the bottom-left button to roll your first fish." },
	{
		title = "Step 3 / 3",
		body = "Open Inventory, click your fish, then click your tank slot. Tips will start flowing.",
	},
}

local function build(screen: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "TutorialPanel"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 12)
	frame.Size = UDim2.fromOffset(560, 110)
	frame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
	frame.BackgroundTransparency = 0.1
	frame.ZIndex = 30
	frame.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 220, 255)
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 24)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(120, 220, 255)
	title.Text = "Step 1 / 3"
	title.ZIndex = 31
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -20, 0, 50)
	body.Position = UDim2.new(0, 12, 0, 30)
	body.Font = Enum.Font.GothamMedium
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextSize = 14
	body.TextColor3 = Color3.new(1, 1, 1)
	body.Text = STEPS[1].body
	body.ZIndex = 31
	body.Parent = frame

	local nextBtn = Instance.new("TextButton")
	nextBtn.Size = UDim2.fromOffset(110, 28)
	nextBtn.AnchorPoint = Vector2.new(1, 1)
	nextBtn.Position = UDim2.new(1, -10, 1, -10)
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 14
	nextBtn.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
	nextBtn.TextColor3 = Color3.fromRGB(20, 30, 50)
	nextBtn.Text = "NEXT"
	nextBtn.ZIndex = 31
	nextBtn.Parent = frame
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = nextBtn

	return { frame = frame, title = title, body = body, next = nextBtn }
end

function TutorialController.Mount(screen: ScreenGui, State)
	local ui
	local step = 1
	local visible = false

	local function setStep(i: number)
		if not ui then
			return
		end
		step = i
		ui.title.Text = STEPS[i].title
		ui.body.Text = STEPS[i].body
		ui.next.Text = i == #STEPS and "DONE" or "NEXT"
	end

	local function show()
		if visible then
			return
		end
		visible = true
		ui = build(screen)
		setStep(1)
		ui.next.MouseButton1Click:Connect(function()
			if step < #STEPS then
				setStep(step + 1)
			else
				task.spawn(function()
					Remotes.Client().Functions.MarkTutorialDone:InvokeServer()
				end)
				ui.frame:Destroy()
				ui = nil
				visible = false
			end
		end)
	end

	local function hide()
		if not visible then
			return
		end
		visible = false
		if ui then
			ui.frame:Destroy()
			ui = nil
		end
	end

	local function reconcile()
		local snap = State.snapshot
		if not snap then
			return
		end
		if snap.tutorialDone then
			hide()
		else
			show()
		end
	end

	State.SnapshotChanged:Connect(reconcile)
	reconcile()
end

return TutorialController
