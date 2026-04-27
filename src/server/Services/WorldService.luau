--!strict
--[[
	WorldService — programmatically builds the lobby + per-player plots.

	The lobby is a circular sandy hall with a central spawn, ambient water
	plane, and 12 plots arranged around the edge (one per max server slot).
	Each plot is a 3×3 grid of pedestals plus a billboard showing the
	owner's name and lifetime cash.

	Why programmatic?
	- The user is non-dev. Every Studio dependency is something they have
	  to learn or pay a Fiverr builder for.
	- The world is data. We can iterate the layout in code, ship updates
	  in PRs, and avoid the asset-versioning hell of `.rbxm` files.
	- It still works if a future content drop swaps the aesthetic — a
	  reef biome is just a different `BuildBiome` function call.

	Visitors and tank rendering live in their own services and parent
	their instances under each plot's `Tanks` and `Visitors` folders.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local WorldService = {}

local PLOT_RADIUS = 110 -- distance of plot centers from origin
local PEDESTAL_GRID = 3 -- 3×3 = 9 pedestals/plot (player can unlock up to STARTING_TANK_SLOTS+gamepass)
local PEDESTAL_SPACING = 14
local PLOT_FORWARD_SHIFT = 30 -- how far plots extend outward
local PLOT_HEIGHT_Y = 0
local PLOTS = Config.SERVER_SIZE

-- Plots are built lazily: the central lobby is created on Init() but
-- per-player plots are only built when a player joins (or pulled from
-- the freePlots pool if a previous player has since left).
local plotByUserId: { [number]: Model } = {}
local freePlots: { Model } = {}
local plotsBuiltCount = 0
local nextPlotIndex = 1

local function makePart(props: { [string]: any }): BasePart
	local part = Instance.new(props.shape == "Cylinder" and "Part" or "Part")
	part.Anchored = true
	part.CanCollide = props.canCollide ~= false
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Color = props.color or Color3.fromRGB(220, 220, 220)
	part.Size = props.size or Vector3.new(4, 1, 4)
	if props.shape then
		part.Shape = props.shape
	end
	if props.cframe then
		part.CFrame = props.cframe
	elseif props.position then
		part.Position = props.position
	end
	if props.transparency then
		part.Transparency = props.transparency
	end
	if props.name then
		part.Name = props.name
	end
	if props.parent then
		part.Parent = props.parent
	end
	return part
end

local function buildLobbyCenter(): Folder
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = Workspace

	-- Sand floor (huge cylinder for the hall feel)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(2, 320, 320) -- cylinder is X-axis-aligned by default
	floor.CFrame = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))
	floor.Material = Enum.Material.Sand
	floor.Color = Color3.fromRGB(245, 220, 170)
	floor.Parent = lobby

	-- Outer water ring (decorative)
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Anchored = true
	water.CanCollide = false
	water.Shape = Enum.PartType.Cylinder
	water.Size = Vector3.new(0.5, 600, 600)
	water.CFrame = CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0, math.rad(90))
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(80, 170, 220)
	water.Transparency = 0.55
	water.Reflectance = 0.4
	water.Parent = lobby

	-- Spawn pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(120, 220, 200)
	spawn.Neutral = true
	spawn.Parent = lobby

	-- Central kiosk (decorative)
	local kioskBase = makePart({
		name = "KioskBase",
		size = Vector3.new(10, 8, 10),
		cframe = CFrame.new(0, 4.5, -22),
		material = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(90, 60, 40),
		parent = lobby,
	})
	local _ = kioskBase
	local kioskSign = Instance.new("Part")
	kioskSign.Anchored = true
	kioskSign.Size = Vector3.new(10, 4, 0.4)
	kioskSign.CFrame = CFrame.new(0, 11, -22)
	kioskSign.Material = Enum.Material.SmoothPlastic
	kioskSign.Color = Color3.fromRGB(40, 60, 80)
	kioskSign.Parent = lobby

	local sgui = Instance.new("SurfaceGui")
	sgui.Adornee = kioskSign
	sgui.Face = Enum.NormalId.Front
	sgui.PixelsPerStud = 100
	sgui.Parent = kioskSign
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = "REEF TYCOON\nopen an egg → place a fish → tips!"
	lbl.Parent = sgui

	return lobby
end

