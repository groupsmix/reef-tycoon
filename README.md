# Reef Tycoon

Idle / incremental aquarium tycoon for Roblox. Built solo with AI-assisted tooling. See [`design.md`](./design.md) for the full game design doc.

> **Status (v0.2.0):** Production-ready scaffold. Server auto-builds the lobby (12 plots, pedestals, water, lighting), tanks render programmatically with animated fish, NPC visitors walk between tanks tipping cash, gacha cinematic with particles + camera shake + sound stingers, daily login reward, tutorial onboarding, server-wide Legendary marquee, anti-cheat (cash-velocity detection + audit log), schema-versioned saves with snapshot fallback, structured analytics, leaderstats + OrderedDataStore top-10, badges + sound system gracefully no-op when their asset IDs are 0.

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

## Lint + build locally

```bash
selene src
stylua --check src
rojo build default.project.json -o build/ReefTycoon.rbxlx
```

CI (`.github/workflows/ci.yml`) runs all three on every PR.

## Schema migrations

`DataService.luau` carries a `MIGRATIONS` table keyed by integer schema version. To bump the schema:

1. Increase `Config.SCHEMA_VERSION` by 1.
2. Add a function under that key that mutates an old profile in-place, defaulting any new fields. Migrations must be idempotent.
3. Update `newProfile()` to include the new defaults so fresh saves have them too.

`migrate(profile)` walks `from + 1 .. CURRENT` and applies each in order, then bumps `profile.schemaVersion`.
