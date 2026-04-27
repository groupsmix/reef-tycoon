--!strict
--[[
	RateLimiter — sliding-window per-key rate limiter.

	Usage:
		local limiter = RateLimiter.new({ burst = 5, sustained = 60, window = 60 })
		if not limiter:TryConsume(player.UserId) then
			-- reject
		end
]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type Config = {
	burst: number, -- max events in the last 1s
	sustained: number, -- max events in the last `window` seconds
	window: number, -- size of the sustained window in seconds
}

function RateLimiter.new(config: Config)
	local self = setmetatable({
		_burst = config.burst,
		_sustained = config.sustained,
		_window = config.window,
		_timestamps = {} :: { [number]: { number } },
	}, RateLimiter)
	return self
end

function RateLimiter:TryConsume(key: number): boolean
	local now = os.clock()
	local stamps = self._timestamps[key]
	if not stamps then
		stamps = {}
		self._timestamps[key] = stamps
	end

	-- Drop entries older than the sustained window
	local cutoff = now - self._window
	local i = 1
	while i <= #stamps and stamps[i] < cutoff do
		i += 1
	end
	if i > 1 then
		-- Compact from the head
		for j = 1, #stamps - (i - 1) do
			stamps[j] = stamps[j + (i - 1)]
		end
		for j = #stamps - (i - 1) + 1, #stamps do
			stamps[j] = nil
		end
	end

	if #stamps >= self._sustained then
		return false
	end

	-- Burst check (last 1s)
	local burstCount = 0
	for j = #stamps, 1, -1 do
		if stamps[j] >= now - 1 then
			burstCount += 1
			if burstCount >= self._burst then
				return false
			end
		else
			break
		end
	end

	table.insert(stamps, now)
	return true
end

function RateLimiter:Forget(key: number)
	self._timestamps[key] = nil
end

return RateLimiter