local function buildPlot(index: number): Model
	local angle = (index - 1) / PLOTS * math.pi * 2
	local center = Vector3.new(
		math.cos(angle) * (PLOT_RADIUS + PLOT_FORWARD_SHIFT),
		PLOT_HEIGHT_Y,
		math.sin(angle) * (PLOT_RADIUS + PLOT_FORWARD_SHIFT)
	)
	-- Local "forward" = away from origin
	local lookAt = center + Vector3.new(math.cos(angle), 0, math.sin(angle))
	local plotCFrame = CFrame.lookAt(center, lookAt)

	local plot = Instance.new("Model")
	plot.Name = "Plot_" .. index
	plot:SetAttribute("Index", index)
	plot:SetAttribute("OwnerUserId", 0)
	plot.Parent = Workspace

	-- Plot floor (square)
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.Size = Vector3.new(56, 1, 50)
	platform.CFrame = plotCFrame
	platform.Material = Enum.Material.Sand
	platform.Color = Color3.fromRGB(240, 215, 165)
	platform.Parent = plot

	-- Decorative back wall
	local back = Instance.new("Part")
	back.Anchored = true
	back.Size = Vector3.new(56, 16, 1)
	back.CFrame = plotCFrame * CFrame.new(0, 8, 24)
	back.Material = Enum.Material.SmoothPlastic
	back.Color = Color3.fromRGB(40, 60, 90)
	back.Parent = plot

	-- Owner billboard
	local billboard = Instance.new("Part")
	billboard.Name = "OwnerBillboard"
	billboard.Anchored = true
	billboard.CanCollide = false
	billboard.Size = Vector3.new(20, 6, 0.4)
	billboard.CFrame = plotCFrame * CFrame.new(0, 18, 24)
	billboard.Material = Enum.Material.Neon
	billboard.Color = Color3.fromRGB(80, 100, 130)
	billboard.Parent = plot

	local ownerSurface = Instance.new("SurfaceGui")
	ownerSurface.Name = "OwnerSurface"
	ownerSurface.Face = Enum.NormalId.Back
	ownerSurface.PixelsPerStud = 100
	ownerSurface.Adornee = billboard
	ownerSurface.Parent = billboard
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Size = UDim2.fromScale(1, 1)
	ownerLabel.Font = Enum.Font.GothamBlack
	ownerLabel.TextScaled = true
	ownerLabel.TextColor3 = Color3.new(1, 1, 1)
	ownerLabel.Text = "Empty Plot"
	ownerLabel.Parent = ownerSurface

	-- Pedestals: 3×3 grid centered on plot, offset forward (toward center)
	local pedestals = Instance.new("Folder")
	pedestals.Name = "Pedestals"
	pedestals.Parent = plot

	local pedestalIndex = 0
	for row = 0, PEDESTAL_GRID - 1 do
		for col = 0, PEDESTAL_GRID - 1 do
			pedestalIndex += 1
			local localOffset = Vector3.new(
				(col - (PEDESTAL_GRID - 1) / 2) * PEDESTAL_SPACING,
				0,
				(row - (PEDESTAL_GRID - 1) / 2) * PEDESTAL_SPACING - 4
			)
			local pedestal = Instance.new("Part")
			pedestal.Name = "Pedestal_" .. pedestalIndex
			pedestal:SetAttribute("Index", pedestalIndex)
			pedestal.Anchored = true
			pedestal.Size = Vector3.new(8, 4, 8)
			pedestal.CFrame = plotCFrame * CFrame.new(localOffset + Vector3.new(0, 2.5, 0))
			pedestal.Material = Enum.Material.Marble
			pedestal.Color = Color3.fromRGB(180, 200, 220)
			pedestal.Parent = pedestals

			-- Click prompt for unlock / placement
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Pedestal " .. pedestalIndex
			prompt.ActionText = "Place tank from shop"
			prompt.MaxActivationDistance = 14
			prompt.HoldDuration = 0
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false -- enabled per-owner from TankRenderService
			prompt.Parent = pedestal
		end
	end

	-- Tanks folder (TankRenderer parents Tank Models here)
	local tanks = Instance.new("Folder")
	tanks.Name = "Tanks"
	tanks.Parent = plot

	-- Visitors folder (VisitorRenderer parents NPCs here)
	local visitors = Instance.new("Folder")
	visitors.Name = "Visitors"
	visitors.Parent = plot

	return plot
end

