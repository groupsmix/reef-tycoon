--!strict
--[[
	Validate — argument-type validators for RemoteFunction handlers.

	Usage:

		local Validate = require(Shared.Util.Validate)

		r.Functions.PlaceTank.OnServerInvoke = Validate.wrap(
			{ "string", "number" },
			function(player, tankId, pedestalIndex)
				return TankService.PlaceTank(player, tankId, pedestalIndex)
			end
		)

	`wrap` returns a function with the standard RemoteFunction
	signature `(player, ...) -> any`. It performs the following checks
	before calling `handler`:

	- the caller is a real Player instance
	- the number of args is at least #signature
	- each arg's `typeof()` matches the corresponding signature entry
	- numeric args are finite (rejects NaN / inf)
	- string args are bounded in length (rejects 1MB griefer payloads)

	If any check fails the call is dropped, a warning is logged, and
	`nil` is returned. Handlers should always return a sentinel
	(false / nil) on failure so `nil` from a validation reject is
	indistinguishable from a normal failure on the client side.

	Optional banlist hook: if a `bannedFn` is provided, it's called
	first and the call is rejected if it returns true.
]]

local MAX_STRING_BYTES = 256

local Validate = {}

export type Signature = { string }
export type Handler = (player: Player, ...any) -> any
export type BannedFn = (userId: number) -> boolean

local function checkArg(value: any, expected: string): (boolean, string?)
	local actual = typeof(value)
	if actual ~= expected then
		return false, ("expected %s, got %s"):format(expected, actual)
	end
	if expected == "number" then
		if value ~= value then
			return false, "NaN"
		end
		if value == math.huge or value == -math.huge then
			return false, "infinite"
		end
	elseif expected == "string" then
		if #value > MAX_STRING_BYTES then
			return false, ("string too long (%d bytes)"):format(#value)
		end
	end
	return true, nil
end

function Validate.wrap(signature: Signature, handler: Handler, bannedFn: BannedFn?): (any, ...any) -> any
	return function(player: any, ...: any): any
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			warn("[Validate] non-Player caller rejected")
			return nil
		end
		if bannedFn and bannedFn(player.UserId) then
			warn(("[Validate] banned user %s blocked"):format(player.Name))
			return nil
		end
		local args = { ... }
		if #args < #signature then
			warn(("[Validate] %s sent %d args, expected %d"):format(player.Name, #args, #signature))
			return nil
		end
		for i, expected in signature do
			local ok, err = checkArg(args[i], expected)
			if not ok then
				warn(("[Validate] %s arg #%d: %s"):format(player.Name, i, err or "?"))
				return nil
			end
		end
		return handler(player, ...)
	end
end

-- Convenience: validators for common signatures.
function Validate.zeroArgs(handler: Handler, bannedFn: BannedFn?)
	return Validate.wrap({}, handler, bannedFn)
end

return Validate
