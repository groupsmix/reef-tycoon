--!strict
--[[
	Tiny test framework — TestEZ-shaped describe/it/expect API, ~150 lines,
	zero deps. Runs under standalone Luau or Lune.
]]

local framework = {}

type Suite = {
	name: string,
	tests: { Test },
	beforeEach: (() -> ())?,
	afterEach: (() -> ())?,
}

type Test = {
	name: string,
	body: () -> (),
}

local suites: { Suite } = {}
local currentSuite: Suite? = nil

function framework.describe(name: string, body: () -> ())
	local suite: Suite = { name = name, tests = {}, beforeEach = nil, afterEach = nil }
	local prev = currentSuite
	currentSuite = suite
	body()
	currentSuite = prev
	table.insert(suites, suite)
end

function framework.it(name: string, body: () -> ())
	assert(currentSuite, "it() must be called inside describe()")
	table.insert(currentSuite.tests, { name = name, body = body })
end

function framework.beforeEach(fn: () -> ())
	assert(currentSuite, "beforeEach() must be called inside describe()")
	currentSuite.beforeEach = fn
end

function framework.afterEach(fn: () -> ())
	assert(currentSuite, "afterEach() must be called inside describe()")
	currentSuite.afterEach = fn
end

local Expectation = {}
Expectation.__index = Expectation

local function repr(v: any): string
	if type(v) == "string" then
		return ("%q"):format(v)
	elseif type(v) == "table" then
		local parts = {}
		for k, val in v do
			table.insert(parts, tostring(k) .. "=" .. tostring(val))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

function Expectation.new(value: any)
	local self = setmetatable({ _value = value, _negated = false }, Expectation)
	return self
end

function Expectation:never(): any
	self._negated = not self._negated
	return self
end

function Expectation:_check(condition: boolean, msg: string)
	if self._negated then
		condition = not condition
	end
	if not condition then
		error(msg, 3)
	end
end

function Expectation:equal(other: any): any
	self:_check(self._value == other, ("expected %s to equal %s"):format(repr(self._value), repr(other)))
	return self
end

function Expectation:near(other: number, epsilon: number?): any
	local eps = epsilon or 1e-6
	self:_check(
		math.abs(self._value - other) < eps,
		("expected %s to be within %s of %s"):format(tostring(self._value), tostring(eps), tostring(other))
	)
	return self
end

function Expectation:beTrue(): any
	self:_check(self._value == true, ("expected %s to be true"):format(repr(self._value)))
	return self
end

function Expectation:beFalse(): any
	self:_check(self._value == false, ("expected %s to be false"):format(repr(self._value)))
	return self
end

function Expectation:beNil(): any
	self:_check(self._value == nil, ("expected %s to be nil"):format(repr(self._value)))
	return self
end

function Expectation:beType(t: string): any
	self:_check(type(self._value) == t, ("expected type %s, got %s"):format(t, type(self._value)))
	return self
end

function Expectation:beGreaterThan(n: number): any
	self:_check(self._value > n, ("expected %s > %s"):format(tostring(self._value), tostring(n)))
	return self
end

function Expectation:beGreaterOrEqual(n: number): any
	self:_check(self._value >= n, ("expected %s >= %s"):format(tostring(self._value), tostring(n)))
	return self
end

function Expectation:beLessThan(n: number): any
	self:_check(self._value < n, ("expected %s < %s"):format(tostring(self._value), tostring(n)))
	return self
end

function Expectation:beLessOrEqual(n: number): any
	self:_check(self._value <= n, ("expected %s <= %s"):format(tostring(self._value), tostring(n)))
	return self
end

function framework.expect(value: any): any
	return Expectation.new(value)
end

function framework.run(): boolean
	local pass, fail = 0, 0
	local failures: { string } = {}
	for _, suite in suites do
		print(("\n• %s"):format(suite.name))
		for _, test in suite.tests do
			if suite.beforeEach then
				suite.beforeEach()
			end
			local ok, err = pcall(test.body)
			if suite.afterEach then
				suite.afterEach()
			end
			if ok then
				pass += 1
				print(("    ✓ %s"):format(test.name))
			else
				fail += 1
				local line = ("    ✗ %s — %s"):format(test.name, tostring(err))
				print(line)
				table.insert(failures, ("[%s] %s\n  %s"):format(suite.name, test.name, tostring(err)))
			end
		end
	end
	print(("\n%d passed, %d failed"):format(pass, fail))
	if fail > 0 then
		print("\n--- failures ---")
		for _, f in failures do
			print(f)
		end
	end
	return fail == 0
end

return framework
