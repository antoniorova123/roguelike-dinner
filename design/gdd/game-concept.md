---
status: reverse-documented
source: main.lua, player.lua, customer.lua, buff.lua, draw.lua, config.lua
date: 2026-04-21
verified-by: user
---

# Game Concept — Proyecto Rome

> This document was reverse-engineered from the existing LÖVE2D prototype.
> It captures current behavior and clarified design intent.
> Sections marked [TO IMPLEMENT] describe intended behavior not yet in code.

## Overview

Proyecto Rome is a fast-paced 2D restaurant management game built in LÖVE2D.
The player controls a waiter navigating a restaurant floor — picking up orders
from the kitchen, reading tables, and serving customers before their patience
expires. A roguelike buff system lets the player permanently upgrade their run
up to three times per session. The goal is to maximize score within a 90-second
time limit by serving orders correctly, serving them fast, and making smart buff
choices.

## Player Fantasy

The player should feel like a skilled waiter who is always one step ahead of
the chaos. Every second spent walking is a second someone's patience is
dropping. The buff system gives each run a distinct identity — a speed-focused
run feels different from a patience-focused one. Mastery is rewarded through
route efficiency and reading the table layout, not just reflexes.

## Detailed Rules

### Core Loop
1. Customer spawns at a free table and starts losing patience immediately
2. Player reads the customer's order, navigates to the matching kitchen slot
3. Player picks up the plate and carries it to the customer's table
4. Correct delivery scores points; serving fast scores more
5. Wrong delivery loses points and frees the player's hands
6. If a customer's patience expires, they leave and the player loses points
7. Up to 3 times per game, the player can press E near the buff cube
   to pause and choose a permanent run upgrade
8. The game ends when the 90-second timer reaches zero

### Player Movement
- **Click-to-move**: Left-click anywhere to set a movement target; player
  moves toward it at constant speed and stops within 5px of the target
- **WASD / Arrow Keys**: Direct movement (four cardinal directions)
  [TO IMPLEMENT — getInputKeys() is defined but not yet connected to movement]
- Both input schemes should work simultaneously
- Movement is bounded by the window edges

### Order System
- Kitchen occupies the left side of the screen
- 5 order types are displayed as interactive slots (Burger, Salad, Soup,
  Fries, Taco)
- Player picks up an order by walking over a kitchen slot
- Player carries one plate at a time; carried order label is shown above
  the player's head
- Player can discard a plate at the trash can (+1 miss, no score change,
  hand freed)

### Customer System
- 6 tables arranged in a 3×2 grid
- A new customer spawns every 4 seconds if a free table exists
- Each customer is assigned a random order from the 5 menu items
- Customers have a patience timer (default 20 seconds) that depletes
  in real time
- Visual anger: customer sprite tints white→red as patience drops;
  a patience bar is displayed above each customer
- If patience reaches 0: customer leaves, player loses 50 points

### Serving
- Player must be within 60px of a customer to attempt delivery
- **Correct order**: score increases (see Formulas); customer leaves;
  table freed
- **Wrong order**: −30 points (floored at 0); +1 miss; plate is dropped

### Buff System
- A rotating yellow cube on the restaurant floor is the buff station
- Press E within 100px of the cube to open the buff menu
- Maximum 3 buff selections per game session
- Buff menu pauses the game entirely
- 3 random buffs are drawn without replacement from a pool of 4
- Navigate choices with A/D or Left/Right arrows; confirm with Enter/Space

**Buff effects:**

| Buff | Effect |
|------|--------|
| Speed + | Player move speed ×1.2 (stackable) |
| Patience + | All future customer patience +2 seconds |
| Score ×2 | All future score gains are doubled [TO IMPLEMENT — currently modifies current total] |
| Stamina + | Reserved — no current mechanic; placeholder for future buff pool expansion |

### Score and End State
- Game ends when the 90-second timer reaches zero
- Final score is displayed on the game over screen
- Press R to restart with a fresh session; ESC to quit

## Formulas

