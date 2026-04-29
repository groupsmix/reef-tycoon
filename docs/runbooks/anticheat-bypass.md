# Runbook: Cheat bypassed AntiCheat

**Symptom:** A player has impossibly high cash, is on the leaderboard
with a value above the theoretical max, or another player reports them.
The Discord webhook may also fire `AC kicks > 10/hr` if a related exploit
is being tested but not catching everyone.

## Confirm the bypass

1. Pull the player's profile from `ReefTycoon_Player_v1` (key
   `u_<UserId>`). Note their current `cash`, `lifetimeCash`, and
   `gacha.totalRolls`.
2. Compute the theoretical max gain since `createdAt` using:
   ```
   max_per_sec = 500_000  -- see AntiCheatService.lua header
   max_total   = max_per_sec * (now - createdAt)
   ```
   If `lifetimeCash > max_total`, the player has gained cash faster
   than the legit ceiling. Confirmed cheat.
3. Pull all audit rows for that user:
   ```
   local store = game:GetService("DataStoreService"):GetDataStore("ReefTycoon_Audit_v1")
   for _, key in store:ListKeysAsync():GetCurrentPage() do
       if key.KeyName:match("^u_<UserId>_") then ... end
   end
   ```
   Look for `cash_velocity_kick` rows. If there are none, the exploit is
   slow-cooked enough to pass the per-event check; the periodic 5s
   sweep should catch it next time.

## Manual ban

Ban the player by writing to the bans store:

```
local banStore = game:GetService("DataStoreService"):GetDataStore("ReefTycoon_Bans_v1")
banStore:SetAsync("ban_<UserId>", { reason = "cash_velocity", t = os.time() })
```

`AntiCheatService.loadBan` will pick this up on next join and kick them.

## Reset their profile (optional)

If you want to keep the account but wipe the cheated cash:

```
local primary = game:GetService("DataStoreService"):GetDataStore("ReefTycoon_Player_v1")
primary:UpdateAsync("u_<UserId>", function(p)
    if p then
        p.cash = 0
        p.lifetimeCash = 0
        -- keep inventory if you want to be merciful
    end
    return p
end)
```

## Tighten the threshold

If the exploit was caught **after** the bypass:

1. Inspect the audit rows. What rate did the cheater sustain?
2. If it was below `KICK_THRESHOLD` (currently 2.5M cash/sec), lower the
   threshold in `AntiCheatService.luau` and ship a hotfix.
3. Remember to leave headroom (5x the theoretical max) so legitimate
   max-prestige max-tanks players are never kicked.

## Communicate

- Do **not** publicly call out the cheater on Discord.
- Reply to bug reports with: "We've banned the account and tightened
  the detection. Please continue to report exploits — we appreciate it."
- Log the incident in `docs/runbooks/incidents.md` (date, exploit type,
  fix, time to resolve).
