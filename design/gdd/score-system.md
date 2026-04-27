# Score System

> **Status**: Designed (pending design-review)
> **Author**: user + agents
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 (Chill Until It Isn't), Pillar 2 (Build Your Day), Pillar 3 (Always Readable)

## Overview

The Score System is the running measure of how well the player is performing their shift. Every correct delivery adds to the score — fast service earns more; a near-zero-patience customer is worth the minimum while a full-patience serve is worth nearly double. Every mistake — wrong plate delivered, abandoned plate, impatient walkout — bites into it. The score serves two roles simultaneously: moment-to-moment feedback (am I playing well right now?) and end-of-day verdict (did I hit the daily money target?). A multiplier buff can double all future earnings, making good stretches feel dramatically larger. A floor-at-zero rule means a bad streak cannot spiral into meaningless negative territory. Mechanically, score state (`game.score`, `game.misses`, `game.scoreMultiplier`) lives directly on the shared `game` table rather than in an isolated module — all systems that contribute to or read score do so via that table. Score writes are restricted to the `play` state; `day_end` reads the accumulated score to evaluate the daily target.

## Player Fantasy

The score is a speedometer, not a ledger. What the player should feel is *momentum* — the rising certainty that the room is theirs, that orders are flowing and nothing is going wrong. The anchor moment is chaining three correct serves in a row and watching the counter jump 300+ points in under four seconds: the number is not just rising, it is *accelerating*, and that acceleration is its own reward. Penalties interrupt momentum rather than define the experience — a wrong dish or a walkout stings because it breaks the streak, not because it moves a number. The score multiplier buff deepens this loop: once active, every correct serve feels bigger, pulling the player toward faster and cleaner decisions to protect the run. This system primarily serves **Pillar 1 (Chill Until It Isn't)** — early in a shift, score climbs easily and momentum feels free; as tables fill and the clock ticks down, holding that momentum is harder and losing it hurts more.

## Detailed Design

### Core Rules

1. Score represents daily earnings. It resets to `0` at the start of each new day and at the start of a new run.
2. Score is a non-negative integer. The floor is `0` — no operation may produce a negative value. All subtractions are wrapped: `math.max(0, game.score - penalty)`.
3. Score is written **only during the `play` game state.** Any scoring event outside `play` is discarded.
4. Score is **read** (never written) during `day_end` by the Day Loop to evaluate the daily money target.
5. Score is **read** every frame by the HUD System for display.
6. **Correct serve:** `game.score = game.score + math.floor(100 + patience × 2) × game.scoreMultiplier`
   — `patience` is the customer's value at the exact moment of delivery, range `[0, 20]`.
7. **Wrong serve:** `game.score = math.max(0, game.score - 30)`
8. **Customer leaves (patience expired):** `game.score = math.max(0, game.score - 50)`
9. `game.scoreMultiplier` starts at `1`. The Score ×2 buff sets `game.scoreMultiplier = game.scoreMultiplier × 2`. Stackable with no defined cap.
10. `game.scoreMultiplier` **persists across days** within a run. It does NOT reset at `buff_select → play`.
11. `game.scoreMultiplier` resets to `1` only on `menu → play` or `gameover → play` (new run).
12. `game.misses` tracks wrong serves + customer leaves per day. It resets to `0` at day start alongside `game.score`. It does not affect score directly; exposed to the HUD for display.

### States and Transitions

The Score System is **stateless event processing.** It holds persistent values (`game.score`, `game.scoreMultiplier`) and one daily-reset value (`game.misses`), but has no internal state machine. The same formulas apply throughout `play` regardless of day number or miss count. `game.scoreMultiplier > 1` is data, not control flow.

**Reset responsibilities** (triggered by Game State Manager on transition):

| Trigger | `game.score` | `game.misses` | `game.scoreMultiplier` |
|---------|-------------|--------------|----------------------|
| Day start (`buff_select → play`) | Reset to `0` | Reset to `0` | No change |
| New run (`menu → play`, `gameover → play`) | Reset to `0` | Reset to `0` | Reset to `1` |

### Interactions with Other Systems

| System | Direction | Data In | Data Out | Notes |
|--------|-----------|---------|----------|-------|
| **Order / Kitchen** | Writes to `game.score` | `patience` (number) | — | Kitchen confirms correctness; passes `patience` at delivery moment |
| **Customer System** | Writes to `game.score` | — | — | Calls leave-penalty when patience reaches 0 |
| **Customer System** | Provides patience | — | `patience: number [0,20]` | Fetched by Order/Kitchen before passing to score calculation |
| **Buff System** | Writes to `game.scoreMultiplier` | `factor: 2` | — | Called once when Score ×2 buff is selected at `buff_select` |
| **Day Loop** | Reads `game.score` | — | `game.score` | Read-once at `day_end` to compare against daily money target |
| **HUD System** | Reads all three | — | `game.score`, `game.misses`, `game.scoreMultiplier` | Polled every frame during `play` and `day_end` |
| **Game State Manager** | Triggers resets | transition event | — | Calls the appropriate reset on `buff_select → play` (day reset) and on new run transitions |

## Formulas

The **correct_serve_score** formula is defined as:

`correct_serve_score = floor(100 + patience × 2) × scoreMultiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Customer patience at delivery | `patience` | float | 0.0–20.0 | Remaining patience in seconds at the exact moment the plate is accepted |
| Score multiplier | `scoreMultiplier` | int | 1, 2, 4, 8… | Active run multiplier; starts at 1, doubled per Score ×2 buff selection |
| Base award | *(constant 100)* | int | — | Minimum points for any correct serve |
| Patience bonus rate | *(constant 2)* | int | — | Points added per whole second of remaining patience |

**Output Range:** 100–140 pts at ×1; 200–280 at ×2; 400–560 at ×4. `floor()` truncates the patience bonus — patience 19.9 s awards the same as 19.0 s.
**Example:** patience = 13.7, scoreMultiplier = 2 → `floor(100 + 13.7 × 2) × 2 = 127 × 2 = 254 pts`

---

The **wrong_serve_penalty** formula is defined as:

`score = max(0, score − 30)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Score before penalty | `score` | int | 0–∞ | Running score at moment of wrong delivery |
| Penalty constant | *(constant 30)* | int | — | Fixed deduction per wrong serve; not affected by `scoreMultiplier` |

**Output Range:** 0 to (score − 30). Floor of 0 always applies. Multiplier has no effect.
**Example:** score = 20 → `max(0, 20 − 30) = 0 pts`

---

The **customer_leave_penalty** formula is defined as:

`score = max(0, score − 50)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Score before penalty | `score` | int | 0–∞ | Running score at moment of walkout |
| Penalty constant | *(constant 50)* | int | — | Fixed deduction per walkout; not affected by `scoreMultiplier` |

**Output Range:** 0 to (score − 50). Same floor rule. Multiplier has no effect.
**Example:** score = 35 → `max(0, 35 − 50) = 0 pts`

---

The **score_multiplier_application** formula is defined as:

`scoreMultiplier = scoreMultiplier × 2` *(applied once per Score ×2 buff selection)*

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current multiplier | `scoreMultiplier` | int | 1, 2, 4, 8… | Persistent run value; doubles each buff selection |
| Buff factor | *(constant 2)* | int | — | Applied on each buff selection |

**Output Range:** 1 (no buff) → 2, 4, 8 on successive selections. Practical max under normal play is ×8 (all three selections used for Score ×2). No hard cap defined. Persists across days; resets to 1 only on a new run.
**Example:** scoreMultiplier = 2, buff selected again → `scoreMultiplier = 2 × 2 = 4`. Correct serve at patience = 10 → `floor(120) × 4 = 480 pts`

> **Balance note:** At ×1 the penalty-to-reward ratio is forgiving — a wrong serve (−30) is less than a third of a typical correct serve (~120 pts). A walkout (−50) takes roughly two low-patience serves to recover. Penalties remain flat as the multiplier grows, so they become proportionally trivial at ×4 and above — intentional, to amplify the momentum fantasy. The real early-game risk is consecutive walkouts pinning score at 0 before the multiplier is active; the Patience + buff is the natural counter, forming a meaningful buff decision axis (Score ×2 for late acceleration vs. Patience + for early-game loss prevention).

## Edge Cases

- **If patience = 0 when a correct serve lands**: score += `floor(100) × scoreMultiplier`. The 100-pt base is always awarded — a zero-patience serve is still a valid serve, not a walkout.
- **If score = 0 and a penalty fires**: `max(0, 0 − penalty) = 0`. The floor absorbs the penalty silently. A player at zero cannot go negative regardless of penalty count.
- **If a wrong-serve and a customer-leave fire on the same frame**: penalties are applied sequentially in order of event resolution, each passing through the floor individually: `score = max(0, max(0, score − 30) − 50)`. This prevents a combined −80 from behaving differently than two chained deductions.
- **If scoreMultiplier is at ×8 (or any value) and Score ×2 buff is selected again**: `scoreMultiplier = scoreMultiplier × 2` with no cap. ×16, ×32, and beyond are allowed — intentional reward for building that far into a run.
- **If the day-end timer reaches 0 while a score event is in-flight (same frame)**: score events are resolved before the `play → day_end` state transition. A correct serve submitted in the final frame counts toward the daily total. Update loop order must reflect this: process score events first, then check timer expiry.
- **If patience ticks to 0 on the same frame a correct serve is submitted**: the serve is checked before the patience decrement. The customer is still present, the correct-serve formula fires, and the customer then leaves normally. The leave penalty does NOT also fire.
- **If a run starts from `menu → play` or `gameover → play` while scoreMultiplier > 1**: `scoreMultiplier` resets to 1 as part of the new-run reset. The `buff_select → play` path must explicitly NOT reset `scoreMultiplier` — these are two distinct reset paths and must not be conflated.
- **If score = 0 and misses > 0 at day end**: not a run-over condition. The Score System makes no judgment about run continuity — only the Day Loop / Campaign system decides whether the run ends by comparing score against the daily money target.

## Dependencies

**Upstream (Score System depends on):**
- None. Score System is Foundation-layer — no upstream dependencies.

**Downstream (systems that write to or read from Score System):**

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Order / Kitchen** | Writes correct-serve score | Passes `patience` at delivery moment; calls score increment formula | Hard — Order/Kitchen cannot complete a serve without triggering scoring |
| **Customer System** | Writes leave penalty; provides patience | Calls leave penalty on walkout; provides `patience` value queried at serve time | Hard — Customer leaving and correct-serve calculation both require Customer data |
| **Buff System** | Writes `game.scoreMultiplier` | Doubles `scoreMultiplier` when Score ×2 buff is selected | Soft — Score System functions without any buff ever being applied |
| **Day Loop / Campaign** | Reads `game.score` | Reads once at `day_end` to compare against daily money target | Hard — Day Loop cannot evaluate the day without a score value |
| **HUD System** | Reads `game.score`, `game.misses`, `game.scoreMultiplier` | Polls every frame during `play` and `day_end` | Soft — HUD can display a placeholder if score is unavailable; system functions without it |
| **Game State Manager** | Triggers resets | Calls day-reset and run-reset on appropriate transitions | Hard — `game.score` and `game.scoreMultiplier` must be reset at the correct transitions or daily target logic breaks |

> **Ownership note (GSM conflict):** The Game State Manager GDD's "Owned variables" table lists `game.scoreMultiplier` as a GSM-owned variable read by the Score System. This is incorrect — `game.scoreMultiplier` is owned by the Score System (the Buff System writes to it; the GSM only resets it on new-run transitions). The GSM GDD should be corrected in a future retrofit pass to remove `game.scoreMultiplier` from its ownership table and add it to the Score System's contract.

## Tuning Knobs

All tuning values must live in `config.lua` — none may be hardcoded inline. Values currently hardcoded in `main.lua` are flagged below.

| Knob | Config Key | Current Value | Safe Range | Too High | Too Low |
|------|-----------|---------------|------------|----------|---------|
| Base serve score | `SERVE_BASE_SCORE` | 100 pts | 50–200 | Score climbs so fast that daily targets feel trivially easy; multiplier buff becomes irrelevant sooner | Serves feel unrewarding; players lose patience before they lose customers |
| Patience bonus rate | `SERVE_PATIENCE_BONUS` | 2 pts/s | 1–5 | Fast-serve skill is rewarded heavily; slow play becomes comparatively unprofitable, punishing exploratory play | Patience no longer meaningfully rewards speed; serve timing becomes irrelevant |
| Wrong serve penalty | `WRONG_SERVE_PENALTY` | 30 pts | 10–80 | A single wrong delivery late in a shift can wipe out several good serves; compounds badly with leave penalties | Mistakes feel consequence-free; players stop caring about order accuracy |
| Customer leave penalty | `LEAVE_PENALTY` | 50 pts | 20–100 | Multiple walkouts on a crowded day can make recovery mathematically impossible; violates Pillar 1 (not punishing at the start) | Customers leaving feels inconsequential; patience management loses tension |
| Score multiplier buff factor | `SCORE_BUFF_FACTOR` | ×2 | ×1.5–×3 | Multiplier compounds so fast it trivializes all other scoring; ×4 after two picks outweighs all penalties | Barely noticeable improvement per pick; Pillar 2 (Build Your Day) is undermined if the buff doesn't feel meaningful |

> ⚠️ `SERVE_BASE_SCORE`, `SERVE_PATIENCE_BONUS`, `WRONG_SERVE_PENALTY`, and `LEAVE_PENALTY` are currently hardcoded inline in `main.lua`. They must be moved to `config.lua` before this GDD is implemented.

**Knob interactions:**
- Raising `SERVE_BASE_SCORE` and `SERVE_PATIENCE_BONUS` together shifts the skill expression from "don't make mistakes" to "be fast" — raises the ceiling but keeps the floor.
- Raising `WRONG_SERVE_PENALTY` and `LEAVE_PENALTY` together shifts the tone from Pillar 1 (chill) to punishing — test against Day 1 first-run experience before raising both.
- `SCORE_BUFF_FACTOR` interacts multiplicatively with everything — a ×3 multiplier on a ×5 patience bonus rate creates outlier scores that break daily target tuning.

## Visual/Audio Requirements

The Score System owns no visual assets or audio cues. All visual feedback for scoring events (point popups, score counter updates, penalty flashes) is specified in the HUD System GDD. Score System's responsibility ends at updating the values in `game.score`, `game.misses`, and `game.scoreMultiplier` — the HUD System owns the presentation layer that makes those values visible to the player.

The one audio note relevant to this system: the momentum fantasy (Pillar 1 / Section B) depends partly on audio punctuation of scoring events. A correct serve should have a distinct reward sound; a walkout should have a distinct penalty sound. These cues are owned by audio implementation, not this GDD — but they should reinforce the score delta, not mask it.

## UI Requirements

The Score System exposes three values that the HUD must display during `play` and `day_end`:

| Value | Display Location | Update Frequency | Notes |
|-------|-----------------|-----------------|-------|
| `game.score` | Score counter (HUD top-right or top-center) | Every frame | Shows current daily total, not run total |
| `game.misses` | Miss counter (HUD) | Every frame | Resets each day; display is per-day only |
| `game.scoreMultiplier` | Multiplier indicator (HUD) | On buff selection | Only visible when > 1; shown as "×2", "×4", etc. |

The daily target (owned by Day Loop) should be displayed alongside `game.score` so the player can track progress toward the daily goal — but the target value is not owned by this system.

> **📌 UX Flag — Score System:** This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the score HUD elements **before** writing epics. Stories that reference score display should cite `design/ux/[hud-screen].md`, not this GDD directly.

## Acceptance Criteria

**Scoring and Formula Criteria**

- **GIVEN** `patience` = 10 and `scoreMultiplier` = 1, **WHEN** a correct serve is delivered, **THEN** score increases by exactly 120 pts (`floor(100 + 10×2) × 1 = 120`).
- **GIVEN** `patience` = 10 and `scoreMultiplier` = 2, **WHEN** a correct serve is delivered, **THEN** score increases by exactly 240 pts.
- **GIVEN** `patience` = 0 and `scoreMultiplier` = 1, **WHEN** a correct serve is delivered, **THEN** score increases by exactly 100 pts — the serve is valid and the base award is guaranteed.
- **GIVEN** `patience` = 20 and `scoreMultiplier` = 1, **WHEN** a correct serve is delivered, **THEN** score increases by exactly 140 pts (maximum normal reward).
- **GIVEN** `patience` = 7.5 (mid-tick float), **WHEN** a correct serve is delivered, **THEN** score increases by `floor(100 + 7.5 × 2) = 115` pts, not 116 — `floor` truncates, not rounds.
- **GIVEN** score = 100 and `scoreMultiplier` = 4, **WHEN** a wrong serve occurs, **THEN** score equals 70 and `scoreMultiplier` remains 4 — the multiplier does not apply to penalties.
- **GIVEN** score = 10, **WHEN** a wrong serve penalty fires, **THEN** score equals 0, not −20.
- **GIVEN** score = 40 and `scoreMultiplier` = 2, **WHEN** a customer leaves, **THEN** score equals 0 and `scoreMultiplier` remains 2.
- **GIVEN** score = 60, **WHEN** a wrong-serve (−30) and a customer-leave (−50) fire in the same frame in that order, **THEN** score = `max(0, max(0, 60−30) − 50) = 0`; penalties apply sequentially through the floor, not as a combined −80.

**Multiplier Criteria**

- **GIVEN** `scoreMultiplier` = 1, **WHEN** Score ×2 buff is selected, **THEN** `scoreMultiplier` = 2.
- **GIVEN** `scoreMultiplier` = 2, **WHEN** Score ×2 buff is selected again, **THEN** `scoreMultiplier` = 4.
- **GIVEN** `scoreMultiplier` = 8, **WHEN** Score ×2 buff is selected, **THEN** `scoreMultiplier` = 16 — no cap enforced.

**Reset Criteria**

- **GIVEN** score = 350, misses = 2, `scoreMultiplier` = 4 at end of a day, **WHEN** the state transitions from `buff_select` to `play` (Day 2+), **THEN** score = 0, misses = 0, `scoreMultiplier` remains 4.
- **GIVEN** score = 500, misses = 3, `scoreMultiplier` = 8 on any day, **WHEN** a new run begins (`menu → play` or `gameover → play`), **THEN** score = 0, misses = 0, `scoreMultiplier` = 1.
- **GIVEN** `scoreMultiplier` = 4 at end of Day 2, **WHEN** Day 3 begins via `buff_select → play`, **THEN** the first correct serve on Day 3 uses `scoreMultiplier` = 4.

**Misses Tracking Criteria**

- **GIVEN** misses = 0, **WHEN** a wrong serve occurs, **THEN** misses = 1.
- **GIVEN** misses = 1, **WHEN** a customer leaves without being served, **THEN** misses = 2.
- **GIVEN** misses = 3 at end of day, **WHEN** the next day begins, **THEN** misses = 0.

**Frame-Ordering Criteria**

- **GIVEN** the day-end timer reaches 0 in the same frame a correct serve input is registered, **WHEN** the frame resolves, **THEN** the score event is processed before the `play → day_end` transition — the serve counts toward the daily total.
- **GIVEN** `patience` ticks to 0 on the same frame a correct serve input is registered, **WHEN** serve-vs-leave priority is evaluated, **THEN** the serve is processed first — score increases by `floor(100 + 0×2) × scoreMultiplier` and misses does not increment.

> *Score-write restriction to `play` state requires white-box or unit-test verification — a black-box tester cannot observe whether a write was attempted and blocked vs. never attempted.*

## Open Questions

1. **Daily money target value** — The Score System defines that the Day Loop reads `game.score` to evaluate the daily target, but the target formula and per-day values are unspecified. Owner: Day Loop / Campaign GDD. Required before implementation.

2. **End-of-run score display** — Is the score shown at `gameover` the last day's score (since score resets daily) or a separate campaign total? The current prototype shows the session total, but with daily resets this needs a decision. If a campaign total is wanted, a separate `game.campaignScore` variable is required — add it to this GDD.

3. **Do misses have any gameplay consequence beyond display?** — The current design uses misses as a display metric only. A future design could use misses as a daily bonus/penalty threshold (e.g., ≤3 misses = bonus multiplier next day). If this is intended, it belongs in the Day Loop or Buff System GDD, not here.

4. **Patience + buff and score ceiling** — `CUSTOMER_PATIENCE` is 20 s by default, and the formula assumes patience ∈ [0, 20]. After multiple Patience + buff picks, a customer's starting patience can exceed 20 s, yielding correct-serve scores above 140×M. This is not a bug — the formula handles any float — but the behavior should be explicitly acknowledged as intentional, not an oversight.
