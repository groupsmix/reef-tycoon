--!strict
local RateLimiter = require("../../src/shared/Util/RateLimiter")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	describe("RateLimiter", function()
		it("permits up to burst events", function()
			local r = RateLimiter.new({ burst = 3, sustained = 100, window = 60 })
			for _ = 1, 3 do
				expect(r:TryConsume(1)):beTrue()
			end
		end)

		it("isolates per-key", function()
			local r = RateLimiter.new({ burst = 1, sustained = 10, window = 60 })
			expect(r:TryConsume(1)):beTrue()
			expect(r:TryConsume(2)):beTrue()
		end)

		it("forgets cleanly", function()
			local r = RateLimiter.new({ burst = 1, sustained = 1, window = 60 })
			expect(r:TryConsume(1)):beTrue()
			r:Forget(1)
			expect(r:TryConsume(1)):beTrue()
		end)
	end)
end
