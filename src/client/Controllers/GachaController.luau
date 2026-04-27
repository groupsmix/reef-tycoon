--!strict
--[[
	GachaController — the egg-pull cinematic.

	Mythic+ pulls darken the screen, flash, and reveal a name card with
	the rarity color. This is the single highest-leverage UI surface in
	the game (it is the TikTok-content engine), so it deserves real
	polish post-MVP. The current implementation is a clean baseline:
	low-cost tweens, no asset deps, one card layout.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local GachaController = {}

local activeState

local function color3FromTriple(t)
	return Color3.new(t[1], t[2], t[3])
end

local function pulseCard(rarity, fish, isPity)
	local s = activeState
	if not s then
		return
	end
	local card = s.card :: Frame
	local nameLbl = s.nameLbl :: TextLabel
	local rarityLbl = s.rarityLbl :: TextLabel
	local pityLbl = s.pityLbl :: TextLabel
	local backdrop = s.backdrop :: Frame

	local color = color3FromTriple(rarity.color)

	nameLbl.Text = fish.name
	nameLbl.TextColor3 = color
	rarityLbl.Text = string.upper(rarity.name)
	rarityLbl.TextColor3 = color
	pityLbl.Visible = isPity == true

	-- Heavier overlays for higher rarities.
	local backdropAlpha = math.clamp(0.1 * rarity.tierIndex, 0.1, 0.85)
	backdrop.BackgroundTransparency = 1
	card.Visible = true
	card.BackgroundTransparency = 1

	TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 - backdropAlpha }):Play()
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 360, 0, 200),
	}):Play()

	task.delay(rarity.tierIndex >= 4 and 2.5 or 1.4, function()
		TweenService:Create(card, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(backdrop, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		task.wait(0.4)
		card.Visible = false
	end)
end

function GachaController.Mount(screen: ScreenGui, State, _r)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "GachaBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.Visible = true
	backdrop.ZIndex = 50
	backdrop.Parent = screen

	local card = Instance.new("Frame")
	card.Name = "GachaCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
	card.BackgroundTransparency = 1
	card.Visible = false
	card.ZIndex = 51
	card.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Parent = card

	local rarityLbl = Instance.new("TextLabel")
	rarityLbl.BackgroundTransparency = 1
	rarityLbl.Size = UDim2.new(1, 0, 0, 28)
	rarityLbl.Position = UDim2.new(0, 0, 0, 16)
	rarityLbl.Font = Enum.Font.GothamBlack
	rarityLbl.TextSize = 22
	rarityLbl.Text = "RARITY"
	rarityLbl.TextColor3 = Color3.new(1, 1, 1)
	rarityLbl.ZIndex = 52
	rarityLbl.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, -32, 0, 96)
	nameLbl.Position = UDim2.new(0, 16, 0, 56)
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextSize = 36
	nameLbl.TextWrapped = true
	nameLbl.Text = "Reef Tetra"
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.ZIndex = 52
	nameLbl.Parent = card

	local pityLbl = Instance.new("TextLabel")
	pityLbl.BackgroundTransparency = 1
	pityLbl.Size = UDim2.new(1, 0, 0, 24)
	pityLbl.Position = UDim2.new(0, 0, 1, -28)
	pityLbl.Font = Enum.Font.GothamMedium
	pityLbl.TextSize = 14
	pityLbl.Text = "Pity!"
	pityLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
	pityLbl.Visible = false
	pityLbl.ZIndex = 52
	pityLbl.Parent = card

	-- Bottom-left "Open Egg" button so playtesters always have a way to test pulls
	-- before the proper shop UI is open.
	local pullButton = Instance.new("TextButton")
	pullButton.Name = "OpenEgg"
	pullButton.AnchorPoint = Vector2.new(0, 1)
	pullButton.Position = UDim2.new(0, 12, 1, -12)
	pullButton.Size = UDim2.new(0, 160, 0, 56)
	pullButton.BackgroundColor3 = Color3.fromRGB(255, 195, 60)
	pullButton.Font = Enum.Font.GothamBlack
	pullButton.TextSize = 18
	pullButton.TextColor3 = Color3.fromRGB(20, 30, 50)
	pullButton.Text = "OPEN EGG"
	pullButton.Parent = screen
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 12)
	cc.Parent = pullButton

	pullButton.MouseButton1Click:Connect(function()
		Remotes.Client().Functions.BuyEgg:InvokeServer()
	end)

	activeState = {
		card = card,
		backdrop = backdrop,
		rarityLbl = rarityLbl,
		nameLbl = nameLbl,
		pityLbl = pityLbl,
		stroke = stroke,
		state = State,
	}
end

function GachaController.OnPullResult(result)
	local s = activeState
	if not s or not s.state.catalog then
		return
	end
	local rarity = s.state.catalog.rarities[result.rarity]
	local fish = s.state.catalog.fish[result.fishId]
	if not rarity or not fish then
		return
	end
	(s.stroke :: UIStroke).Color = color3FromTriple(rarity.color)
	pulseCard(rarity, fish, result.isPity)
end

function GachaController.OnLegendaryAnnounce(payload)
	-- Server-wide marquee. For MVP we just print + post a small chat-style banner.
	print(("[ReefTycoon] %s pulled a Legendary: %s"):format(payload.name, payload.fishId))
end

return GachaController
