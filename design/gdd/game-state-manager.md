# Game State Manager

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-04-21
> **Implements Pillar**: Core Infrastructure

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

1. The state machine has exactly four valid states: `menu`, `play`, `buffs_paused`, `gameover`. No other values are valid for `game.gameState`.
2. A single variable — `game.gameState` (string) — is the canonical source of truth. All systems read this variable; none may shadow it or maintain a local copy.
3. All LÖVE2D callbacks (`love.update`, `love.draw`, `love.keypressed`, `love.mousepressed`) gate their logic on `game.gameState` at the top of the function. A callback that proceeds without checking state is a contract violation.
4. Only the Game State Manager may write to `game.gameState`. No other system transitions state directly — they request it by triggering the Game State Manager's inputs (key events, timer expiry, buff selection).
5. `buffs_paused → play` is a **resume** (session variables intact). `menu → play` and `gameover → play` are **resets** (`resetGame()` called). This distinction is explicit and must not be blurred.
6. While in `buffs_paused`, all simulation halts — the game timer does not tick, customers do not lose patience, the player does not move. This is a full freeze, not slow-motion.
7. The game timer is owned by the Game State Manager. It ticks only during `play`. When it reaches zero, the Game State Manager transitions to `gameover`.
8. Entering `gameover` does not reset any variables — it only sets the state. Score, timer, and entity state persist until `resetGame()` is explicitly called.

### States and Transitions

| From | To | Trigger | Guard | Side Effects |
|------|----|---------|-------|--------------|
| `menu` | `play` | `return` or `space` key | — | `resetGame()` — all variables reset |
| `play` | `buffs_paused` | `e` key near cube | `buffsSelected < 3` AND player within 100 px of cube | `buff_module.openMenu()` called; `game.menuOpen = true` |
| `buffs_paused` | `play` | `return` or `space` key | Valid buff selected | Buff applied; `buffsSelected + 1`; `game.menuOpen = false` |
| `play` | `gameover` | `game.gameTimer ≤ 0` | — | None — score/entities persist for display |
| `gameover` | `play` | `r` key | — | `resetGame()` — all variables reset |
| `play` | `play` | `r` key | In `play` state | `resetGame()` — intentional mid-run reset |

**Note on buff menu cancellation**: There is no escape from `buffs_paused`. Once the buff menu opens, the player must select a buff. This is a deliberate design choice — the moment of choosing is a committed decision, not a menu to back out of.

### Interactions with Other Systems

- **Score System** — `game.score`, `game.misses`, `game.scoreMultiplier` are owned here. Score writes occur only during `play`. Score is read during `gameover` for display. All three are reset on `menu → play` and `gameover → play` transitions.
- **Player Movement** — Input processed only during `play`. Mouse clicks (`love.mousepressed`) also gated on `play`. During `buffs_paused` and `gameover`, no movement occurs.
- **Order/Kitchen System** — Orders interactable only during `play`. During `buffs_paused`, the player cannot pick up or serve orders. Kitchen and trash zones remain rendered but inactive.
- **Customer System** — `customer_module.update()` called only during `play`. Customer patience does not tick and the spawn timer halts during `buffs_paused`.
- **Buff System** — `buff_module.openMenu()` called only from `play` via the `e` key interaction. The menu is visible and interactive only when `game.menuOpen == true` AND `game.gameState == "buffs_paused"`. Buff selection transitions back to `play`.
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
2. **R key pressed in `buffs_paused`** — The `buffs_paused` input block does not handle `r`. The key is silently ignored. The player must select a buff before any reset is possible.
3. **Buff menu opened with `buffsSelected == 3`** — Guard requires `buffsSelected < 3`. Once three buffs have been selected, pressing `e` near the cube does nothing. The cube remains rendered but non-interactive.
4. **`resetGame()` called while customers are active** — `customer_module.reset()` clears all customers and releases their tables. No orphaned entity state persists after a reset.
5. **Score floor at 0** — Customer-leave penalties and wrong-serve deductions use `math.max(0, score - penalty)`. Score cannot go negative.
6. **`love.mousepressed` during `gameover`** — Gated on `game.gameState == "play"`. Mouse clicks are silently ignored in `gameover`. Only `r` key triggers a transition from `gameover`.

