# Game State Manager

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Core Infrastructure
> **Revision note**: Updated for 7-day campaign + endless mode. Replaced `buffs_paused` with `day_end` and `buff_select` states. Mid-game cube interaction removed. Retrofit 2026-04-26: corrected stale `buffs_paused` references, removed obsolete edge case (cube guard), removed obsolete owned variables (`game.menuOpen`, `game.buffsSelected`, `game.scoreMultiplier`).

## Overview

The Game State Manager is the central controller for Proyecto Rome's session flow. It maintains a single active state variable that all other systems read to determine their behavior each frame. The game has four defined states: **menu** (title screen, awaiting input to begin), **play** (active gameplay — all systems running), **buffs_paused** (gameplay frozen while the player selects a buff upgrade), and **gameover** (session ended, score displayed, awaiting restart). Every LÖVE2D callback (`love.update`, `love.draw`, `love.keypressed`, `love.mousepressed`) gates its logic on the current state. No system may change game behavior by bypassing this variable — all state transitions are owned by the Game State Manager.

## Player Fantasy

The Game State Manager has no player fantasy of its own — and that is precisely
the point. When it works correctly, the player never thinks about states,
transitions, or modes; they only experience seamless flow between the main menu,
the 90-second service rush, and the game-over screen. The one moment this system
becomes briefly perceptible is when the buff menu opens: the restaurant freezes
mid-chaos, and that sudden stillness should feel like a decisive snap-to-calm —
a clear signal that the rules of the world have temporarily changed and the
player now has permission to think.

## Detailed Design

### Core Rules

1. The state machine has exactly five valid states: `menu`, `play`, `day_end`, `buff_select`, `gameover`. No other values are valid for `game.gameState`.
2. A single variable — `game.gameState` (string) — is the canonical source of truth. All systems read this variable; none may shadow it or maintain a local copy.
3. All LÖVE2D callbacks (`love.update`, `love.draw`, `love.keypressed`, `love.mousepressed`) gate their logic on `game.gameState` at the top of the function. A callback that proceeds without checking state is a contract violation.
4. Only the Game State Manager may write to `game.gameState`. No other system transitions state directly — they signal the Game State Manager via their defined triggers (key events, timer expiry, Day Loop verdict).
5. `day_end → buff_select → play` is a **resume chain** (session variables intact — score, entities, day counter). `menu → play` and `gameover → play` are **resets** (`resetGame()` called). This distinction must not be blurred.
6. During `day_end` and `buff_select`, all simulation halts — the game timer does not tick, customers do not lose patience, the player does not move. This is a full freeze, not slow-motion.
7. The game timer is owned by the Game State Manager. It ticks only during `play`. When it reaches zero, the Game State Manager transitions to `day_end` — NOT directly to `gameover`. The Day Loop / Campaign system evaluates whether the daily target was met and requests the appropriate next state.
8. Entering `gameover` does not reset any variables — it only sets the state. Score, timer, and entity state persist until `resetGame()` is explicitly called.
9. The Day Loop / Campaign system is the only system authorized to trigger the `day_end → buff_select` and `day_end → gameover` transitions. It does this by invoking the Game State Manager's transition functions after evaluating the daily target. No other system may cause these transitions.

### States and Transitions

| From | To | Trigger | Guard | Side Effects |
|------|----|---------|-------|--------------|
| `menu` | `play` | `return` or `space` key | — | `resetGame()` — all variables reset |
| `play` | `day_end` | `game.gameTimer ≤ 0` | — | Simulation halts; Day Loop evaluates daily target |
| `day_end` | `buff_select` | Day Loop: target met | Daily target met AND days remain | Day counter not yet incremented |
| `day_end` | `gameover` | Day Loop: target missed | Daily target not met | None — score/entities persist for display |
| `buff_select` | `play` | `return` or `space` key | Valid buff selected | Buff applied; day counter +1; timer reset; difficulty escalates (Day Loop owned) |
| `gameover` | `play` | `r` key | — | `resetGame()` — all variables reset |
| `play` | `play` | `r` key | In `play` state | `resetGame()` — intentional mid-run reset |

