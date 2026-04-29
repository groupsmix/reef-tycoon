--!strict
--[[
	Test runner — collects every spec under tests/specs/ and runs it
	via the tiny framework. Exits non-zero on any failure.

	Usage (Lune): lune run tests/run.luau
]]

local framework = require("./framework")

local specs = {
	require("./specs/EconomyOps.spec"),
	require("./specs/GachaPity.spec"),
	require("./specs/DataMigrations.spec"),
	require("./specs/AntiCheatCheck.spec"),
	require("./specs/ReceiptDedup.spec"),
	require("./specs/RateLimiter.spec"),
	require("./specs/WeightedRandom.spec"),
}

for _, spec in specs do
	spec(framework)
end

local ok = framework.run()
if not ok then
	-- Lune treats nonzero as failure
	local proc = require("@lune/process")
	proc.exit(1)
end
