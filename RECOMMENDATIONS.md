# Reef Tycoon — Pre-Launch Recommendations

This document tracks work that is **not** covered by the codebase but **is required** before a public launch on Roblox. None of these items can be done by editing source files alone — they require Roblox Studio, Creator Hub, or external services.

Tackle them in roughly this order. Items are tagged P0 (blocks launch) → P3 (nice-to-have).

---

## P0 — Blocks public launch

### 1. Mobile UI pass — needs Studio runtime testing

The HUD, shop, inventory, and gacha modals were authored for desktop dimensions. Roblox is **~70% mobile**. Without a tuning pass, thumb tap targets, top-bar safe area, and modal scaling will all be wrong on phones.

**To do:**
- Open `ReefTycoon-starter.rbxlx` in Studio.
- Run **Test → Device** and rotate through: iPhone Portrait, iPhone Landscape, iPad, Tablet, 1080p TV.
- For each frame, verify:
  - Top HUD does not collide with the Roblox top bar (set `IgnoreGuiInset = false` if needed).
  - All buttons are at least 44×44 px tall in the rendered output (tap target minimum).
  - Modals (gacha pull cinematic, daily reward, tutorial) do not overflow the screen.
  - Text scales legibly at the lowest resolution.
- Tweak `UDim2` sizes in `src/client/Controllers/*.luau` accordingly. Most controllers use absolute pixels; consider switching critical ones to `UDim.new(scale, offset)` form for resolution independence.

**Effort:** 1–2 hours of click-testing + a few targeted edits.

---

### 2. Game icon + launch trailer — outsource

Roblox's organic discovery is brutal without good first-impression art. The plan budgets **$60 + $250 on Fiverr** — do not skip this.

**To do:**
- **Game icon (512×512 PNG):** Search Fiverr for "Roblox game icon". Brief: "Cute aquarium tycoon. Small fish in a bubbly glass tank, vibrant colors, cartoony, eye-catching at 64×64 thumbnail size." Budget $40–$80.
- **Launch trailer (15–30s, 1080p):** Search Fiverr for "Roblox game trailer". Brief: "Fast-paced cuts of fish pulls (Mythic + Legendary), tank placement, visitor tipping, prestige animation. End on game name + 'Out Now' + a logo." Budget $200–$400.
- Upload icon at: [Creator Hub → your experience → Configure Place → Game Icon].
- Upload trailer at: [Creator Hub → your experience → Configure Place → Trailer].

**Effort:** 1–2 days of Fiverr turnaround.

---

### 3. Monetization + badge + sound IDs — Creator Hub

The code has stubs for all of these. Until the IDs are filled in:

- No one can spend Robux on the game (gamepasses + dev products).
- No one can earn the milestone badges (welcome, first Mythic, first Legendary, first Prestige, Prestige 10).
- The game is silent (ambient ocean, music, bubbles, tip pings, egg pop, stingers).

**To do:**

#### 3a. Gamepasses (5)
Create at: [Creator Hub → your experience → Monetization → Passes].

| Name | Price (R$) | Description |
|------|-----------|-------------|
| 2× Tips Forever | 499 | Permanently doubles all visitor tip income. |
| Auto-Collect Tips | 299 | Tips deposit directly to your balance. |
| VIP Badge + Chat Tag + Exclusive Fish | 999 | VIP role, special tag, and the "Reef VIP" exclusive fish. |
| 3× Luck on Fish Eggs | 799 | Triples your Rare+ chance on every egg pull. |
| +10 Tank Slots | 399 | Permanently raises your tank slot cap by 10. |

Paste the IDs into `Config.GAMEPASS_IDS` in `src/shared/Config.luau`.

#### 3b. Developer products (7)
Create at: [Creator Hub → your experience → Monetization → Developer Products].

| Name | Price (R$) |
|------|-----------|
| Small Gem Pack (1,000 gems) | 99 |
| Medium Gem Pack (5,500 gems) | 499 |
| Large Gem Pack (12,000 gems) | 999 |
| Mega Gem Pack (30,000 gems) | 2,499 |
| Whale Gem Pack (75,000 gems) | 4,999 |
| Single Mythic Egg (guaranteed Mythic+) | 1,499 |
| Event Pass (limited-time exclusive fish) | 799 |

Paste the IDs into `Config.DEV_PRODUCT_IDS` in `src/shared/Config.luau`.

#### 3c. Badges (5)
Create at: [Creator Hub → your experience → Badges].

