# Runbook: DataStore failure

**Symptom:** Players join and report missing cash / inventory / progress.
The Discord webhook fires `data_load_recovered > 1%`, or you see
`[DataService] primary load failed` in the live logs.

## Triage

1. Check [Roblox Status](https://status.roblox.com/). DataStore outages
   are usually platform-wide. If Roblox is degraded, post in
   `#announcements`: "We're seeing intermittent save issues from a
   Roblox-side outage. Your progress is safe — we have hourly snapshots
   and will recover it as the platform comes back."
2. If only Reef Tycoon is affected, run `LeaderboardService.GetTopCash`
   from the Studio command bar against the live universe to confirm
   reads work at all.
3. Pull recent audit rows:
   ```
   local store = game:GetService("DataStoreService"):GetDataStore("ReefTycoon_Audit_v1")
   local pages = store:ListKeysAsync()
   ```
   Look for spikes of `data_load_failed` in the last hour.

## Recovery

Reef Tycoon writes a snapshot copy to `ReefTycoon_Player_Snapshot_v1`
hourly. `DataService.load` already falls back to the snapshot store when
the primary fails, so most players will recover automatically on the
next session. For players who lost more than the most recent hour:

1. Open the Open Cloud DataStore explorer (Creator Hub → Develop →
   DataStores → `ReefTycoon_Player_Snapshot_v1`).
2. Locate the user's key (`u_<UserId>`).
3. Copy the snapshot blob.
4. Paste it into the primary key (`ReefTycoon_Player_v1` → `u_<UserId>`).
5. Kick the player from the live server so they re-load on next join:
   ```
   game.Players:GetPlayerByUserId(<id>):Kick("Save restored. Please rejoin.")
   ```

## Communication

While the outage is ongoing:

- Pin a status banner in `#announcements` describing the issue.
- Reply to support tickets with the recovery ETA.
- Do **not** issue Robux refunds — Roblox owns the payment side. Direct
  refund requests to Roblox support.

## Post-mortem

Once recovered, log:

- Number of affected sessions
- Number recovered automatically vs by hand
- Time from first alert to all-clear
- Any code changes that need to land (e.g. tighten the snapshot cadence)
