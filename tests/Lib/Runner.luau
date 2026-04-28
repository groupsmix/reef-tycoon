--!strict
--[[
	Runner — minimal TestEZ-compatible test framework.

	Provides describe / it / expect with the chained `to.equal` /
	`to.be.ok` / `never` style of TestEZ. We vendor a small
	implementation rather than pulling TestEZ via Wally so the test
	dependencies stay zero.

	Usage:

		local Runner = require(path.to.Runner)
		Runner.describe("MyService", function()
			Runner.it("does something", function()
				Runner.expect(1 + 1).to.equal(2)
			end)
		end)
		local stats = Runner.run()
]]

local Runner = {}

type Spec = {
	name: string,
	fn: () -> (),
}

type Suite = {
	name: string,
	specs: { Spec },
	suites: { Suite },
}

local rootSuite: Suite = { name = "", specs = {}, suites = {} }
local suiteStack: { Suite } = { rootSuite }

local function currentSuite(): Suite
	return suiteStack[#suiteStack]
end

function Runner.describe(name: string, fn: () -> ())
	local suite: Suite = { name = name, specs = {}, suites = {} }
	table.insert(currentSuite().suites, suite)
	table.insert(suiteStack, suite)
	local ok, err = pcall(fn)
	table.remove(suiteStack)
	if not ok then
		error(("describe(%q) failed: %s"):format(name, tostring(err)), 0)
	end
end

function Runner.it(name: string, fn: () -> ())
	table.insert(currentSuite().specs, { name = name, fn = fn })
end

-- ─── expectation chain ──────────────────────────────────────────────────
-- Mimics TestEZ: expect(x).to.equal(y), expect(x).never.to.equal(y),
-- expect(x).to.be.ok(), expect(fn).to.throw().

local function fail(msg: string)
	error(msg, 3)
end

local Matchers = {}

function Matchers.equal(self, other)
	local equal = self.value == other
	if self._negated then
		if equal then
			fail(("expected %s NOT to equal %s"):format(tostring(self.value), tostring(other)))
		end
	else
		if not equal then
			fail(("expected %s to equal %s"):format(tostring(self.value), tostring(other)))
		end
	end
end

function Matchers.never_equal(self, other)
	local clone = setmetatable({ value = self.value, _negated = true }, getmetatable(self))
	Matchers.equal(clone, other)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k, v in b do
		if not deepEqual(v, a[k]) then
			return false
		end
	end
	return true
end

function Matchers.deepEqual(self, other)
	local eq = deepEqual(self.value, other)
	if self._negated then
		if eq then
			fail("expected NOT to deepEqual")
		end
	else
		if not eq then
			fail("expected deepEqual; got mismatch")
		end
	end
end

function Matchers.ok(self)
	local ok = self.value ~= nil and self.value ~= false
	if self._negated then
		if ok then
			fail(("expected falsy / nil, got %s"):format(tostring(self.value)))
		end
	else
		if not ok then
			fail(("expected truthy, got %s"):format(tostring(self.value)))
		end
	end
end

function Matchers.throw(self)
	if type(self.value) ~= "function" then
		fail("expect(...).to.throw expected a function")
	end
	local ok = pcall(self.value)
	if self._negated then
		if not ok then
			fail("expected NOT to throw")
		end
	else
		if ok then
			fail("expected to throw")
		end
	end
end

function Matchers.greaterThan(self, other)
	if not (self.value > other) then
		fail(("expected %s > %s"):format(tostring(self.value), tostring(other)))
	end
end

function Matchers.lessThan(self, other)
	if not (self.value < other) then
		fail(("expected %s < %s"):format(tostring(self.value), tostring(other)))
	end
end

local Be = {}
Be.__index = function(self, k)
	if k == "ok" then
		return function()
			Matchers.ok(self)
		end
	end
	error(("unknown matcher .be.%s"):format(tostring(k)), 2)
end

local To = {}
To.__index = function(self, k)
	if k == "equal" then
		return function(other)
			Matchers.equal(self, other)
		end
	elseif k == "deepEqual" then
		return function(other)
			Matchers.deepEqual(self, other)
		end
	elseif k == "throw" then
		return function()
			Matchers.throw(self)
		end
	elseif k == "be" then
		return setmetatable({ value = self.value, _negated = self._negated }, Be)
	elseif k == "greaterThan" then
		return function(other)
			Matchers.greaterThan(self, other)
		end
	elseif k == "lessThan" then
		return function(other)
			Matchers.lessThan(self, other)
		end
	end
	error(("unknown matcher .to.%s"):format(tostring(k)), 2)
end

local Expectation = {}
Expectation.__index = function(self, k)
	if k == "to" then
		return setmetatable({ value = self.value, _negated = self._negated }, To)
	elseif k == "never" then
		return setmetatable({ value = self.value, _negated = not self._negated }, Expectation)
	end
	error(("unknown chain .%s"):format(tostring(k)), 2)
end

function Runner.expect(value: any)
	return setmetatable({ value = value, _negated = false }, Expectation)
end

-- ─── runner ─────────────────────────────────────────────────────────────

type Result = {
	name: string,
	ok: boolean,
	err: string?,
}

local function joinName(parts: { string }): string
	local cleaned = {}
	for _, p in parts do
		if p ~= "" then
			table.insert(cleaned, p)
		end
	end
	return table.concat(cleaned, " > ")
end

local function runSuite(suite: Suite, prefix: { string }, results: { Result })
	local nextPrefix = table.clone(prefix)
	if suite.name ~= "" then
		table.insert(nextPrefix, suite.name)
	end
	for _, spec in suite.specs do
		local fullName = joinName(table.clone(nextPrefix)) .. (#nextPrefix > 0 and " > " or "") .. spec.name
		local ok, err = pcall(spec.fn)
		table.insert(results, {
			name = fullName,
			ok = ok,
			err = ok and nil or tostring(err),
		})
	end
	for _, child in suite.suites do
		runSuite(child, nextPrefix, results)
	end
end

function Runner.run(): { passed: number, failed: number, results: { Result } }
	local results: { Result } = {}
	runSuite(rootSuite, {}, results)
	local passed, failed = 0, 0
	for _, r in results do
		if r.ok then
			passed += 1
			print(("[PASS] %s"):format(r.name))
		else
			failed += 1
			print(("[FAIL] %s\n       %s"):format(r.name, tostring(r.err)))
		end
	end
	print(("\n--- %d passed, %d failed ---"):format(passed, failed))
	return { passed = passed, failed = failed, results = results }
end

function Runner.reset()
	rootSuite = { name = "", specs = {}, suites = {} }
	suiteStack = { rootSuite }
end

return Runner
