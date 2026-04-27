# Reef Tycoon

Idle / incremental aquarium tycoon for Roblox. Built solo with AI-assisted tooling (Claude Code + Roblox Agentic Assistant + Cube 4D). See [`design.md`](./design.md) for the full game design doc.

> **Status:** Week 1 MVP scaffold. Server services, shared data tables, client UI scaffolding, monetization wiring, anti-cheat, save/load. Still requires: Cube 4D meshes for fish, lobby build (free Toolbox assets), gamepass + dev product IDs from Creator Hub, public launch.

## Quickstart

You need [Rokit](https://github.com/rojo-rbx/rokit) installed (it manages Rojo, Selene, and StyLua).

```bash
rokit install
rojo serve
```

Then in Roblox Studio:

1. Install the Rojo Studio plugin (one-time).
2. Click *Connect* to localhost:34872.
3. Live-edit. The full place tree is replicated from `src/`.

To produce a static `.rbxlx` place file:

```bash
rojo build default.project.json -o ReefTycoon.rbxlx
```

Open that file in Studio and publish to your experience.

## Project layout

```
src/
├── server/                      # ServerScriptService.ReefTycoon
│   ├── Main.server.luau         # Bootstrap: starts services in dependency order
│   └── Services/
│       ├── DataService.luau         # DataStore save/load + hourly snapshot + BindToClose
│       ├── EconomyService.luau      # Server-authoritative cash + gems
│       ├── TankService.luau         # Place / remove tanks, ownership
│       ├── VisitorService.luau      # NPC visitors, pathing, tip generation
│       ├── GachaService.luau        # Weighted roll + pity timer + audit log
│       ├── MonetizationService.luau # Gamepass + dev product fulfillment
│       └── PrestigeService.luau     # Rebuild Reef multiplier
│
├── shared/                      # ReplicatedStorage.Shared
│   ├── Config.luau              # All tunables (drop rates, prices, IDs, cadences)
│   ├── FishData.luau            # 30 species
│   ├── TankData.luau            # 5 tank tiers
│   ├── RarityData.luau          # 6 rarities + colors
│   ├── GamepassData.luau
│   ├── DevProductData.luau
│   ├── Remotes.luau             # RemoteEvent / RemoteFunction registry
│   ├── Signal.luau              # Lightweight signal class
│   └── Util/
│       ├── RateLimiter.luau
│       └── WeightedRandom.luau
│
└── client/                      # StarterPlayerScripts.ReefTycoon
    ├── Main.client.luau
    └── Controllers/
        ├── HudController.luau
        ├── ShopController.luau
        ├── InventoryController.luau
        └── GachaController.luau
```

## What still needs to happen in Studio (not in code)

- **Cube 4D mesh generation** for the 30 species in `FishData.luau`. Set `meshAssetId` on each entry once generated.
- **Lobby build** — drop a free reef/beach asset from the Toolbox into Workspace and create a folder named `TankPedestals` containing the placement parts.
- **Monetization IDs** — create gamepasses + dev products in Creator Hub, paste IDs into `src/shared/Config.luau`.
- **Place settings** — server size 12, FilteringEnabled true (default in `default.project.json`).

## Lint + build locally

```bash
selene src
stylua --check src
rojo build default.project.json -o build/ReefTycoon.rbxlx
```

CI (`.github/workflows/ci.yml`) runs all three on every PR.
