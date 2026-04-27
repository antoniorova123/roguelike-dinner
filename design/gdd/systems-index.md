# Systems Index — Proyecto Rome

> **Generated**: 2026-04-21
> **Updated**: 2026-04-23 — Added Day Loop / Campaign System and Animation System after
> brainstorm enrichment; revised dependency map and design order to reflect 7-day campaign structure.
> **Based on**: `design/gdd/game-concept.md`
> **Review Mode**: Lean

CD-SYSTEMS skipped — Lean mode.

---

## All Systems

| # | System | Layer | Category | Priority | Status | Design Doc |
|---|--------|-------|----------|----------|--------|------------|
| 1 | Game State Manager | Foundation | Core/Infrastructure | MVP | Designed | design/gdd/game-state-manager.md |
| 2 | Score System | Foundation | Core/Infrastructure | MVP | Designed | design/gdd/score-system.md |
| 3 | Day Loop / Campaign | Core | Core/Infrastructure | MVP | Designed | design/gdd/day-loop.md |
| 4 | Player Movement | Core | Camera/Input | MVP | Not Started | — |
| 5 | Order/Kitchen System | Feature | Interaction | MVP | Not Started | — |
| 6 | Customer System | Feature | AI | MVP | Not Started | — |
| 7 | Buff System | Complex Feature | Progression | MVP | Not Started | — |
| 8 | HUD System | Presentation | UI | MVP | Not Started | — |
| 9 | Animation System | Presentation | Visual/Animation | Alpha | Not Started | — |


---

## Dependency Map

```
Layer 0 — Foundation
├── Game State Manager    (no dependencies)
└── Score System          (no dependencies)

Layer 1 — Core
├── Player Movement       depends on: Game State Manager
└── Day Loop / Campaign   depends on: Game State Manager, Score System

Layer 2 — Feature
├── Order/Kitchen System  depends on: Player Movement, Score System
└── Customer System       depends on: Game State Manager, Score System

Layer 3 — Complex Feature
└── Buff System           depends on: Game State Manager, Day Loop,
                                      Player Movement, Customer System, Score System

Layer 4 — Presentation
├── HUD System            depends on: Game State Manager, Score System,
                                      Buff System, Player Movement, Day Loop
└── Animation System      depends on: Player Movement, Customer System
```

### Bottleneck Systems (high dependency count — design carefully)

| System | Dependents | Risk |
|--------|-----------|------|
| Game State Manager | Player Movement, Day Loop, Order/Kitchen, Customer, Buff, HUD (6 systems) | HIGH |
| Score System | Day Loop, Order/Kitchen, Customer, Buff, HUD (5 systems) | MEDIUM |
| Day Loop / Campaign | Buff System, HUD System (2 systems) | MEDIUM |

### Leaf Nodes (nothing depends on these — lowest risk, can be designed last)

- HUD System
- Animation System

---

## Recommended Design Order

| Order | System | Priority | Reason |
|-------|--------|----------|--------|
| 1 | Game State Manager | MVP | Foundation — GDD complete; `day_end` and `buff_select` states spec'd. Day Loop can now be designed against it. |
| 2 | Score System | MVP | Foundation — daily money targets and all consequence logic need score contracts defined before Day Loop or Features |
| 3 | Day Loop / Campaign | MVP | Core heartbeat of the 7-day campaign — all Feature systems must respect its day structure and escalation parameters |
| 4 | Player Movement | MVP | Enables all player–world interaction; Order/Kitchen and Customer systems need movement proximity checks |
| 5 | Order/Kitchen System | MVP | The pickup half of the core loop — defines what the player carries and how |
| 6 | Customer System | MVP | The delivery target and patience pressure — the "chill until it isn't" experience is owned here |
| 7 | Buff System | MVP | Roguelike identity (Pillar 2: Build Your Day) — needs all core systems defined; between-day behavior ties to Day Loop |
| 8 | HUD System | MVP | Reads data from all other systems; designed last so all data contracts are known |
| 9 | Animation System | Alpha | Presentation polish — MVP survives on color tints and static sprites; defer until core loop is validated |

---

## High-Risk Systems

| System | Risk | Reason |
|--------|------|--------|
| Game State Manager | HIGH | 6 of 9 systems depend on its state transitions — the new campaign states must be spec'd before others build against them |
| Score System | MEDIUM | 5 systems read or write to score — the daily target check and multiplier logic must be unambiguous |
| Day Loop / Campaign | MEDIUM | NEW system with no prototype reference — the escalation curve and target formula are open design questions |
| Buff System | MEDIUM | Behavior changed from mid-game cube to between-day selection — existing prototype code is being redesigned, not extended |

---

## Progress Tracker

- Total systems: **9**
- MVP systems: **8**
- Alpha systems: **1**
- Designed (current): **3** (Game State Manager, Score System, Day Loop / Campaign)
- Needs Revision: **0**
- In Review: **0**
- Approved: **0**
- Not Started: **6**

---

## Notes

- Input handling (keyboard + mouse) is folded into **Player Movement** — at this game's scale, LÖVE2D input callbacks don't warrant a separate system GDD.
- The 90-second session timer is now owned jointly by **Game State Manager** (it ticks during `play`) and **Day Loop** (it determines when a day ends). The Day Loop GDD will specify which system owns the authoritative tick.
- `draw.lua` (rendering) and `music/` (audio) are infrastructure, not design systems — no GDDs needed at MVP.
- Stamina buff is a placeholder in the current code; it will be formally specified in the **Buff System** GDD.
- **Animation System** is Presentation-layer and Alpha priority — MVP validates the core loop with static sprites and color tints (current approach). The Animation GDD is written after Player Movement and Customer System GDDs are approved.
