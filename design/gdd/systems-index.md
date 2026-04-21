# Systems Index — Proyecto Rome

> **Generated**: 2026-04-21
> **Based on**: `design/gdd/game-concept.md`
> **Review Mode**: Lean

CD-SYSTEMS skipped — Lean mode.

---

## All Systems

| # | System | Layer | Category | Priority | Status | Design Doc |
|---|--------|-------|----------|----------|--------|------------|
| 1 | Game State Manager | Foundation | Core/Infrastructure | MVP | Designed | design/gdd/game-state-manager.md |
| 2 | Score System | Foundation | Core/Infrastructure | MVP | Not Started | — |
| 3 | Player Movement | Core | Camera/Input | MVP | Not Started | — |
| 4 | Order/Kitchen System | Feature | Combat/Interaction | MVP | Not Started | — |
| 5 | Customer System | Feature | AI | MVP | Not Started | — |
| 6 | Buff System | Complex Feature | Progression | MVP | Not Started | — |
| 7 | HUD System | Presentation | UI | MVP | Not Started | — |

---

## Dependency Map

```
Layer 0 — Foundation
└── Game State Manager      (no dependencies)

Layer 1 — Core
├── Score System             depends on: Game State Manager
└── Player Movement          depends on: Game State Manager

Layer 2 — Feature
├── Order/Kitchen System     depends on: Player Movement, Score System
└── Customer System          depends on: Game State Manager, Score System

Layer 3 — Complex Feature
└── Buff System              depends on: Game State Manager, Player Movement,
                                         Customer System, Score System

Layer 4 — Presentation
└── HUD System               depends on: Game State Manager, Score System,
                                         Buff System, Player Movement
```

### Bottleneck Systems (high dependency count — design carefully)

| System | Dependents |
|--------|-----------|
| Game State Manager | Score System, Player Movement, Order/Kitchen System, Customer System, Buff System, HUD System |
| Score System | Order/Kitchen System, Customer System, Buff System, HUD System |

### Leaf Nodes (nothing depends on these)

- HUD System — lowest risk, can be designed last

---

## Recommended Design Order

| Order | System | Reason |
|-------|--------|--------|
| 1 | Game State Manager | Foundation — everything else depends on state transitions |
| 2 | Score System | Foundation — all consequence flows through score |
| 3 | Player Movement | Core — player can't interact without movement |
| 4 | Order/Kitchen System | Feature — defines the pickup half of the core loop |
| 5 | Customer System | Feature — defines the delivery target and patience pressure |
| 6 | Buff System | Complex Feature — the roguelike identity layer; needs all core systems defined first |
| 7 | HUD System | Presentation — designed last; reads data from all other systems |

---

## High-Risk Systems

| System | Risk | Reason |
|--------|------|--------|
| Game State Manager | HIGH | 6 of 7 systems depend on its state transitions — a bad contract here breaks everything |
| Score System | MEDIUM | 4 systems read or write to score — multiplier logic (from Buff System) must be spec'd carefully |
| Buff System | MEDIUM | Effects cross multiple systems; must be designed after all affected systems have GDDs |

---

## Progress Tracker

- Total systems: **7**
- MVP systems: **7**
- Designed: **1**
- In Review: **0**
- Approved: **0**
- Not Started: **6**

---

## Notes

- Input handling (keyboard + mouse) is folded into **Player Movement** — at this game's scale,
  LÖVE2D input callbacks don't warrant a separate system GDD.
- The 90-second game timer is folded into **Game State Manager**.
- `draw.lua` (rendering) and `music/` (audio) are infrastructure, not design systems —
  no GDDs needed at MVP.
- Stamina buff is a placeholder in the current code; it will be formally specified
  when the Buff System GDD is authored.