| Badge | Trigger |
|-------|---------|
| Welcome to the Reef | Issued on first session. |
| First Mythic | Issued on first Mythic+ pull. |
| First Legendary | Issued on first Legendary pull. |
| Reef Reborn | Issued on first prestige. |
| Apex Curator | Issued at prestige level 10. |

Paste the IDs into `Config.BADGE_IDS`. Code gracefully no-ops while IDs = 0.

#### 3d. Sounds (7)
Either upload your own to Creator Hub or pick free Toolbox sounds.

| Constant | Suggested asset |
|----------|----------------|
| `AMBIENT_OCEAN` | Looping underwater drone, low volume. |
| `BUBBLES` | Looping bubble crackle, low volume. |
| `MUSIC_CHILL` | Lo-fi beach loop. |
| `TIP` | Coin/cash register ping. |
| `EGG_POP` | Gentle pop / chime when an egg cracks. |
| `MYTHIC_STINGER` | Synth swell, cinematic, ~1s. |
| `LEGENDARY_STINGER` | Triumphant brass + bass drop, ~1.5s. |

Paste the IDs into `Config.SOUND_IDS`. Code gracefully silences while IDs = 0.

**Effort:** 1–2 hours total in Creator Hub.

---

### 4. Real fish meshes — Cube 4D in Studio

Currently fish render as rarity-colored neon spheres with a glow. Functional, but sub-50th-percentile visually. To hit the top-1% bar, generate proper meshes.

**To do:**

- Open the place in Studio.
- Use the **Cube 4D mesh generator** (in-Studio AI tool) with a consistent style prefix:
  > `low-poly cartoon reef fish, bright vivid color, 0.6 studs long, side-profile silhouette, soft outline`
- Generate one mesh per species (30 total). Append the species' descriptor (e.g., `glow guppy`, `coral angelfish`, `prismatic moray`).
- For each generated mesh, copy its `assetId` into the corresponding `meshAssetId` field in `src/shared/FishData.luau`.
- (Alternative if Cube 4D is unavailable / quality is poor): browse the Roblox Toolbox for free reef fish models and paste the `assetId` of each. Search terms: "tropical fish", "reef fish", "cartoon fish".

**Effort:** 2–4 hours for 30 species.

---

## P1 — Strongly recommended before public launch

### 5. Run a private playtest

Per the original 90-day plan (Day 7): invite 3 friends, fix obvious bugs, verify the DataStore + visitor pathing + tip accumulation work as intended. Record one new-player session and time how long it takes them to grasp the core loop. If it's >2 minutes, the tutorial needs work.

### 6. Set up the Discord

- Channels: `#announcements`, `#trade-area-preview` (locked, future trading teaser), `#show-your-tank`, `#suggestions`, `#bugs`, `#events`, `#off-topic`.
- Founder role for the first 200 members + auto-DM with a code for an exclusive Legendary fish.

### 7. Pre-write 14 days of TikTok/Reels content

Sundays should be content-prep day per the plan. Batch-shoot 10 reels using the 10 hook formulas from the plan (pull reaction, collection progress, comment bait, tier list, beginner guide, etc.). Schedule them.

---

## P2 — Code-quality follow-ups (already opened or planned PRs)

These are tracked in GitHub PRs; merge in order:

- **PR #1** — Debounce snapshot replication (3 Hz) [perf]
- **PR #2** — Lazy plot build (per-player) [perf]
- **PR #3** — RemoteFunction arg validation + soft-ban list [anti-cheat]
- **PR #4** — Hot-loadable fish + rarity config via DataStore [content]

Future PRs to consider:
- Mobile UI pass (depends on #1 above).
- In-game leaderboard UI (the data is already written via `LeaderboardService`; just no UI yet).
- Localization scaffold (string table) — needed before MENA/LATAM creator outreach in Month 2.

---

## P3 — Nice-to-have

- **Purchase confirmation modals** on dev products ("Thanks for supporting the reef!").
- **Visitor density scales with tank tier** (Reef God plots feel busy, Starter plots feel sleepy).
- **Welcome-back panel** could play the sound stinger and animate cash counter, not just show a number.
- **Tutorial floating arrows** that physically point at the pedestal → egg button → inventory.

---

## Status checklist

Tick as you complete each:

- [ ] Mobile UI pass done in Studio
- [ ] Game icon uploaded
- [ ] Launch trailer uploaded
- [ ] Gamepass IDs filled in
- [ ] Dev product IDs filled in
- [ ] Badge IDs filled in
- [ ] Sound IDs filled in
- [ ] Fish meshes generated and IDs filled in
- [ ] Private playtest with 3 friends complete
- [ ] Discord set up
- [ ] First 14 days of TikTok content drafted
