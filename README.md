# Reef Tycoon

Idle / incremental aquarium tycoon for Roblox. Built solo with AI-assisted tooling. See [`design.md`](./design.md) for the full game design doc.

> **Status (v0.3.0):** Feature-complete pre-launch scaffold. Server auto-builds the lobby (12 plots, pedestals, water, lighting), tanks render programmatically with animated fish, NPC visitors walk between tanks tipping cash, gacha cinematic with particles + camera shake + sound stingers, daily login reward, tutorial onboarding, server-wide Legendary marquee, anti-cheat (cash-velocity detection + audit log), schema-versioned saves with snapshot fallback, idempotent receipt fulfillment, structured analytics, leaderstats + OrderedDataStore top-10 with client UI, badges + sound system gracefully no-op when their asset IDs are 0. Pure-logic services (economy, gacha pity, data migrations, anti-cheat thresholds, receipt dedup) are covered by unit tests run on every PR.
>
> **Before public launch:** create the gamepasses, dev products, badges, and sound IDs in Creator Hub and paste them into [`src/shared/Config.luau`](./src/shared/Config.luau). Without those IDs the relevant systems intentionally no-op. See [`docs/runbooks/`](./docs/runbooks) for live-ops procedures.

## Quickstart

You need [Rokit](https://github.com/rojo-rbx/rokit) installed (it manages Rojo, Selene, and StyLua).

```bash
rokit install
rojo serve
```

Then in Roblox Studio:

1. Install the Rojo Studio plugin (one-time).
2. Click *Connect* to localhost:34872.
3. Press Play. The lobby auto-generates, you spawn at the central pad, are teleported onto a free plot, and a ProximityPrompt on each pedestal lets you place a tank.

To produce a static `.rbxlx` place file:

```bash
rojo build default.project.json -o ReefTycoon.rbxlx
```

Open that file in Studio and publish to your experience.

## Project layout

```
src/
├── server/                                # ServerScriptService.ReefTycoon
│   ├── Main.server.luau                   # Bootstrap: starts services in dependency order
│   └── Services/
│       ├── DataService.luau               # DataStore save/load, hourly snapshot, BindToClose, schema migrations
│       ├── EconomyService.luau            # Server-authoritative cash + gems with CashChanged signal
│       ├── WorldService.luau              # Programmatic lobby (12 plots, water, pedestals, lighting)
│       ├── TankService.luau               # Place / remove tanks, slot ownership
│       ├── TankRenderService.luau         # Glass tank parts + animated fish parts on pedestals
│       ├── PlacementService.luau          # ProximityPrompt wiring on pedestals + tank stands
│       ├── VisitorService.luau            # Visitor tip economics + offline earnings
│       ├── VisitorRenderService.luau      # NPC visitors walking + emitting tip particles
│       ├── GachaService.luau              # Weighted roll + 50/200 pity + audit log
│       ├── MonetizationService.luau       # Gamepass + dev product fulfillment
│       ├── PrestigeService.luau           # Rebuild Reef multiplier
│       ├── BadgeService.luau              # Awards Roblox badges on milestones
│       ├── AnalyticsService.luau          # Structured event log batched to DataStore
│       ├── AntiCheatService.luau          # Cash-velocity detection + auto-kick + audit
│       ├── DailyRewardService.luau        # Login streak, escalating gem rewards, 20h cooldown
│       ├── LeaderboardService.luau        # leaderstats + OrderedDataStore top-10 cash
│       └── SoundService.luau              # Named Sounds in SoundService (ambient, music, SFX)
│
├── shared/                      # ReplicatedStorage.Shared
│   ├── Config.luau              # All tunables (drop rates, prices, IDs, cadences, badge/sound IDs)
│   ├── FishData.luau            # 30 species
│   ├── TankData.luau            # 5 tank tiers
│   ├── RarityData.luau          # 6 rarities + colors
│   ├── GamepassData.luau
│   ├── DevProductData.luau
│   ├── Remotes.luau             # RemoteEvent / RemoteFunction registry
│   ├── Signal.luau
│   └── Util/{RateLimiter,WeightedRandom}.luau
│
└── client/                                # StarterPlayerScripts.ReefTycoon
    ├── Main.client.luau
    └── Controllers/
        ├── LoadingController.luau         # Covers UI until catalog + snapshot received
        ├── HudController.luau             # Cash / Gems / Prestige / Slots top bar
        ├── ShopController.luau            # Tanks, Gems, Passes tabs + pity progress
        ├── InventoryController.luau       # Rarity-sorted fish grid
        ├── GachaController.luau           # Pull cinematic: particles + camera shake + sound
        ├── DailyRewardController.luau     # Daily streak claim button
        ├── TutorialController.luau        # 3-step new-player onboarding
        ├── LegendaryMarqueeController.luau # Server-wide Legendary banner
        └── OfflineEarningsController.luau # Welcome-back panel
```

## What still needs to happen in Studio / Creator Hub (not in code)

- **Monetization IDs** — create gamepasses + dev products in Creator Hub, paste IDs into [`src/shared/Config.luau`](./src/shared/Config.luau) under `GAMEPASS_IDS` and `DEV_PRODUCT_IDS`.
- **Badge IDs** — create the 5 milestone badges, paste IDs into `Config.BADGE_IDS`. Code gracefully no-ops while IDs = 0.
- **Sound asset IDs** — upload (or pick free Toolbox sounds) for ambient ocean, bubbles, chill music, tip ping, egg pop, mythic stinger, legendary stinger. Paste IDs into `Config.SOUND_IDS`. Code gracefully silences while IDs = 0.
- **Cube 4D fish meshes** (optional polish) — generate 30 species with a consistent prompt prefix, paste each `meshAssetId` into [`src/shared/FishData.luau`](./src/shared/FishData.luau). Without these, fish render as rarity-colored neon spheres with a glow PointLight (still feels alive thanks to the swim animation).
- **Place settings** — `server size 12` is set by default. Enable `EnableStudioAccessToApiServices` in Studio if you want DataStores to work locally.

## Lint + build + test locally

```bash
selene src
stylua --check src
rojo build default.project.json -o build/ReefTycoon.rbxlx
lune run tests/run.luau
```

CI (`.github/workflows/ci.yml`) runs all four on every PR.

Unit tests live under `tests/specs/` and target the pure-logic modules in `src/shared/` (data migrations, gacha pity, anti-cheat thresholds, receipt idempotency, economy mutations, rate limiter, weighted random). They run under [Lune](https://github.com/lune-org/lune) — no Roblox runtime required. The framework lives in `tests/framework.luau` (~150 lines, TestEZ-shaped describe/it/expect).

## Schema migrations

The `MIGRATIONS` table lives in [`src/shared/DataMigrations.luau`](./src/shared/DataMigrations.luau) so it can be unit-tested without a Roblox runtime. To bump the schema:

1. Increase `Config.SCHEMA_VERSION` by 1.
2. Add a function under that key in `DataMigrations.MIGRATIONS` that mutates an old profile in-place, defaulting any new fields. Migrations must be idempotent.
3. Update `newProfile()` in `DataService.luau` to include the new defaults so fresh saves have them too.
4. Add a test under `tests/specs/DataMigrations.spec.luau` that runs the migration twice and asserts no double-mutation.

`DataMigrations.run(profile, targetVersion, prestigeBonus)` walks `from + 1 .. CURRENT` and applies each in order, then bumps `profile.schemaVersion` and re-applies defensive defaults.

## Runbooks

Live-ops procedures live under [`docs/runbooks/`](./docs/runbooks):
- [DataStore failure](./docs/runbooks/datastore-failure.md)
- [Anti-cheat bypass](./docs/runbooks/anticheat-bypass.md)
- [Hot config update](./docs/runbooks/hot-config-update.md)

## Legal

- [LICENSE](./LICENSE) — All Rights Reserved (proprietary)
- [PRIVACY.md](./PRIVACY.md) — what we store, how it's used
- [TERMS.md](./TERMS.md) — acceptable use + Robux refund policy
