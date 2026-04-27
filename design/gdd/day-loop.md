# Day Loop / Campaign

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 (Chill Until It Isn't), Pillar 2 (Build Your Day)

## Overview

The Day Loop / Campaign system is the campaign controller for Proyecto Rome's 7-day run structure. It tracks the current day number (`game.currentDay`) and the active money target (`game.dailyTarget`), evaluating the player's `game.score` against that target each time the Game State Manager enters `day_end`. If the target is met and days remain, the Day Loop authorises the `day_end → buff_select` transition; if the target is missed, it authorises `day_end → gameover`. After the player selects a buff and `buff_select → play` fires, the Day Loop increments `game.currentDay`, updates `game.dailyTarget` to the next day's value, and applies any difficulty escalation before gameplay resumes. After day 7, the system enters endless mode — the target check continues with escalating targets until one is finally missed, ending the run. The Day Loop owns no display elements; it exposes `game.currentDay` and `game.dailyTarget` to the HUD and signals only the Game State Manager. All other systems remain unaware of day number or target values.

## Player Fantasy

The Day Loop / Campaign system is invisible infrastructure — the player never sees it, only feels what it produces. The fantasy it serves is *expertise under escalating pressure*: the restaurant gets harder to outrun each day, and a player who reaches day seven has learned to read the chaos before it peaks. The anchor moment is the mid-shift inflection — when a second wave of customers arrives faster than expected — and the player realises they planned for it: the right buff was already selected, the route is already optimised, and the surge is controlled rather than merely survived. This system primarily serves **Pillar 1 (Chill Until It Isn't)**: the Day Loop is the mechanism that makes "it isn't" true — the escalation it controls is what turns an approachable early shift into a demanding late one. Buff selection (Pillar 2) is the player's only lever to shape how that escalation lands on them personally.

## Detailed Design

### Core Rules

**Owned Variables**

1. The Day Loop owns four values on the shared `game` table: `game.currentDay` (int, 1–∞), `game.dailyTarget` (int, points), `game.isEndless` (bool), `game.campaignScore` (int, cumulative run total). No other system may write these values. All initialise in `resetGame()`.
2. The Day Loop also maintains `game.effective.spawnInterval` (number) and `game.effective.customerPatience` (number) — the active difficulty values the Customer System reads at spawn time. `config.SPAWN_INTERVAL` and `config.CUSTOMER_PATIENCE` are the Day 1 baseline and are never modified at runtime. `resetGame()` copies config values back to `game.effective.*`.
3. The Day Loop does not own `game.score`, `game.gameState`, or `game.gameTimer`. It reads `game.score` at `day_end`; it reads `game.gameState` to gate all logic. It never writes these.

**Daily Target Evaluation**

4. Target evaluation fires exactly once per `day_end`, on the first frame GSM enters that state. An internal guard flag (`day_loop.evaluated`, reset on `buff_select → play`) prevents re-evaluation on subsequent `day_end` frames.
5. At `day_end` evaluation, in this order: (a) add `game.score` to `game.campaignScore`, (b) compare `game.score` to `game.dailyTarget`, (c) signal GSM.
6. Evaluation logic:
   - If `game.score >= game.dailyTarget`:
     - If `game.currentDay == 7`: set `game.isEndless = true`
     - Signal GSM: `day_end → buff_select`
   - Else: Signal GSM: `day_end → gameover`
7. `game.isEndless` is set before `buff_select` is entered. Systems that read this flag during `buff_select` see the correct value.
8. The Day Loop is the ONLY system authorised to signal `day_end → buff_select` and `day_end → gameover`. Any other system triggering these transitions is a contract violation.

**Day Start (buff_select → play)**

9. On `buff_select → play`, actions run in this exact order: (1) Buff System applies the selected buff, (2) Day Loop increments `game.currentDay`, updates `game.dailyTarget` and `game.effective.*`, (3) `game.score` and `game.misses` reset to 0, (4) `game.gameTimer` resets to `config.GAME_TIME`. No other ordering is valid.
10. `game.currentDay` increments on `buff_select → play` — NOT at `day_end`. Evaluation at `day_end` always reads the current day's number, not the next.

**Fixed Target Table (campaign days 1–7)**

11. Daily money targets for the campaign, defined in `config.lua` as `DAILY_TARGETS`:

| Day | Target | Notes |
|-----|--------|-------|
| 1 | 400 pts | ~3–4 correct serves; winnable first attempt |
| 2 | 600 pts | ~5 correct serves |
| 3 | 850 pts | ~7 correct serves; penalties begin to matter |
| 4 | 1,100 pts | ~9 correct serves |
| 5 | 1,400 pts | ~11 correct serves; Score ×2 buff becomes valuable |
| 6 | 1,750 pts | ~13 correct serves |
| 7 | 2,100 pts | ~15–17 correct serves; near-optimal play required |

> Initial tuning values — must be validated by playtesting. Approximations assume ~120 pts avg per serve at ×1 multiplier. All values are achievable more easily with a Score ×2 buff active. Do not lock before at least one full playtested run.

**Endless Mode Targets (days 8+)**

12. In endless mode, daily targets are computed by formula: `game.dailyTarget = DAILY_TARGETS[7] + (game.currentDay − 7) × ENDLESS_TARGET_STEP`. `ENDLESS_TARGET_STEP` is defined in `config.lua` (initial value: 350 pts/day — steeper than the campaign avg step of ~283 pts/day). The run ends when this target is missed.

**Difficulty Escalation**

13. Two parameters escalate each day: `game.effective.spawnInterval` (decreasing) and `game.effective.customerPatience` (decreasing). No other parameters are modified by the Day Loop.
14. Escalation values for campaign days 1–7 are defined as arrays in `config.lua`: `ESCALATION_SPAWN[1..7]` and `ESCALATION_PATIENCE[1..7]`. The Day Loop reads the indexed value and writes it to `game.effective.*` on `buff_select → play`. Floors are enforced inside the Day Loop with one `math.max(floor, value)` call per parameter.

| Day | `game.effective.spawnInterval` | `game.effective.customerPatience` |
|-----|-------------------------------|----------------------------------|
| 1 | 4.0 s (config baseline) | 20.0 s (config baseline) |
| 2 | 3.6 s | 18.5 s |
| 3 | 3.2 s | 17.0 s |
| 4 | 2.9 s | 15.5 s |
| 5 | 2.6 s | 14.0 s |
| 6 | 2.4 s | 13.0 s |
| 7 | 2.2 s | 12.0 s |

Campaign floors: `spawnInterval ≥ 2.2 s`, `customerPatience ≥ 12.0 s`. Below 2.2 s spawn, six tables fill in under 14 seconds — too many simultaneous inputs. Below 12.0 s patience, a full-diagonal serve cycle becomes unreliable; this is timing pressure, not volume pressure (violates Pillar 1).

15. In endless mode (day > 7), escalation continues at a steeper step:
    - `spawnInterval` decreases 0.15 s/day (campaign avg: ~0.27 s/day)
    - `customerPatience` decreases 0.8 s/day (campaign avg: ~1.14 s/day)
    - Absolute endless floors: `spawnInterval ≥ 1.5 s`, `customerPatience ≥ 8.0 s`
    - Applied each day: `math.max(floor, previous − step)`
16. Escalation takes effect at the start of the new day's `play` state. Existing customers on the floor carry whatever patience they had at spawn; the new values apply to the next spawn only.

**Campaign Score**

17. `game.campaignScore` accumulates `game.score` from each completed day. It is added to at step (a) of Rule 5 (before `game.score` is evaluated against the daily target). It resets to 0 only on a new run (`menu → play`, `gameover → play`) — not on day start. It is the value displayed on the game-over screen as the player's final run score.

---

### States and Transitions

The Day Loop is **stateless event processing**. It has no internal state machine. It reacts to two GSM transition events:

| GSM Event | Day Loop Action |
|-----------|----------------|
| `play → day_end` | Accumulate campaign score → evaluate daily target → signal GSM. Guard prevents re-evaluation on subsequent `day_end` frames. |
| `buff_select → play` | Increment `game.currentDay` → update `game.dailyTarget` → write `game.effective.*` escalation values → reset `game.score`, `game.misses`, `game.gameTimer` (per Rule 9 ordering). |

During `play`, the Day Loop is completely idle. The GSM owns the timer and fires `play → day_end` autonomously when `game.gameTimer ≤ 0`.

---

### Interactions with Other Systems

| System | Direction | Data In | Data Out | Notes |
|--------|-----------|---------|----------|-------|
| **Game State Manager** | Read + signal | `game.gameState` (string) | `transitionTo("buff_select")` or `transitionTo("gameover")` | Signals once per day from `day_end`; reads every frame to gate logic |
| **Score System** | Read | `game.score` (int, 0–∞) | — | Read at `day_end` to compare against target; never written by Day Loop |
| **Customer System** | Write | — | `game.effective.spawnInterval`, `game.effective.customerPatience` | Written at `buff_select → play`; Customer System reads `game.effective.*` at each spawn event — never `config.*` directly |
| **Buff System** | Sequenced, no direct call | — | — | Buff applies first on `buff_select → play`; Day Loop runs immediately after in the same handler; no direct API between them |
| **HUD System** | Expose | — | `game.currentDay` (int), `game.dailyTarget` (int), `game.isEndless` (bool), `game.campaignScore` (int) | Polled every frame during `play`; `game.campaignScore` read at `gameover` for final display |

## Formulas

> **Note on campaign targets (days 1–7):** `game.dailyTarget` for days 1–7 is a fixed lookup, not a computed formula. The table lives in `config.lua` as `DAILY_TARGETS` (`{1=400, 2=600, 3=850, 4=1100, 5=1400, 6=1750, 7=2100}` pts). The Day Loop reads `DAILY_TARGETS[game.currentDay]` directly. No arithmetic is applied.
>
> For `correct_serve_score` and per-day score accumulation, see `design/gdd/score-system.md`.

---

The **endless_daily_target** formula is defined as:

`endless_daily_target = DAILY_TARGETS[7] + (currentDay − 7) × ENDLESS_TARGET_STEP`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Day 7 campaign target | `DAILY_TARGETS[7]` | int | 2100 (constant) | Anchor value; the final campaign target, defined in `config.lua` |
| Current day number | `currentDay` | int | 8–∞ | `game.currentDay` at the start of the day being evaluated; always ≥ 8 in endless mode |
| Endless target step | `ENDLESS_TARGET_STEP` | int | 350 (tunable) | Points added per endless day; defined in `config.lua` |

**Output Range:** 2,450 pts on day 8; grows without cap. There is no defined ceiling — the target rises indefinitely until missed.
**Example:** Day 10 → `2100 + (10 − 7) × 350 = 2100 + 1050 = 3,150 pts`

---

The **endless_spawn_interval** formula is defined as:

`endless_spawn_interval = math.max(1.5, previousSpawnInterval − 0.15)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Previous day's spawn interval | `previousSpawnInterval` | float | 1.5–2.2 | `game.effective.spawnInterval` from the completed day; on day 8 this equals the day 7 value of 2.2 s |
| Step decrease | *(constant 0.15)* | float | — | Seconds removed per endless day |
| Absolute endless floor | *(constant 1.5)* | float | — | Below this, six tables fill in under 10 s — exceeds the volume-pressure boundary of Pillar 1 |

**Output Range:** 2.05 s on day 8; floors at 1.5 s ~day 12. Once the floor is reached, the value is clamped and does not decrease further.
**Example:** Day 8 → `math.max(1.5, 2.2 − 0.15) = 2.05 s` | Day 12 → `math.max(1.5, 1.45) = 1.5 s` (floor reached)

---

The **endless_customer_patience** formula is defined as:

`endless_customer_patience = math.max(8.0, previousCustomerPatience − 0.8)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Previous day's customer patience | `previousCustomerPatience` | float | 8.0–12.0 | `game.effective.customerPatience` from the completed day; on day 8 this equals the day 7 value of 12.0 s |
| Step decrease | *(constant 0.8)* | float | — | Seconds of patience removed per endless day |
| Absolute endless floor | *(constant 8.0)* | float | — | Below this, a full-diagonal serve cycle cannot reliably complete — timing pressure violates Pillar 1 |

**Output Range:** 11.2 s on day 8; floors at 8.0 s ~day 13. Patience remains constant at 8.0 s for all subsequent endless days once the floor is reached.
**Example:** Day 8 → `math.max(8.0, 12.0 − 0.8) = 11.2 s` | Day 13 → `math.max(8.0, 7.6) = 8.0 s` (floor reached)

## Edge Cases

1. **If `game.score == game.dailyTarget` exactly at `day_end`**: this is a pass. The condition is `score >= dailyTarget`; equal score meets the target. Must be implemented as `>=`, not `>`.

2. **If day 7 target is met**: `game.isEndless = true` is set on the `day_end` evaluation frame, before `buff_select` is entered. During the entire `buff_select` state, `game.currentDay` is still `7` (it does not increment until `buff_select → play`). Both conditions are simultaneously true: `currentDay == 7` AND `isEndless == true`. Systems reading either value during `buff_select` will see both correctly.

3. **If `game.currentDay == 8` and `game.dailyTarget` is read from the campaign table**: `DAILY_TARGETS[8]` does not exist — Lua returns `nil` for any index > 7, not an error. A conditional branch on `game.isEndless` is mandatory: if `isEndless == true`, use the formula; if false, use `DAILY_TARGETS[currentDay]`. Never call the table lookup unconditionally past day 7.

4. **If `day_end` state persists across multiple frames** (normal behaviour): `day_loop.evaluated` is set to `true` on the first frame and blocks all subsequent evaluations. Without this guard, `game.score` would be added to `game.campaignScore` on every frame in `day_end`, corrupting the run total.

5. **If the player fails the daily target (`gameover` path)**: `game.campaignScore` still receives `game.score` at evaluation step (a) before the `gameover` signal fires. The accumulation is unconditional — it runs on pass and fail. The gameover screen displays `game.campaignScore` including the failed day's score. A branch that only accumulates on a pass will produce a wrong final total.

6. **If `gameover → play` fires (new run starts via `resetGame()`)**: `day_loop.evaluated` was left `true` by the `day_end` evaluation that triggered gameover. `resetGame()` must explicitly reset `day_loop.evaluated = false`. If it does not, Day 1's evaluation is skipped silently — the day auto-passes to `buff_select` without any target check. This is the single highest-risk omission in this system.

7. **If both endless floors are reached on the same day**: `spawnInterval` clamps at 1.5 s and `customerPatience` clamps at 8.0 s simultaneously. Both clamps fire independently. Difficulty stops escalating for those two parameters, but `endless_daily_target` continues rising uncapped. The run ends by score failure, not a difficulty ceiling — the floors are a player-experience boundary, not a run-end boundary.

8. **If `Patience+` buff is selected on `buff_select → play`** and the Day Loop also writes `game.effective.customerPatience`: per Rule 9, the Buff System applies first (step 1), then Day Loop writes escalation values (step 2). The Buff System GDD must specify that Patience+ adds a delta to `game.effective.customerPatience` after the escalation write — not sets an absolute value that the Day Loop then silently overwrites. *(Cross-GDD contract — must be resolved in the Buff System GDD before implementation of either system.)*

9. **If the endless target formula reads `currentDay` at `day_end`**: `game.currentDay` is the day just played (incremented at the start of this day on `buff_select → play`). For endless day 8, `currentDay == 8` at evaluation and `(8 − 7) × 350 = 350` is correct. An off-by-one in the formula (`currentDay − 1` or `currentDay + 1`) produces wrong endless targets on every day.

## Dependencies

**Upstream (Day Loop depends on):**
- **Game State Manager** — reads `game.gameState` to gate all logic; signals GSM to trigger state transitions. Hard dependency — Day Loop cannot function without GSM's state machine.
- **Score System** — reads `game.score` at `day_end` to evaluate the daily target. Hard dependency — target evaluation requires the score value.

**Downstream (systems that depend on Day Loop):**

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Customer System** | Reads Day Loop's escalation output | Reads `game.effective.spawnInterval` and `game.effective.customerPatience` at each spawn event | Hard — Customer System spawn behaviour is directly controlled by these values |
| **Buff System** | Sequenced on same transition | Runs before Day Loop on `buff_select → play`; must treat Day Loop's `game.effective.*` write as authoritative for that day | Hard — the Patience+ buff contract requires knowing Day Loop's write timing (see Edge Case 8) |
| **HUD System** | Reads display data | Polls `game.currentDay`, `game.dailyTarget`, `game.isEndless`, `game.campaignScore` every frame during `play`; reads `game.campaignScore` at `gameover` for final display | Soft — HUD can display a placeholder if values are unavailable; Day Loop functions without it |

**Owned variables exposed to other systems:**

| Variable | Type | Read by |
|----------|------|---------|
| `game.currentDay` | int | HUD System |
| `game.dailyTarget` | int | HUD System |
| `game.isEndless` | bool | HUD System, Buff System (display context) |
| `game.campaignScore` | int | HUD System (gameover screen) |
| `game.effective.spawnInterval` | float | Customer System |
| `game.effective.customerPatience` | float | Customer System, Buff System (Patience+ delta target) |

## Tuning Knobs

All tuning values must live in `config.lua` — none may be hardcoded inline.

| Knob | Config Key | Current Value | Safe Range | Too High | Too Low |
|------|-----------|---------------|------------|----------|---------|
| Day 1 target | `DAILY_TARGETS[1]` | 400 pts | 200–600 | Day 1 not winnable first-attempt; violates anti-pillar | Trivially easy; no tension; player doesn't understand the stakes |
| Day 7 target | `DAILY_TARGETS[7]` | 2,100 pts | 1,400–3,000 | Requires near-perfect play AND a multiplier buff; too punishing | Late campaign has no tension; skilled players cruise through |
| Endless target step | `ENDLESS_TARGET_STEP` | 350 pts/day | 200–600 | Endless ends too quickly; no player reaches day 10 | Endless runs too long; feels like it never ends |
| Campaign spawn floor | `ESCALATION_SPAWN[7]` | 2.2 s | 2.0–2.8 s | Fewer customers per shift, lower pressure | ≥6 tables fill in <14 s — too many simultaneous inputs |
| Campaign patience floor | `ESCALATION_PATIENCE[7]` | 12.0 s | 10.0–15.0 s | More time per serve, less late-game pressure | Full-diagonal serve cycle unreliable — timing pressure, not volume (violates Pillar 1) |
| Endless spawn floor | `MIN_ENDLESS_SPAWN` | 1.5 s | 1.5–2.0 s | — | Physically unplayable — 6 tables fill in <10 s |
| Endless patience floor | `MIN_ENDLESS_PATIENCE` | 8.0 s | 8.0–10.0 s | — | Serve cycle becomes impossible for average movement speed |
| Endless spawn step | `ENDLESS_SPAWN_STEP` | 0.15 s/day | 0.05–0.25 s | Floors hit quickly; endless ends fast | Barely perceptible escalation; endless feels static |
| Endless patience step | `ENDLESS_PATIENCE_STEP` | 0.8 s/day | 0.3–1.5 s | Customers feel almost instantly impatient | Patience barely changes; endless difficulty is only target-driven |

**Knob interactions:**
- Raising `DAILY_TARGETS[1..7]` without adjusting escalation pacing can create "wall days" — one day suddenly much harder than the previous. Test all 7 targets together, not in isolation.
- `ENDLESS_TARGET_STEP` and the endless floors interact: if the target step is very high but floors clamp early, the run ends purely by score failure rather than a mix of score and difficulty — changes the end-game feel.
- `ESCALATION_PATIENCE` values interact with the Patience+ buff: if base patience is already low, the buff's +2 s becomes proportionally more valuable. Retune buff balance when escalation values change.

> ⚠️ Move `ENDLESS_SPAWN_STEP`, `ENDLESS_PATIENCE_STEP`, `MIN_ENDLESS_SPAWN`, and `MIN_ENDLESS_PATIENCE` to `config.lua` as named constants before implementation — they are currently inline values in the Day Loop spec.

## Visual/Audio Requirements

The Day Loop owns no visual or audio assets. It is pure data and event processing — it produces no direct output visible to the player. The emotional beats this system creates (the end-of-day verdict, the endless mode unlock) are rendered by the HUD System and Buff System. The one audio note: the `day_end → buff_select` vs. `day_end → gameover` verdict should have distinct audio feedback — a continuation cue vs. a run-end cue. These cues are owned by audio implementation, not this GDD.

## UI Requirements

| Value | Display | Update Frequency | Notes |
|-------|---------|-----------------|-------|
| `game.currentDay` | Day indicator (e.g., "Day 3 / 7") | At day start | Visible during `play` and `day_end` |
| `game.dailyTarget` | Target display alongside `game.score` | At day start | Lets the player track progress toward the target during the shift |
| `game.isEndless` | Endless mode indicator (e.g., "ENDLESS" banner) | On entering `buff_select` after day 7 | Only displayed when `game.isEndless == true` |
| `game.campaignScore` | Final score on gameover screen | At `gameover` | Displayed as the run total, not the last day's score |

> **📌 UX Flag — Day Loop**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the HUD's day indicator and daily target display **before** writing epics. Stories that reference these UI elements should cite `design/ux/[hud-screen].md`, not this GDD directly.

## Acceptance Criteria

**Daily Target Evaluation**
- **GIVEN** `game.score = 400` and `game.dailyTarget = 400` at `day_end`, **WHEN** the Day Loop evaluates, **THEN** the result is a pass — state transitions to `buff_select`. Equal score is not a failure. (`>=`, not `>`)
- **GIVEN** `game.score = 399` and `game.dailyTarget = 400` at `day_end`, **WHEN** the Day Loop evaluates, **THEN** state transitions to `gameover`.
- **GIVEN** the GSM has been in `day_end` for 10 frames and `game.score = 500`, `game.dailyTarget = 400`, **WHEN** those 10 frames resolve, **THEN** `game.campaignScore` has been incremented by exactly 500 — once, not 10 times. (`day_loop.evaluated` guard must be present.)

**Campaign Score Accumulation**
- **GIVEN** `game.campaignScore = 0`, `game.score = 450`, and the day is a pass, **WHEN** the Day Loop evaluates at `day_end`, **THEN** `game.campaignScore = 450` before any state transition fires.
- **GIVEN** `game.campaignScore = 1200`, `game.score = 300`, and the daily target is 600 (fail), **WHEN** the Day Loop evaluates, **THEN** `game.campaignScore = 1500` — the failed day's score is accumulated before the `gameover` signal, not withheld.

**Campaign Target Table (Days 1–7)**
- **GIVEN** `game.currentDay = 1` at run start, **WHEN** `game.dailyTarget` is read, **THEN** `game.dailyTarget = 400`.
- **GIVEN** `game.currentDay = 7` and `game.isEndless = false`, **WHEN** `game.dailyTarget` is read at day start, **THEN** `game.dailyTarget = 2100` via the table lookup branch — `game.isEndless` remains `false` at this read.

**Endless Mode Activation**
- **GIVEN** `game.currentDay = 7` and `game.score >= 2100` at `day_end`, **WHEN** the Day Loop evaluates, **THEN** `game.isEndless = true` is set before `buff_select` is entered; `game.currentDay` remains `7` for the entire `buff_select` state.
- **GIVEN** `game.currentDay = 8` and `game.isEndless = true`, **WHEN** `game.dailyTarget` is set at day start, **THEN** `game.dailyTarget = 2450` from the formula branch (`2100 + 1 × 350`). The system must not read `DAILY_TARGETS[8]` — Lua returns `nil` for that index, not an error.
- **GIVEN** `game.currentDay = 10` and `game.isEndless = true`, **WHEN** `game.dailyTarget` is set, **THEN** `game.dailyTarget = 3150` (`2100 + 3 × 350 = 3150`).

**Difficulty Escalation**
- **GIVEN** the player transitions from `buff_select` to `play` for Day 7, **WHEN** the Day Loop writes escalation, **THEN** `game.effective.spawnInterval = 2.2` and `game.effective.customerPatience = 12.0`. The Customer System reads `game.effective.*`, not `config.*` directly.
- **GIVEN** `game.effective.spawnInterval = 2.2` at end of Day 7, **WHEN** Day Loop writes Day 8 escalation, **THEN** `game.effective.spawnInterval = 2.05` (`math.max(1.5, 2.2 − 0.15)`).
- **GIVEN** `game.effective.spawnInterval = 1.55` entering an endless day, **WHEN** Day Loop computes the next value, **THEN** `game.effective.spawnInterval = 1.5` — floor clamped.
- **GIVEN** `game.effective.customerPatience = 12.0` at end of Day 7, **WHEN** Day Loop writes Day 8 escalation, **THEN** `game.effective.customerPatience = 11.2` (`math.max(8.0, 12.0 − 0.8)`).
- **GIVEN** `game.effective.customerPatience = 8.3` entering an endless day, **WHEN** Day Loop computes the next value, **THEN** `game.effective.customerPatience = 8.0` — floor clamped.

**resetGame() and Guard**
- **GIVEN** a run just ended at `gameover` (leaving `day_loop.evaluated = true`), **WHEN** the player presses R and `resetGame()` fires, **THEN** `day_loop.evaluated = false` is explicitly reset — Day 1 of the new run performs its target check normally and does not auto-pass to `buff_select` silently.

**Day Counter Timing**
- **GIVEN** `game.currentDay = 3` throughout `day_end` and `buff_select`, **WHEN** the player confirms a buff and `buff_select → play` fires, **THEN** `game.currentDay = 4` at the first frame of the new `play` state.

> **Test team notes**: The guard criterion requires a white-box unit test — a black-box tester cannot observe frame count vs. accumulation directly. The Day 7 table-vs-formula criterion may false-pass since `2100 + (7−7)×350 = 2100`; confirm the branch condition, not just the output value. The resetGame guard reset is the highest-risk omission — only a full new-run playthrough will catch it.

## Open Questions

1. **Buff + escalation write ordering for Patience+ buff** — Edge Case 8 identifies a race between the Buff System's Patience+ delta and the Day Loop's escalation write on `buff_select → play`. The Buff System GDD must resolve whether Patience+ adds a delta *after* the Day Loop escalation write, or sets an absolute value. Owner: Buff System GDD. Required before either system is implemented.

2. **`buff_select → play` call sequence ownership in code** — Rule 9 defines the ordering (buff → Day Loop → reset), but who owns the orchestrator? Recommended: `main.lua` calls each system hook in sequence. If Day Loop owns the handler, Buff System becomes a Day Loop dependency, which is architecturally wrong (Day Loop is Layer 1; Buff System is Layer 3). Owner: lead programmer. Should become an ADR before implementation.

3. **Escalation storage format** — Campaign escalation values are spec'd as lookup arrays (`ESCALATION_SPAWN[1..7]`, `ESCALATION_PATIENCE[1..7]`). An alternative is a formula with a per-day step and a campaign floor clamp. Arrays are explicit and playtest-safe; a formula is more compact. Must resolve before Customer System is designed, since it affects which config keys the Customer System reads. Owner: game designer + lead programmer.

4. **Daily target playtesting** — The 7-day target values (400–2,100 pts) are initial estimates derived from theoretical serve throughput. They need at least one full playtested run before locking. Day 1 (400 pts) is most critical: if a first-time player cannot reach it, it violates the anti-pillar. Owner: game designer. Target resolution: first internal playtest.

5. **Patience+ buff and patience starting value for endless escalation** — If Patience+ has been applied multiple times during the campaign, `game.effective.customerPatience` entering endless mode is higher than 12.0 s. The `endless_customer_patience` formula starts from whatever `game.effective.customerPatience` is at end of Day 7 — not from the config baseline. The Buff System GDD must specify whether `game.effective.customerPatience` is the Patience+-adjusted value or escalation-only. This affects the actual difficulty of endless mode. Owner: Buff System GDD. Required before Buff System is designed.
