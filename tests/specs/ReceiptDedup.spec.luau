--!strict
local ReceiptDedup = require("../../src/shared/ReceiptDedup")

return function(framework)
	local describe, it, expect = framework.describe, framework.it, framework.expect

	local function newStore()
		local data: { [string]: { [string]: boolean } } = {}
		local writes = 0
		return {
			data = data,
			writes = function()
				return writes
			end,
			get = function(playerKey: string, receiptId: string): boolean
				return (data[playerKey] or {})[receiptId] == true
			end,
			set = function(playerKey: string, receiptId: string)
				writes += 1
				data[playerKey] = data[playerKey] or {}
				data[playerKey][receiptId] = true
			end,
		}
	end

	describe("ReceiptDedup:Claim", function()
		it("returns true the first time a receipt is seen", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			expect(d:Claim("u_1", "r1")):beTrue()
		end)

		it("returns false on duplicate within the same session", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			d:Claim("u_1", "r1")
			expect(d:Claim("u_1", "r1")):beFalse()
		end)

		it("returns false when the persistent store already has the receipt", function()
			local store = newStore()
			-- simulate a prior server fulfilling and crashing before reply
			store.set("u_1", "r1")
			local d = ReceiptDedup.new(store :: any)
			expect(d:Claim("u_1", "r1")):beFalse()
		end)

		it("allows distinct receipts for the same player", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			expect(d:Claim("u_1", "r1")):beTrue()
			expect(d:Claim("u_1", "r2")):beTrue()
		end)

		it("isolates receipts across players", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			expect(d:Claim("u_1", "r1")):beTrue()
			expect(d:Claim("u_2", "r1")):beTrue()
		end)

		it("only writes to the persistent store on first claim", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			d:Claim("u_1", "r1")
			d:Claim("u_1", "r1")
			d:Claim("u_1", "r1")
			expect(store.writes()):equal(1)
		end)
	end)

	describe("ReceiptDedup:Forget", function()
		it("clears the in-memory cache for a player but not the persistent store", function()
			local store = newStore()
			local d = ReceiptDedup.new(store :: any)
			d:Claim("u_1", "r1")
			d:Forget("u_1")
			-- Persistent store still remembers, so Claim is still false
			expect(d:Claim("u_1", "r1")):beFalse()
		end)
	end)
end
