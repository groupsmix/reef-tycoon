--!strict
--[[
	ReceiptDedup — in-memory + persistent receipt-id idempotency tracker.

	MarketplaceService.ProcessReceipt MUST be idempotent: if we crash mid-
	grant and Roblox replays the receipt, we have to either grant once or
	be safe to grant a second time. We store every fulfilled receipt id
	per player. On every grant we check the store first and short-circuit
	if we've seen that id before.

	The actual DataStore writes are injected so this module stays pure
	and unit-testable. Pass a `store` table with .get(playerKey, receiptId)
	and .set(playerKey, receiptId) — both may be no-ops in tests.
]]

local ReceiptDedup = {}
ReceiptDedup.__index = ReceiptDedup

export type Store = {
	get: (playerKey: string, receiptId: string) -> boolean,
	set: (playerKey: string, receiptId: string) -> (),
}

function ReceiptDedup.new(store: Store)
	local self = setmetatable({
		_store = store,
		-- in-memory cache of already-fulfilled receipts to short-circuit
		-- without hitting the store on hot replays
		_seen = {} :: { [string]: { [string]: boolean } },
	}, ReceiptDedup)
	return self
end

local function ensure(t: { [string]: { [string]: boolean } }, k: string): { [string]: boolean }
	local existing = t[k]
	if not existing then
		existing = {}
		t[k] = existing
	end
	return existing
end

-- Returns true iff this receipt has NOT been fulfilled before (i.e. caller
-- should perform the grant). Returns false on duplicate.
function ReceiptDedup:Claim(playerKey: string, receiptId: string): boolean
	local mem = ensure(self._seen, playerKey)
	if mem[receiptId] then
		return false
	end
	if self._store.get(playerKey, receiptId) then
		mem[receiptId] = true
		return false
	end
	mem[receiptId] = true
	self._store.set(playerKey, receiptId)
	return true
end

function ReceiptDedup:Forget(playerKey: string)
	self._seen[playerKey] = nil
end

return ReceiptDedup
