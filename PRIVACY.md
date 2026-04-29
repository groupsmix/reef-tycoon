# Privacy Policy — Reef Tycoon

**Effective date:** 2025-01-01
**Last updated:** 2025-01-01

Reef Tycoon ("we", "us", "the game") is a Roblox experience operated by
groupsmix. This policy explains what data we collect, how we use it, and
your rights. Reef Tycoon runs entirely on the Roblox platform, so Roblox's
own [Privacy Notice](https://en.help.roblox.com/hc/articles/115004630823)
governs most data handling. This document covers data we collect on top of
that.

## 1. Who we are

groupsmix, the developer of Reef Tycoon. Contact us via the Roblox
experience page or the repository owner on GitHub.

## 2. What data we collect

We only collect data necessary to run the game. We do NOT ask for real
names, email addresses, phone numbers, home addresses, payment card
details, or any government-issued identifiers. All payments are handled
entirely by Roblox.

Data we store on Roblox DataStores, keyed by your Roblox `UserId`:

- **Game progress** — cash, gems, lifetime cash, prestige level, tank
  slots, placed tanks, fish inventory, gacha roll counters, tutorial
  completion, daily login streak.
- **Session metadata** — last seen timestamp, total playtime seconds,
  account creation timestamp (within the game).
- **Anti-cheat audit log** — events flagged by our cash-velocity detector
  (timestamp, event type, magnitude). Used only to investigate exploits.
- **Analytics events** — aggregated gameplay events (e.g. `session_start`,
  `egg_pulled`, `tutorial_done`) keyed by `UserId` and used to tune the
  game. We do NOT attach any personal information beyond the `UserId`.
- **Leaderboards** — your Roblox display name and lifetime cash appear on
  the top-10 leaderboard if you qualify.

## 3. What we do NOT collect

- We do not collect real names, email, postal address, phone number, IP
  address, or precise geolocation.
- We do not collect payment information — Roblox handles all transactions.
- We do not sell, rent, or share your data with advertisers or data
  brokers.
- We do not use third-party analytics SDKs outside of Roblox's own
  platform services.

## 4. How we use your data

- **To run the game:** load your save, grant offline earnings, replicate
  state to your client.
- **To prevent cheating:** detect abnormal cash velocity and suspend
  exploiters.
- **To improve the game:** aggregate analytics help us balance drop rates
  and pricing.
- **To show leaderboards:** your display name and cash rank.

We do NOT use your data for advertising, profiling for non-game purposes,
or automated decisions that have legal effects on you.

## 5. Data retention

- **Active saves** are retained for as long as you play the experience.
- **Snapshots** are retained indefinitely as disaster-recovery backups.
- **Anti-cheat audit entries** are retained for up to 90 days, after which
  they are rotated out.
- **Analytics events** are retained in aggregate; individual events are
  purged after 90 days.

## 6. Children's privacy

Roblox has robust protections for users under 13 (see Roblox's
[Children's Privacy Notice](https://en.help.roblox.com/hc/articles/360027658093)).
We operate within those constraints. We do not knowingly collect
additional data from children beyond what Roblox provides.

## 7. Your rights

Because we key all our data on Roblox `UserId`, and because Roblox handles
account-level data requests, the following applies:

- **Access:** you may request a copy of the data we store about your
  account by contacting us.
- **Deletion:** you may request deletion of your in-game save. We will
  honor the request within 30 days. If you delete your Roblox account,
  Roblox notifies us and we purge your data.
- **Correction:** contact us if you believe your data is inaccurate.
- **Objection / restriction:** you may request that we stop processing
  your data; doing so may prevent you from playing the game.

To exercise any right, message us on the Roblox experience page or open
an issue on the public GitHub repository.

## 8. Security

- Save data is stored in Roblox DataStores with server-side write
  authority. The client cannot mutate its own save directly.
- We maintain an hourly snapshot in a separate DataStore key for
  disaster recovery.
- Sensitive game logic (currency grants, gacha rolls, tank placement) is
  server-authoritative.

## 9. Third parties

We rely on the Roblox platform and its sub-processors for hosting,
storage, and payments. We do not integrate any third-party SDK, tracker,
or advertising service.

## 10. International transfers

Roblox operates globally and may store data in multiple jurisdictions.
See Roblox's privacy notice for specifics.

## 11. Changes to this policy

We may update this policy. Material changes will be announced in the
game's in-experience news panel and in the repository changelog. The
"Last updated" date above reflects the latest revision.

## 12. Contact

Open an issue on <https://github.com/groupsmix/reef-tycoon/issues> or
message us on the Roblox experience page.
