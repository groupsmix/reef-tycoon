--!strict
--[[
	TestRunner — boots all *.spec.luau modules under Tests.Specs and
	runs them via the in-tree TestEZ-compatible Runner.

	Bundled into the test place via `tests.project.json`. Run locally
	with:
		rojo build tests.project.json -o build/ReefTycoonTests.rbxlx
		run-in-roblox --place build/ReefTycoonTests.rbxlx --script tests/TestRunner.server.luau

	Or in CI, see `.github/workflows/test.yml`.
]]

local Tests = script.Parent
local Runner = require(Tests:WaitForChild("Lib"):WaitForChild("Runner"))
local Specs = Tests:WaitForChild("Specs")

-- Give services a tick to be ready in case the test place ever boots
-- alongside Main (we do NOT include Main today, but be defensive).
task.wait(0.5)

local loadFailures: { string } = {}
for _, mod in Specs:GetChildren() do
	if mod:IsA("ModuleScript") then
		local ok, err = pcall(require, mod)
		if not ok then
			table.insert(loadFailures, ("%s: %s"):format(mod.Name, tostring(err)))
		end
	end
end

if #loadFailures > 0 then
	for _, msg in loadFailures do
		warn(("[TestRunner] failed to load spec %s"):format(msg))
	end
	error(("[TestRunner] %d spec module(s) failed to load"):format(#loadFailures))
end

local stats = Runner.run()

if stats.failed > 0 then
	error(("[TestRunner] %d test(s) failed"):format(stats.failed))
end

print("[TestRunner] ALL TESTS PASSED")
