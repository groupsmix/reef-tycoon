--!strict
--[[
	GachaController — the egg-pull cinematic.

	Layered effects per pull:
	- Backdrop fades in (alpha scales with rarity).
	- Card scales in with elastic ease + gradient stroke.
	- Burst of particles (radial, rarity-colored) on Mythic+ pulls.
	- Camera shake on Mythic+ via CFrame nudge tweens (no humanoid).
	- Sound stinger: EggPop on every pull, MythicStinger / LegendaryStinger
	  on rare pulls.

	The whole thing intentionally never blocks the gameplay loop — the
	server has already credited the fish; this is purely visual.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local GachaController = {}

local activeState

local function color3FromTriple(t)
	return Color3.new(t[1], t[2], t[3])
end

local function playSound(name: string)
	local sound = SoundService:FindFirstChild(name)
	if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
		sound:Play()
	end
end

local function shakeCamera(intensity: number, duration: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local startTime = os.clock()
	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			return
		end
		local decay = 1 - (elapsed / duration)
		local offset = Vector3.new(
			(math.random() - 0.5) * intensity * decay,
			(math.random() - 0.5) * intensity * decay,
			(math.random() - 0.5) * intensity * decay
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

local function emitParticleBurst(parent: Frame, color: Color3, count: number)
	for i = 1, count do
		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromOffset(8, 8)
		dot.BackgroundColor3 = color
		dot.BackgroundTransparency = 0
		dot.BorderSizePixel = 0
		dot.ZIndex = 53
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
		dot.Parent = parent

		local angle = (i / count) * math.pi * 2 + math.random() * 0.4
		local radius = 220 + math.random(0, 80)
		local targetX = math.cos(angle) * radius
		local targetY = math.sin(angle) * radius

		TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, targetX, 0.5, targetY),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		}):Play()
		task.delay(1.0, function()
			dot:Destroy()
		end)
	end
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
	local particles = s.particles :: Frame
	local stroke = s.stroke :: UIStroke

	local color = color3FromTriple(rarity.color)
	local tier = rarity.tierIndex

	nameLbl.Text = fish.name
	nameLbl.TextColor3 = color
	rarityLbl.Text = string.upper(rarity.name)
	rarityLbl.TextColor3 = color
	stroke.Color = color
	pityLbl.Visible = isPity == true

	-- Sound stinger
	playSound("EggPop")
	if tier >= 5 then
		playSound("LegendaryStinger")
	elseif tier >= 4 then
		playSound("MythicStinger")
	end

	-- Camera shake on Mythic+
	if tier >= 4 then
		shakeCamera(0.6 + (tier - 4) * 0.4, 0.6)
	end

	-- Backdrop intensity scales with rarity
	local backdropAlpha = math.clamp(0.1 * tier, 0.1, 0.85)
	backdrop.BackgroundTransparency = 1
	card.Visible = true
	card.BackgroundTransparency = 1
	card.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 - backdropAlpha }):Play()
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 380, 0, 220),
	}):Play()

	-- Particle burst on Rare+
	if tier >= 3 then
		emitParticleBurst(particles, color, 16 + tier * 8)
	end

	local hold = tier >= 4 and 2.6 or 1.4
	task.delay(hold, function()
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

	local particles = Instance.new("Frame")
	particles.Name = "GachaParticles"
	particles.Size = UDim2.fromScale(1, 1)
	particles.BackgroundTransparency = 1
	particles.ZIndex = 52
	particles.Parent = screen

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
	nameLbl.Position = UDim2.new(0, 16, 0, 60)
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
	pityLbl.Text = "Pity Bonus!"
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
		particles = particles,
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
	pulseCard(rarity, fish, result.isPity)
end

function GachaController.OnLegendaryAnnounce(_payload)
	-- The server-wide marquee is owned by LegendaryMarqueeController.
	-- We just trigger a one-off camera shake here for everyone in the server.
	shakeCamera(0.4, 0.5)
end

return GachaController
