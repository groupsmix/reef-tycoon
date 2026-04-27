# Reef Tycoon — Game Design Doc (v0.1)

> **Working title.** Lock the real name on Day 1 across Roblox group, TikTok, IG, YouTube before public launch.

## 1. Pitch

Reef Tycoon is an idle / incremental aquarium curator on Roblox. Players place tanks, attract visitors, collect rare fish via gacha-style "egg" pulls, and prestige-reset for permanent multipliers.

## 2. Core Loop

```
place tank ──► visitors arrive ──► visitors tip cash ──► buy eggs ──► roll fish
     ▲                                                                   │
     └────────────────── upgrade tanks / unlock biomes ◄──────────────────┘
                              │
                              └──► prestige ("Rebuild Reef") ──► +X% perm. tip multiplier
```

Session shape:

- **First 90 seconds**: place starter tank, get first Common fish, see first tip.
- **First 5 minutes**: open first egg, hit at least Uncommon, unlock 2nd tank slot.
- **First session (~20 min)**: see at least one Rare, fill 4–5 slots, buy first gamepass-curious upgrade.
- **Day 2 retention hook**: offline earnings + a "daily Mythic streak" claim.

## 3. Rarity Table

| Tier      | Drop Rate | Tips/sec multiplier | Color    | Pull-screen treatment                 |
| --------- | --------- | ------------------- | -------- | ------------------------------------- |
| Common    | 45.0%     | 1×                  | Gray     | Plain fade-in.                        |
| Uncommon  | 28.0%     | 2.83×               | Green    | Soft glow.                            |
| Rare      | 15.0%     | 7.94×               | Blue     | Beam of light.                        |
| Epic      | 8.0%      | 22.4×               | Purple   | Screen darkens, particles.            |
| Mythic    | 3.0%      | 63.0×               | Gold     | Lightning, screen shake, name reveal. |
| Legendary | 1.0%      | 178×                | Rainbow  | Full cinematic, server-wide announce. |

Multiplier is `(tier_index ^ 2.5)` rounded with `tier_index` 1..6.

**Pity timer:**

- Guaranteed Epic+ every **50** eggs without one.
- Guaranteed Mythic every **200** eggs without one.

## 4. Tank Tiers

| Tier        | Cost (cash) | Visitor capacity | Tip multiplier | Slot cap |
| ----------- | ----------- | ---------------- | -------------- | -------- |
| Starter     | 100         | 1                | 1×             | 1 fish   |
| Premium     | 2,500       | 3                | 1.5×           | 3 fish   |
| Luxury      | 50,000      | 8                | 2.5×           | 6 fish   |
| Mythic      | 1,000,000   | 20               | 5×             | 10 fish  |
| Reef God    | 25,000,000  | 50               | 10×            | 20 fish  |

Players have N tank pedestals starting at 4, going up via tank-slot gamepass / cash buys.

## 5. Species (30 at launch)

5 species per tier × 6 tiers = 30. Names use generic / made-up Latin to avoid IP issues.

- Common (5): Reef Tetra, Sand Goby, Glow Guppy, Coral Damsel, Pebble Wrasse
- Uncommon (5): Lantern Tang, Dawn Cardinal, Moss Pleco, Sunset Anthias, Whisper Blenny
- Rare (5): Glass Lionfish, Ember Surgeon, Velvet Mandarin, Saber Tang, Chrome Triggerfish
- Epic (5): Aurora Boxfish, Frostfin Grouper, Stormcoat Eel, Twilight Seahorse, Prism Wrasse
- Mythic (5): Glass Leviathan, Magma Manta, Astral Octopus, Bloom Jellyfish, Halo Angelshark
- Legendary (5): Reef God Koi, Eclipse Dragon, Aurora Phoenixfish, Tideshaper Whale, Crystal Krakenfish

## 6. Monetization

### Gamepasses (one-time)

| Pass                              | R$  |
| --------------------------------- | --- |
| 2× Tips Forever                   | 499 |
| Auto-Collect Tips                 | 299 |
| VIP (badge + chat tag + cosmetic) | 999 |
| 3× Luck on Eggs                   | 799 |
| +10 Tank Slots                    | 399 |

### Dev products (consumable)

| Product                            | R$    |
| ---------------------------------- | ----- |
| 1,000 Gems                         | 99    |
| 5,500 Gems                         | 499   |
| 12,000 Gems                        | 999   |
| 30,000 Gems                        | 2,499 |
| 75,000 Gems                        | 4,999 |
| Single Mythic Egg (guaranteed M+)  | 1,499 |
| Event Pass (limited fish unlock)   | 799   |

Target revenue split: 65% dev products / 25% gamepasses / 10% events.

## 7. Prestige ("Rebuild Reef")

- Unlocked at first $1M lifetime tips earned.
- Wipes cash + non-Mythic+ fish + tanks.
- Grants `+10% permanent tip multiplier per prestige`, capped at 100 prestiges (+1000%).
- Mythic and Legendary fish are kept as a trophy collection ("Reef Hall of Fame").

## 8. Live-Ops Cadence

- **Monday**: 1 new species, weighted toward Rare/Epic.
- **Friday (biweekly)**: limited 7-day event biome with 5 exclusive fish.
- **Monthly**: a new full biome OR new prestige tier OR 10-fish content pack.

## 9. Anti-cheat / Server Authority

- All currency mutations live in `EconomyService` and never trust client values.
- Egg opens are rate-limited (max 5/sec/player burst, 60/min sustained).
- Inventory is server state; client only renders.
- DataStore writes use a primary + hourly snapshot key.
- Audit log entries: `{ userId, action, payload, t }` for every Mythic+ pull, every prestige, every dev-product fulfillment.

## 10. Out-of-scope at launch (future work)

- Trading (month 3+)
- PvP / raids
- Friend / guild systems
- Pets / companions
- Additional biomes beyond Tropical Reef