## Dependencies

**Upstream (this system depends on)**
- None. The Game State Manager is a Foundation-layer system with no dependencies. It relies only on LÖVE2D's callback architecture.

**Downstream (systems that depend on this)**
- **Score System** — reads `game.gameState` to gate score writes; uses reset on state transitions
- **Player Movement** — reads `game.gameState` to gate input processing
- **Order/Kitchen System** — reads `game.gameState` to gate interactivity
- **Customer System** — reads `game.gameState` to gate patience decay and spawning
- **Buff System** — reads `game.gameState` and `game.menuOpen` to gate menu display and buff application
- **HUD System** — reads `game.gameState` to determine which overlay to draw

**Owned variables exposed to other systems**

| Variable | Type | Read by |
|----------|------|---------|
| `game.gameState` | string | All systems |
| `game.gameTimer` | number | HUD System (timer display) |
| `game.menuOpen` | boolean | Buff System, draw layer |
| `game.buffsSelected` | number | Buff System (guard on menu open) |
| `game.scoreMultiplier` | number | Score System |

## Tuning Knobs

| Knob | Location | Current Value | Effect |
|------|----------|---------------|--------|
| Session duration | `config.GAME_TIME` | 90 seconds | Total play time per session. Raising gives players more time to accumulate score; lowering increases pressure. |
| Max buff selections | Guard in `love.keypressed` | 3 | Maximum buffs a player can select per session. |
| Cube interaction radius | Guard in `love.keypressed` | 100 px | Distance within which `e` opens the buff menu. |

Session duration is the primary lever for difficulty and pacing feel. The buff cap (3) ties to the number of buff selection milestones designed into the session arc.

## Visual/Audio Requirements

No visual or audio assets are owned by this system. State transitions drive which overlays and menus the draw layer renders, but layout and content are owned by the HUD System and Buff System GDDs.

The `buffs_paused` state should produce a perceptible audio cue (silence, a snap, or a muffled-world effect) to reinforce the sudden freeze. Owned by audio implementation.

## UI Requirements

No UI elements are owned by this system. `game.gameState` drives which UI layer is rendered each frame, but all layout, content, and interaction handling is specified in the HUD System GDD.

## Acceptance Criteria

- [ ] Starting the game from `menu` (pressing `return` or `space`) resets all session variables and transitions to `play`
- [ ] The 90-second timer counts down only during `play`; it does not tick during `buffs_paused`
- [ ] When the timer reaches 0, the game transitions to `gameover` with score and entities preserved
- [ ] Pressing `r` in `gameover` resets all variables and transitions to `play`
- [ ] Pressing `r` in `play` (mid-run) resets all variables and transitions to `play`
- [ ] Pressing `e` near the cube (within 100 px) while `buffsSelected < 3` and in `play` transitions to `buffs_paused` and opens the buff menu
- [ ] Selecting a buff in `buffs_paused` applies the buff, increments `buffsSelected`, and transitions back to `play`
- [ ] There is no way to exit `buffs_paused` without selecting a buff
- [ ] After 3 buffs are selected, pressing `e` near the cube does nothing
- [ ] Customers do not lose patience and the spawn timer does not tick during `buffs_paused`
- [ ] Player input (WASD and mouse click) is inactive during `buffs_paused` and `gameover`

## Open Questions

- **High-score persistence**: The current design resets all state on each new session. If a future version wants to display a personal best or leaderboard, a separate persistent storage system is needed. Not in scope for MVP.
- **Generic pause**: The game has no standard pause state — `buffs_paused` is the only freeze, and it has a specific gameplay purpose. If the game targets mobile or requires platform-compliant pause behavior, a separate `paused` state would need to be added.
