--!strict
--[[
	Signal — minimal Roblox-flavored event class.

	Inspired by stravant's GoodSignal but trimmed to the essentials we use:
	`Connect`, `DisconnectAll`, and `Fire`.
]]

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type Class = {
	Connect: (self: Class, fn: (...any) -> ()) -> Connection,
	Fire: (self: Class, ...any) -> (),
	DisconnectAll: (self: Class) -> (),
}

function Signal.new(): Class
	local self = setmetatable({
		_listeners = {} :: { [number]: ((...any) -> ())? },
		_nextId = 1,
	}, Signal)
	return (self :: any) :: Class
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local id = self._nextId
	self._nextId += 1
	self._listeners[id] = fn

	local listeners = self._listeners
	local conn = {
		Connected = true,
	}
	function conn:Disconnect()
		if self.Connected then
			self.Connected = false
			listeners[id] = nil
		end
	end
	return conn
end

function Signal:Fire(...)
	for _, fn in self._listeners do
		if fn then
			task.spawn(fn, ...)
		end
	end
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
end

return Signal
