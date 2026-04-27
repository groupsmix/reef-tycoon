--!strict
--[[
	VisitorRenderService — visual NPCs walking around each owner's plot.

	Pure decoration. The actual tip math lives in `VisitorService`. We
	spawn small stylized visitor parts (head + body + legs) that walk to
	a random tank, idle for a few seconds, emit a tip particle, and walk
	to the next tank. They despawn after a few minutes to keep the part
	count bounded.

	Why not use proper Humanoids?
	- Humanoid pathfinding adds CPU overhead per NPC.
	- We don't need real collision. A pure-tween walker is plenty.
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local VisitorRenderService = {}

local rng = Random.new()

local SHIRT_COLORS = {
	Color3.fromRGB(255, 180, 90),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(200, 110, 220),
	Color3.fromRGB(120, 220, 130),
	Color3.fromRGB(255, 130, 130),
	Color3.fromRGB(100, 130, 220),
}

local SKIN_COLORS = {
	Color3.fromRGB(245, 215, 175),
	Color3.fromRGB(220, 175, 130),
	Color3.fromRGB(180, 130, 90),
	Color3.fromRGB(140, 95, 60),
}

local function buildVisitor(parent: Instance, spawnPos: Vector3): Model
	local visitor = Instance.new("Model")
	visitor.Name = "Visitor"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(2, 2.4, 1.2)
	body.Color = SHIRT_COLORS[rng:NextInteger(1, #SHIRT_COLORS)]
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new(spawnPos + Vector3.new(0, 1.2, 0))
	body.Parent = visitor
	visitor.PrimaryPart = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = SKIN_COLORS[rng:NextInteger(1, #SKIN_COLORS)]
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = visitor

	local function attach()
		head.CFrame = body.CFrame * CFrame.new(0, body.Size.Y / 2 + head.Size.Y / 2 - 0.2, 0)
	end
	attach()
	-- Keep head tracking body whenever we tween
	body:GetPropertyChangedSignal("CFrame"):Connect(attach)

	visitor.Parent = parent
	return visitor
end

local function emitTipParticle(part: BasePart)
	local emitter = Instance.new("Part")
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.Transparency = 1
	emitter.Size = Vector3.new(0.1, 0.1, 0.1)
	emitter.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	emitter.Parent = part
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 80, 0, 40)
	bb.AlwaysOnTop = true
	bb.Parent = emitter
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text = "+$"
	lbl.Parent = bb
	-- Float up + fade
	TweenService:Create(emitter, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = emitter.CFrame + Vector3.new(0, 4, 0),
	}):Play()
	TweenService:Create(lbl, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.3, function()
		emitter:Destroy()
	end)
end

local function walkTo(visitor: Model, target: CFrame, duration: number)
	local body = visitor.PrimaryPart
	if not body then
		return
	end
	-- Face the target
	local lookCFrame = CFrame.lookAt(body.Position, target.Position) * CFrame.new(0, 0, 0)
	-- Bob slightly while walking
	local steps = math.max(2, math.floor(duration * 8))
	for i = 1, steps do
		local alpha = i / steps
		local pos = body.Position:Lerp(target.Position, alpha)
		local bob = math.sin(alpha * math.pi * 4) * 0.15
		body.CFrame = CFrame.new(pos + Vector3.new(0, bob, 0)) * lookCFrame.Rotation
		task.wait(duration / steps)
	end
end

local function chooseTankAnchor(plot: Model): CFrame?
	local tanks = plot:FindFirstChild("Tanks")
	if not tanks then
		return nil
	end
	local children = tanks:GetChildren()
	if #children == 0 then
		return nil
	end
	local pick = children[rng:NextInteger(1, #children)]
	if pick:IsA("Model") then
		local stand = pick:FindFirstChild("Stand")
		if stand and stand:IsA("BasePart") then
			-- A few studs in front of the stand, on the ground
			return stand.CFrame * CFrame.new(0, -2.5, 4)
		end
	end
	return nil
end

local function visitorLoop(visitor: Model, plot: Model, plotEdge: CFrame)
	local body = visitor.PrimaryPart
	if not body then
		return
	end
	for _ = 1, rng:NextInteger(2, 5) do
		if not visitor.Parent then
			return
		end
		local target = chooseTankAnchor(plot)
		if not target then
			break
		end
		walkTo(visitor, target, rng:NextNumber(2.0, 3.5))
		-- Idle + tip
		task.wait(rng:NextNumber(1.5, 3.0))
		if visitor.Parent and body and body.Parent then
			emitTipParticle(body)
		end
	end
	-- Walk back off the plot edge then despawn
	walkTo(visitor, plotEdge, 2.5)
	visitor:Destroy()
end

function VisitorRenderService._spawnForPlot(plot: Model)
	local platform = plot:FindFirstChild("Platform") :: BasePart?
	if not platform then
		return
	end
	-- Spawn at the edge facing inward
	local spawnPos = (platform.CFrame * CFrame.new(0, 1.5, -22)).Position
	local plotEdge = platform.CFrame * CFrame.new(0, 1.5, 24)
	local visitorsFolder = plot:FindFirstChild("Visitors") :: Folder?
	if not visitorsFolder then
		return
	end
	local visitor = buildVisitor(visitorsFolder, spawnPos)
	task.spawn(visitorLoop, visitor, plot, plotEdge)
end

function VisitorRenderService.Init() end

function VisitorRenderService.Start()
	task.spawn(function()
		while true do
			task.wait(Config.VISITOR_SPAWN_INTERVAL_SECONDS)
			-- Only spawn for plots that have at least one tank with at least one fish.
			for _, plot in Workspace:GetChildren() do
				if plot:IsA("Model") and plot.Name:sub(1, 5) == "Plot_" then
					local ownerId = plot:GetAttribute("OwnerUserId")
					if not ownerId or ownerId == 0 then
						continue
					end
					local owner = Players:GetPlayerByUserId(ownerId)
					if not owner then
						continue
					end
					local profile = DataService.GetProfile(owner)
					if not profile then
						continue
					end
					-- Skip if the plot already has too many visitors
					local visitorsFolder = plot:FindFirstChild("Visitors")
					if visitorsFolder and #visitorsFolder:GetChildren() >= 6 then
						continue
					end
					local hasFish = false
					for _, placed in profile.placedTanks do
						if #placed.fish > 0 then
							hasFish = true
							break
						end
					end
					if hasFish then
						VisitorRenderService._spawnForPlot(plot)
					end
				end
			end
		end
	end)
end

return VisitorRenderService
