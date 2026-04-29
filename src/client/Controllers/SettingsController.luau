--!strict
--[[
	SettingsController — small panel anchored bottom-right with audio
	toggles, a locale picker, and links to the privacy notice / terms.

	The panel is hidden by default and toggled by a 44x44 button so it
	complies with the mobile tap-target minimum.

	Audio is implemented as a multiplier on `SoundService.Volume` for
	music vs SFX groups. Settings are not persisted server-side at
	launch; players who want their preferences remembered can return the
	feedback in Discord and we can promote it to a profile field in a
	future schema bump.
]]

local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local SettingsController = {}

local function makeButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(230, 240, 255)
	btn.Text = text
	btn.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	return btn
end

local function makeRow(parent: Instance, label: string, y: UDim, height: UDim): Frame
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -16, height.Scale, height.Offset)
	row.Position = UDim2.new(0, 8, y.Scale, y.Offset)
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.5, 0, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Color3.fromRGB(220, 230, 255)
	lbl.Text = label
	lbl.Parent = row
	return row
end

function SettingsController.Mount(screen: ScreenGui, _State)
	local toggle = Instance.new("TextButton")
	toggle.Name = "SettingsToggle"
	toggle.AnchorPoint = Vector2.new(1, 1)
	toggle.Position = UDim2.new(1, -12, 1, -12)
	toggle.Size = UDim2.fromOffset(48, 48)
	toggle.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
	toggle.BorderSizePixel = 0
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 22
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Text = "⚙"
	toggle.Parent = screen
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	local panel = Instance.new("Frame")
	panel.Name = "SettingsPanel"
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(1, -12, 1, -68)
	panel.Size = UDim2.fromOffset(280, 280)
	panel.BackgroundColor3 = Color3.fromRGB(15, 25, 38)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screen
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(230, 240, 255)
	title.Text = Strings.get("settings.title")
	title.Parent = panel

	local musicRow = makeRow(panel, Strings.get("settings.audio.music"), UDim.new(0, 38), UDim.new(0, 36))
	local musicBtn = makeButton(musicRow, "On", UDim2.new(0.45, -8, 1, 0), UDim2.new(0.55, 0, 0, 0))
	musicBtn.Name = "MusicToggle"

	local sfxRow = makeRow(panel, Strings.get("settings.audio.sfx"), UDim.new(0, 80), UDim.new(0, 36))
	local sfxBtn = makeButton(sfxRow, "On", UDim2.new(0.45, -8, 1, 0), UDim2.new(0.55, 0, 0, 0))
	sfxBtn.Name = "SfxToggle"

	local localeRow = makeRow(panel, Strings.get("settings.locale"), UDim.new(0, 122), UDim.new(0, 36))
	local localeBtn = makeButton(localeRow, Strings.getLocale(), UDim2.new(0.45, -8, 1, 0), UDim2.new(0.55, 0, 0, 0))
	localeBtn.Name = "LocaleCycle"

	local privacyBtn =
		makeButton(panel, Strings.get("settings.privacy"), UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 168))
	privacyBtn.Name = "PrivacyLink"

	local termsBtn = makeButton(panel, Strings.get("settings.terms"), UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 212))
	termsBtn.Name = "TermsLink"

	local musicOn, sfxOn = true, true
	local musicGroup = SoundService:FindFirstChild("Music")
	local sfxGroup = SoundService:FindFirstChild("SFX")

	local function applyAudio()
		musicBtn.Text = musicOn and "On" or "Off"
		sfxBtn.Text = sfxOn and "On" or "Off"
		if musicGroup and musicGroup:IsA("SoundGroup") then
			musicGroup.Volume = musicOn and 1 or 0
		end
		if sfxGroup and sfxGroup:IsA("SoundGroup") then
			sfxGroup.Volume = sfxOn and 1 or 0
		end
	end

	applyAudio()

	musicBtn.MouseButton1Click:Connect(function()
		musicOn = not musicOn
		applyAudio()
	end)

	sfxBtn.MouseButton1Click:Connect(function()
		sfxOn = not sfxOn
		applyAudio()
	end)

	localeBtn.MouseButton1Click:Connect(function()
		local locales = Strings.supportedLocales()
		local currentIdx = 1
		for i, loc in locales do
			if loc == Strings.getLocale() then
				currentIdx = i
				break
			end
		end
		local next_ = locales[(currentIdx % #locales) + 1]
		Strings.setLocale(next_)
		localeBtn.Text = next_
	end)

	-- Both buttons just print a notice in chat for now. Public-launch
	-- branch swaps these for actual links once the GitHub raw URLs are
	-- live.
	local function announce(msg: string)
		print(("[Settings] %s"):format(msg))
	end
	privacyBtn.MouseButton1Click:Connect(function()
		announce("see PRIVACY.md in the repo")
	end)
	termsBtn.MouseButton1Click:Connect(function()
		announce("see TERMS.md in the repo")
	end)

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return SettingsController