**Correct serve points (base):**
```
points = 100 + floor(customer.patience) × 2
```
Range: 100 pts (near-zero patience) to 140 pts (full 20s patience)

**With Score ×2 buff active:**
```
points = (100 + floor(customer.patience) × 2) × scoreMultiplier
```
`scoreMultiplier` starts at 1, doubles to 2 when the buff is selected.
Stacks if selected twice: ×2 then ×4.

**Wrong serve penalty:**
```
score = max(0, score − 30)
```

**Customer leave penalty:**
```
score = max(0, score − 50)
```

**Customer anger (visual only):**
```
anger = 1 − (patience / CUSTOMER_PATIENCE)
```
Range 0.0 → 1.0. Drives the white-to-red tint on the customer sprite.

## Edge Cases

- **All 6 tables occupied**: No new customer spawns until a table is freed
- **Player discards at trash**: +1 miss, no score change, hand freed;
  player must return to kitchen for a new plate
- **Score below 0**: Always floored at 0 — score never goes negative
- **Wrong order delivered**: Plate dropped, player must return to kitchen
- **Buff cube at 3/3 used**: E key near cube has no effect after 3 selections
- **Speed + stacked multiple times**: Each application multiplies speed by
  1.2 again — no defined cap; can stack up to 3× if chosen repeatedly
- **Patience + applied after customers spawn**: Changes the config value;
  only affects customers that spawn after the buff is selected, not existing ones
- **Score ×2 selected when score is 0**: No retroactive effect —
  multiplier applies to all future gains only

## Dependencies

- **Player movement system** — speed, direction, window bounds clamping,
  WASD + click-to-move input
- **Customer AI system** — patience timers, anger feedback, table
  management, spawn scheduling
- **Buff system** — pool management, random selection, pause state,
  effect application
- **Score system** — point accumulation, penalty application,
  score multiplier, floor-at-zero
- **Order / Kitchen system** — slot layout, pickup proximity detection,
  plate carry state
- **Input system** — keyboard (movement + buff navigation) and mouse
  (click-to-move)

## Tuning Knobs

All values live in `config.lua`:

| Constant | Current Value | Effect |
|----------|--------------|--------|
| `GAME_TIME` | 90 s | Total session length |
| `SPAWN_INTERVAL` | 4 s | Seconds between customer spawns |
| `CUSTOMER_PATIENCE` | 20 s | Starting patience per customer |
| `PLAYER_SPEED` | 240 px/s | Base movement speed |
| Base serve score | 100 pts | Minimum points for a correct serve |
| Patience bonus | ×2 pts/s | Points per second of remaining patience |
| Wrong serve penalty | −30 pts | Cost of delivering the wrong order |
| Customer leave penalty | −50 pts | Cost when patience expires |
| Buff range | 100 px | Activation radius around the buff cube |
| Serve range | 60 px | Delivery radius around a customer |
| Max buffs per game | 3 | Roguelike selections per session |
| Speed buff multiplier | ×1.2 | Speed increase per Speed + selection |
| Patience buff bonus | +2 s | Patience increase per Patience + selection |

## Acceptance Criteria

- [ ] Player navigates using WASD/Arrow Keys and click-to-move simultaneously
- [ ] Player picks up an order by walking over the correct kitchen slot
- [ ] Delivering the correct order to a matching customer awards 100–140 pts
- [ ] Delivering the wrong order deducts 30 pts and never drops score below 0
- [ ] Customer patience depletes over 20 seconds with visible anger tint and bar
- [ ] A customer leaving due to impatience deducts 50 pts
- [ ] New customers spawn every 4 seconds when a free table exists
- [ ] Pressing E near the buff cube opens the selection menu (max 3 times/game)
- [ ] Score ×2 buff doubles all future earnings (not the current total)
- [ ] Speed + applies a ×1.2 multiplier to player speed
- [ ] Patience + adds 2 seconds to all future customer patience values
- [ ] Game ends at 90 seconds and displays the final score
- [ ] Press R to restart with a clean state; ESC to quit
