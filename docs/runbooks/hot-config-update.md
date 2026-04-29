# Runbook: Ship a hot config update

Reef Tycoon supports live tuning via `LiveConfigService`, which polls a
JSON blob from a DataStore every few minutes and applies overrides to
fish stats, drop weights, and event windows without redeploying the
place.

## Update flow

1. Edit the live-config JSON locally:
   - Drop weights live under `rarity.weights`
   - Event windows live under `events.<eventId>.start_at` /
     `events.<eventId>.end_at` (unix seconds, server time)
   - New event fish (limited-time exclusives) live under
     `fish.event.<fishId>`
2. Validate the JSON in your editor — `LiveConfigService` rejects malformed
   blobs and falls back to the previous good config. Watch for the
   `[LiveConfig] applied vN` line in server logs.
3. Upload the new blob via the Open Cloud DataStore API (or the helper
   script at `tools/upload-live-config.luau`):
   ```
   POST https://apis.roblox.com/datastores/v1/universes/<universeId>/standard-datastores/datastore/entries/entry
       ?datastoreName=ReefTycoon_LiveConfig_v1
       &entryKey=current
       Authorization: x-api-key <your-cloud-key>
       Body: { "version": <next-int>, ... }
   ```
4. Wait up to `LiveConfigService.POLL_INTERVAL_SECONDS` (default 300s)
   for live servers to pick it up. Check `#announcements` if any server
   logs warn about the new version.

## Rollback

If a config change causes a regression (e.g. a fish weight that breaks
pity, an event window in the past):

1. Re-upload the previous version with the same key (`current`).
2. Bump the `version` field so live servers re-apply.
3. The next poll (≤5 min) reverts the change. No restart needed.

## What NOT to put in live config

- Anything that changes save schema. Schema versions are bumped via a
  proper code release with a migration in `DataMigrations.MIGRATIONS`.
- Anything that changes monetization IDs or prices. Those need a Creator
  Hub update plus a Config.luau bump.
- Code or callable behavior. Live config is data only; trying to ship
  Lua through it is a foot-gun and will be rejected by the validator.
