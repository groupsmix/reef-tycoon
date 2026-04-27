--!strict
--[[
	WeightedRandom — tiny helper for picking a key from a {[k]=weight} table.

	Returns nil if the table is empty.
]]

local WeightedRandom = {}

function WeightedRandom.pick<T>(weights: { [T]: number }, rng: Random?): T?
	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		return nil
	end
	local r: number
	if rng then
		r = rng:NextNumber(0, total)
	else
		r = math.random() * total
	end
	local acc = 0
	local last: T? = nil
	for k, w in weights do
		acc += w
		last = k
		if r <= acc then
			return k
		end
	end
	return last
end

return WeightedRandom
