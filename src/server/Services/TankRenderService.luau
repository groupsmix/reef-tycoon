--!strict
--[[
	TankRenderService — renders each player's tanks as 3D Models on their
	plot, with fish that swim along randomized waypoints inside the tank
	volume.

	Why server-side rendering?
	- Multiplayer plot visibility: players can wander the lobby and see
	  other tanks, which is half the social fun.
	- One source of truth: server profile drives 3D state, the client
	  just observes.

	Performance budget:
	- Up to 12 plots × 9 pedestals × tank slot cap (20 for Reef God) × 1
	  fish part = ~2,160 parts at the absolute extreme. In practice it's
	  ~50–150 parts per server. Tween budget is fine.
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FishData = require(Shared:WaitForChild("FishData"))
local TankData = require(Shared:WaitForChild("TankData"))
local RarityData = require(Shared:WaitForChild("RarityData"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local WorldService = require(script.Parent:WaitForChild("WorldService"))

local TankRenderService = {}

local rng = Random.new()

local function setEnsureBillboard(part: BasePart, text: string)
	local existing = part:FindFirstChild("InfoBillboard")
	if existing and existing:IsA("BillboardGui") then
		local lbl = existing:FindFirstChild("Label")
		if lbl and lbl:IsA("TextLabel") then
			lbl.Text = text
		end
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoBillboard"
	bb.Size = UDim2.new(0, 240, 0, 60)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text = text
	lbl.Parent = bb
end

local function buildFishPart(fishId: string, parent: Instance, tankCFrame: CFrame, tankSize: Vector3)
	local fishMeta = FishData.getById(fishId)
	if not fishMeta then
		return
	end
	local rarity = RarityData.Rarities[fishMeta.rarity]

	local fish = Instance.new("Part")
	fish.Name = "Fish_" .. fishId
	fish.Anchored = true
	fish.CanCollide = false
	fish.Shape = Enum.PartType.Ball
	fish.Size = Vector3.new(1.0, 0.6, 1.6)
	fish.Material = Enum.Material.Neon
	fish.Color = fishMeta.primaryColor
	-- Trail-style glow ring
	local glow = Instance.new("PointLight")
	glow.Range = 6
	glow.Brightness = rarity and (1 + rarity.tierIndex * 0.4) or 1
	glow.Color = fishMeta.primaryColor
	glow.Parent = fish

	-- Tail: a thinner part attached behind
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Anchored = true
	tail.CanCollide = false
	tail.Shape = Enum.PartType.Ball
	tail.Size = Vector3.new(0.4, 0.4, 0.6)
	tail.Material = Enum.Material.Neon
	tail.Color = fishMeta.primaryColor
	tail.Parent = fish

	-- Random starting point inside tank
	local function randomPoint(): Vector3
		local margin = 1.5
		return tankCFrame
			* Vector3.new(
				rng:NextNumber(-tankSize.X / 2 + margin, tankSize.X / 2 - margin),
				rng:NextNumber(-tankSize.Y / 2 + margin, tankSize.Y / 2 - margin),
				rng:NextNumber(-tankSize.Z / 2 + margin, tankSize.Z / 2 - margin)
			)
	end

	fish.Position = randomPoint()
	fish.Parent = parent

	-- Swim loop. Each fish moves independently to a new random point every 1.5–3s.
	task.spawn(function()
		while fish.Parent do
			local next = randomPoint()
			local lookAt = CFrame.lookAt(fish.Position, next)
			local dur = rng:NextNumber(1.5, 3.0)
			local goal = { CFrame = lookAt + (next - fish.Position) }
			-- Wiggle the tail slightly while swimming
			local _ = goal
			local fishTween = TweenService:Create(
				fish,
				TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = CFrame.lookAt(next, next + (next - fish.Position).Unit) }
			)
			fishTween:Play()
			-- Position the tail behind the head every frame for the duration.
			local startTime = os.clock()
			while os.clock() - startTime < dur and fish.Parent do
				tail.CFrame = fish.CFrame * CFrame.new(0, 0, 0.7)
				task.wait(0.05)
			end
			task.wait(0.05)
		end
	end)
end

local function buildTankModel(plot: Model, pedestal: BasePart, tankId: string, fishIds: { string })
	local tankMeta = TankData.Tanks[tankId]
	if not tankMeta then
		return
	end

	local model = Instance.new("Model")
	model.Name = "Tank_" .. pedestal:GetAttribute("Index")
	model:SetAttribute("TankId", tankId)
	model:SetAttribute("PedestalIndex", pedestal:GetAttribute("Index"))
	model.Parent = plot:FindFirstChild("Tanks") :: Folder

	-- Stand on top of pedestal (pedestal top = pedestal.Y + 2)
	local stand = Instance.new("Part")
	stand.Name = "Stand"
	stand.Anchored = true
	stand.Size = Vector3.new(7, 1, 7)
	stand.CFrame = pedestal.CFrame * CFrame.new(0, 2.5, 0)
	stand.Material = Enum.Material.WoodPlanks
	stand.Color = Color3.fromRGB(80, 50, 30)
	stand.Parent = model

	-- Glass tank (visual)
	local tankSize = Vector3.new(6, 5, 6)
	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Anchored = true
	glass.CanCollide = false
	glass.Size = tankSize
	glass.CFrame = stand.CFrame * CFrame.new(0, tankSize.Y / 2 + 0.5, 0)
	glass.Material = Enum.Material.Glass
	glass.Color = tankMeta.primaryColor
	glass.Transparency = 0.4
	glass.Reflectance = 0.2
	glass.Parent = model

	-- Water inside (slightly smaller, more saturated)
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Anchored = true
	water.CanCollide = false
	water.Size = tankSize - Vector3.new(0.5, 0.5, 0.5)
	water.CFrame = glass.CFrame
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(80, 170, 220)
	water.Transparency = 0.7
	water.Parent = model

	-- Billboard with tank name + active fish count
	setEnsureBillboard(stand, ("%s (%d/%d)"):format(tankMeta.name, #fishIds, tankMeta.slotCapacity))

	-- Spawn fish parts
	local fishFolder = Instance.new("Folder")
	fishFolder.Name = "Fish"
	fishFolder.Parent = model

	for _, fishId in fishIds do
		buildFishPart(fishId, fishFolder, water.CFrame, water.Size)
	end

	-- Click prompt to remove
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = tankMeta.name
	prompt.ActionText = "Remove tank"
	prompt.HoldDuration = 1.0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stand
	prompt:SetAttribute("PedestalIndex", pedestal:GetAttribute("Index"))
end

local function rebuildPlayer(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local plot = WorldService.GetPlotForPlayer(player)
	if not plot then
		return
	end
	local tanks = plot:FindFirstChild("Tanks")
	if not tanks then
		return
	end
	tanks:ClearAllChildren()
	for _, placed in profile.placedTanks do
		local pedestal = WorldService.GetPlotPedestal(plot, placed.pedestalIndex)
		if pedestal then
			buildTankModel(plot, pedestal, placed.tankId, placed.fish)
		end
	end
end

function TankRenderService.Init() end

function TankRenderService.Start()
	DataService.ProfileChanged:Connect(rebuildPlayer)
	-- Periodic safety re-render in case events are lost; cheap because we
	-- only rebuild plots that have an owner.
	task.spawn(function()
		while true do
			task.wait(15)
			for _, plot in Workspace:GetChildren() do
				if plot:IsA("Model") and plot.Name:sub(1, 5) == "Plot_" then
					local ownerId = plot:GetAttribute("OwnerUserId")
					if ownerId and ownerId ~= 0 then
						local owner = game.Players:GetPlayerByUserId(ownerId)
						if owner then
							rebuildPlayer(owner)
						end
					end
				end
			end
		end
	end)
end

return TankRenderService