**Note on endless mode**: After day 7 target is met, the `day_end → buff_select → play` chain executes normally. The Day Loop / Campaign system signals endless mode internally — the Game State Manager does not require a separate `endless` state. The `play` state is reused for endless days.

**Note on buff selection**: There is no exit from `buff_select` without selecting a buff. Once the selection screen opens, the player must choose. This is deliberate — the choice is a committed decision, not a menu to back out of.

### Interactions with Other Systems

- **Score System** — `game.score`, `game.misses`, `game.scoreMultiplier` are owned here. Score writes occur only during `play`. Score is read during `day_end` (for daily target evaluation by the Day Loop) and during `gameover` for final display. All three are reset on `menu → play` and `gameover → play` transitions.
- **Day Loop / Campaign** — The Day Loop reads `game.gameState` to gate day progression logic. It is the only system authorized to trigger `day_end → buff_select` and `day_end → gameover` transitions — it does this after evaluating `game.score` against the daily target. Data owned by Day Loop: `game.currentDay`, `game.dailyTarget`. Data owned by Game State Manager: `game.gameState`, `game.gameTimer`.
- **Player Movement** — Input processed only during `play`. Mouse clicks (`love.mousepressed`) also gated on `play`. During `day_end`, `buff_select`, and `gameover`, no movement occurs.
- **Order/Kitchen System** — Orders interactable only during `play`. During `day_end` or `buff_select`, the player cannot pick up or serve orders. Kitchen and trash zones remain rendered but inactive.
- **Customer System** — `customer_module.update()` called only during `play`. Customer patience does not tick and the spawn timer halts during `day_end` and `buff_select`.
- **Buff System** — Buff selection UI is visible and interactive only during `game.gameState == "buff_select"`. The Game State Manager enters `buff_select` after `day_end` when the Day Loop confirms the daily target was met. Buff selection transitions to `play` (next day). The `buffs_paused` state and mid-game cube interaction no longer exist.
- **HUD System** — HUD drawn during both `play` and `buffs_paused`. Not drawn during `menu` or `gameover` — those states use dedicated full-screen overlays.

## Formulas

The Game State Manager owns one formula-adjacent value: the session timer.

**Session Duration**
- `game.gameTimer` starts at `config.GAME_TIME` (90 seconds, defined in `config.lua`)
- Decremented each frame: `game.gameTimer = game.gameTimer - dt`
- Transition to `gameover` fires when: `game.gameTimer ≤ 0`

No other formulas are owned by this system. Score math, patience decay, and buff effects are specified in their respective system GDDs.

## Edge Cases

1. **Timer expires while buff menu is open** — Cannot happen. `game.gameTimer` only ticks during `play`. The session cannot end mid-buff-selection.
2. **R key pressed in `buff_select`** — The `buff_select` input block does not handle `r`. The key is silently ignored. The player must select a buff before any reset is possible.
3. **`resetGame()` called while customers are active** — `customer_module.reset()` clears all customers and releases their tables. No orphaned entity state persists after a reset.
4. **Score floor at 0** — Customer-leave penalties and wrong-serve deductions use `math.max(0, score - penalty)`. Score cannot go negative.
5. **`love.mousepressed` during `gameover`** — Gated on `game.gameState == "play"`. Mouse clicks are silently ignored in `gameover`. Only `r` key triggers a transition from `gameover`.

## Dependencies

**Upstream (this system depends on)**
- None. The Game State Manager is a Foundation-layer system with no dependencies. It relies only on LÖVE2D's callback architecture.

