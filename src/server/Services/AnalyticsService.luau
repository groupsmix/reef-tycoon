--!strict
--[[
	AnalyticsService — structured event log.

	Events are emitted via `AnalyticsService.Track(player, name, props)`
	and batched into a per-day DataStore key. Designed to be cheap and
	bounded; we cap each day's batch at 1,000 events per UTC day across
	the whole server.

	You can pull the data via Open Cloud / DataStores Explorer.
	For higher fidelity, swap this with PlayFab or PlayerAnalytics.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local AnalyticsService = {}

local store = DataStoreService:GetDataStore("ReefTycoon_Analytics_v1")

local DAY_CAP = 1000
local buffer: { any } = {}
local lastDayKey: string? = nil
local count = 0

local function dayKey(): string
	return os.date("!%Y-%m-%d", os.time()) :: string
end

local function flush()
	if #buffer == 0 then
		return
	end
	if RunService:IsStudio() then
		buffer = {}
		return
	end
	local payload = buffer
	buffer = {}
	local key = ("d_%s_s_%s_%d"):format(dayKey(), tostring(game.JobId), os.time())
	pcall(function()
		store:SetAsync(key, payload)
	end)
end

function AnalyticsService.Track(playerOrUserId: any, name: string, props: any?)
	local userId: number = if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player")
		then playerOrUserId.UserId
		else playerOrUserId :: number
	local key = dayKey()
	if key ~= lastDayKey then
		lastDayKey = key
		count = 0
	end
	if count >= DAY_CAP then
		return
	end
	count += 1
	table.insert(buffer, {
		t = os.time(),
		u = userId,
		e = name,
		p = props,
	})
	if #buffer >= 50 then
		task.spawn(flush)
	end
end

function AnalyticsService.Init() end

function AnalyticsService.Start()
	task.spawn(function()
		while true do
			task.wait(60)
			flush()
		end
	end)
	game:BindToClose(flush)
end

return AnalyticsService