local function setLighting()
	Lighting.Ambient = Color3.fromRGB(110, 140, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 160, 180)
	Lighting.Brightness = 2.2
	Lighting.ColorShift_Top = Color3.fromRGB(70, 130, 170)
	Lighting.ColorShift_Bottom = Color3.fromRGB(20, 60, 100)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true

	-- Soft underwater bloom
	local existingBloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not existingBloom then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.4
		bloom.Threshold = 0.85
		bloom.Size = 24
		bloom.Parent = Lighting
	end
	local existingBlur = Lighting:FindFirstChildOfClass("BlurEffect")
	if not existingBlur then
		local blur = Instance.new("BlurEffect")
		blur.Size = 6
		blur.Parent = Lighting
	end
	local existingColor = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not existingColor then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = 0.1
		cc.TintColor = Color3.fromRGB(220, 240, 255)
		cc.Parent = Lighting
	end
end

function WorldService.GetPlotForPlayer(player: Player): Model?
	return plotByUserId[player.UserId]
end

function WorldService.GetPlotPedestal(plot: Model, pedestalIndex: number): BasePart?
	local pedestals = plot:FindFirstChild("Pedestals")
	if not pedestals then
		return nil
	end
	return pedestals:FindFirstChild("Pedestal_" .. pedestalIndex) :: BasePart?
end

local function takeOrBuildPlot(): Model?
	local pooled = table.remove(freePlots, 1)
	if pooled then
		return pooled
	end
	if plotsBuiltCount >= PLOTS then
		return nil
	end
	local plot = buildPlot(nextPlotIndex)
	nextPlotIndex += 1
	plotsBuiltCount += 1
	return plot
end

function WorldService._claimPlot(player: Player)
	local plot = takeOrBuildPlot()
	if not plot then
		warn(("[WorldService] no free plot for %s; server too full?"):format(player.Name))
		return
	end
	plot:SetAttribute("OwnerUserId", player.UserId)
	plotByUserId[player.UserId] = plot
	local billboard = plot:FindFirstChild("OwnerBillboard")
	if billboard then
		local surface = billboard:FindFirstChild("OwnerSurface")
		if surface then
			local lbl = surface:FindFirstChild("OwnerLabel")
			if lbl and lbl:IsA("TextLabel") then
				lbl.Text = player.DisplayName .. "'s Reef"
			end
		end
	end

	-- Teleport the player on top of their plot (offset slightly in toward the plot center)
	local platform = plot:FindFirstChild("Platform") :: BasePart?
	if platform then
		task.spawn(function()
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
			hrp.CFrame = platform.CFrame * CFrame.new(0, 6, -8)
		end)
	end

	-- Enable the placement prompts on this player's pedestals
	local pedestals = plot:FindFirstChild("Pedestals")
	if pedestals then
		for _, pedestal in pedestals:GetChildren() do
			if pedestal:IsA("BasePart") then
				local prompt = pedestal:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = true
				end
			end
		end
	end
end

function WorldService._releasePlot(player: Player)
	local plot = plotByUserId[player.UserId]
	if not plot then
		return
	end
	plotByUserId[player.UserId] = nil
	plot:SetAttribute("OwnerUserId", 0)
	local billboard = plot:FindFirstChild("OwnerBillboard")
	if billboard then
		local surface = billboard:FindFirstChild("OwnerSurface")
		if surface then
			local lbl = surface:FindFirstChild("OwnerLabel")
			if lbl and lbl:IsA("TextLabel") then
				lbl.Text = "Empty Plot"
			end
		end
	end
	-- Clear tanks and visitors
	local tanks = plot:FindFirstChild("Tanks")
	if tanks then
		tanks:ClearAllChildren()
	end
	local visitors = plot:FindFirstChild("Visitors")
	if visitors then
		visitors:ClearAllChildren()
	end
	-- Disable prompts
	local pedestals = plot:FindFirstChild("Pedestals")
	if pedestals then
		for _, pedestal in pedestals:GetChildren() do
			if pedestal:IsA("BasePart") then
				local prompt = pedestal:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = false
				end
			end
		end
	end
	table.insert(freePlots, plot)
end

function WorldService.Init()
	-- Avoid double-build (e.g. test rigs)
	if Workspace:FindFirstChild("Lobby") then
		return
	end
	setLighting()
	buildLobbyCenter()
	-- Plots build lazily as players join. We do NOT pre-build all 12
	-- plots here — most servers have 1-3 players and would otherwise
	-- spend the rest of the session paying for ~100 unused parts.
	freePlots = {}
	plotsBuiltCount = 0
	nextPlotIndex = 1
	Players.PlayerAdded:Connect(WorldService._claimPlot)
	Players.PlayerRemoving:Connect(WorldService._releasePlot)
	for _, p in Players:GetPlayers() do
		task.spawn(WorldService._claimPlot, p)
	end
end

function WorldService.Start() end

return WorldService