**Downstream (systems that depend on this)**
- **Score System** — reads `game.gameState` to gate score writes; uses reset on state transitions
- **Player Movement** — reads `game.gameState` to gate input processing
- **Order/Kitchen System** — reads `game.gameState` to gate interactivity
- **Customer System** — reads `game.gameState` to gate patience decay and spawning
- **Buff System** — reads `game.gameState` to gate menu display and buff application
- **HUD System** — reads `game.gameState` to determine which overlay to draw

**Owned variables exposed to other systems**

| Variable | Type | Read by |
|----------|------|---------|
| `game.gameState` | string | All systems |
| `game.gameTimer` | number | HUD System (timer display) |

## Tuning Knobs

| Knob | Location | Current Value | Effect |
|------|----------|---------------|--------|
| Session duration | `config.GAME_TIME` | 90 seconds | Play time per day. Raising gives players more time to accumulate score; lowering increases pressure per day. |
| Campaign length | Day Loop (unimplemented) | 7 days | Number of days before endless mode begins. |

Session duration is the primary lever for difficulty and pacing feel per day. Campaign length is owned by the Day Loop / Campaign system GDD.

> **Removed knobs**: `Max buff selections` (3) and `Cube interaction radius` (100 px) are no longer applicable — the mid-game cube interaction has been removed. Buff selection now occurs once between each day, governed by the Buff System GDD.

## Visual/Audio Requirements

No visual or audio assets are owned by this system. State transitions drive which overlays and menus the draw layer renders, but layout and content are owned by the HUD System and Buff System GDDs.

The `buffs_paused` state should produce a perceptible audio cue (silence, a snap, or a muffled-world effect) to reinforce the sudden freeze. Owned by audio implementation.

## UI Requirements

No UI elements are owned by this system. `game.gameState` drives which UI layer is rendered each frame, but all layout, content, and interaction handling is specified in the HUD System GDD.

## Acceptance Criteria

- [ ] Starting the game from `menu` (pressing `return` or `space`) resets all session variables and transitions to `play`
- [ ] The 90-second timer counts down only during `play`; it does not tick during `day_end`, `buff_select`, or `gameover`
- [ ] GIVEN the 90-second timer reaches 0 during `play`, WHEN the day ends, THEN state transitions to `day_end` (not `gameover`); all simulation halts
- [ ] GIVEN in `day_end` AND the daily money target was met AND days remain, WHEN the Day Loop evaluates, THEN state transitions to `buff_select`
- [ ] GIVEN in `day_end` AND the daily money target was not met, WHEN the Day Loop evaluates, THEN state transitions to `gameover`
- [ ] GIVEN in `buff_select`, WHEN the player selects a buff and presses `return` or `space`, THEN state transitions to `play`; day counter increments; timer resets
- [ ] GIVEN day 7 completed and target met, WHEN transitioning from `buff_select`, THEN the game continues in `play` (no separate endless state required)
- [ ] GIVEN in `day_end` or `buff_select`, WHEN the `r` key is pressed, THEN no state transition occurs; player must resolve the current screen
- [ ] There is no exit from `buff_select` without selecting a buff
- [ ] Customers do not lose patience and the spawn timer does not tick during `day_end` or `buff_select`
- [ ] Player input (WASD and mouse click) is inactive during `day_end`, `buff_select`, and `gameover`
- [ ] Pressing `r` in `gameover` resets all variables and transitions to `play`
- [ ] Pressing `r` in `play` (mid-run) resets all variables and transitions to `play`

## Open Questions

- **High-score persistence**: The current design resets all state on each new session. If a future version wants to display a personal best or leaderboard, a separate persistent storage system is needed. Not in scope for MVP.
- **Generic pause**: The game has no standard pause state — `day_end` and `buff_select` are gameplay-specific freezes, not a general pause. If the game targets platforms requiring compliant pause behavior, a separate `paused` state would need to be added.
- **Endless mode state detection**: The Day Loop signals endless mode internally; the Game State Manager uses `play` for both campaign and endless days. If future systems need to distinguish campaign vs. endless behavior, a flag (e.g., `game.isEndless`) should be added here rather than a new state. Not in scope for MVP.
