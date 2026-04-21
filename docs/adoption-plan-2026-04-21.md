# Adoption Plan

> **Generated**: 2026-04-21
> **Project phase**: Pre-Production (working prototype — code ahead of all docs)
> **Engine**: LÖVE2D (Lua) — not yet configured in template format
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

These three gaps prevent all template skills from running. Fix them first.

### 1a. Create template directory structure

None of the expected directories exist in Proyecto Rome yet. Create them all:

```bash
mkdir -p design/gdd
mkdir -p design/narrative
mkdir -p design/levels
mkdir -p docs/architecture
mkdir -p production/epics
mkdir -p production/session-state
mkdir -p production/session-logs
mkdir -p tests/unit
mkdir -p tests/integration
mkdir -p .claude/docs
```

**Time**: 5 min
- [ ] Directory structure created in Proyecto Rome

### 1b. Create CLAUDE.md

Proyecto Rome needs its own `CLAUDE.md` so all skills know the project context.
Create `CLAUDE.md` in the root of Proyecto Rome with this content:

```markdown
# Proyecto Rome — Game Studio Config

Restaurant management game (Dinner Dash + roguelike buffs) built in LÖVE2D / Lua.

## Technology Stack

- **Engine**: LÖVE2D 11.x
- **Language**: Lua
- **Version Control**: Git with trunk-based development

## Project Structure

- `main.lua` — entry point and game loop
- `config.lua` — all game constants and tuning values
- `player.lua` — player movement and interaction
- `customer.lua` — customer AI and table management
- `buff.lua` — roguelike buff system
- `draw.lua` — all rendering and UI
- `utils.lua` — shared utility functions
- `design/` — game design documents
- `docs/` — architecture decisions and technical docs
- `production/` — sprint plans, milestones, session state
- `tests/` — automated tests

## Coding Standards

- Gameplay values must come from `config.lua`, never hardcoded inline
- All public functions should be testable (pass state as arguments, avoid globals where possible)
- Comments only for non-obvious WHY, not WHAT

## Collaboration Protocol

Every task follows: Question → Options → Decision → Draft → Approval
- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- No commits without user instruction
```

**Time**: 10 min
- [ ] `CLAUDE.md` created in Proyecto Rome root

### 1c. Configure LÖVE2D as the engine

Run `/setup-engine` to configure LÖVE2D formally in the template. This writes the
engine name, version, and specialist routing to `.claude/docs/technical-preferences.md`.

**Command**: `/setup-engine`
**Time**: 15 min
- [ ] `.claude/docs/technical-preferences.md` created with engine set to LÖVE2D
- [ ] Engine specialists configured (Lua code routing)

---

## Step 2: Fix High-Priority Gaps

### 2a. Generate the game concept document

The game concept lives informally in `README.md` and `Ideas.txt`. Convert it into
the formal GDD format the template expects.

**Command**: `/reverse-document` (point it at README.md and the existing Lua code)
**Time**: 30 min
- [ ] `design/gdd/game-concept.md` created with all 8 required sections

### 2b. Create engine reference for LÖVE2D

The template uses `docs/engine-reference/` to warn about API changes and knowledge
gaps. Create a version reference for LÖVE2D so ADR engine compatibility checks work.

Create `docs/engine-reference/love2d/VERSION.md` with this content:

```markdown
# LÖVE2D — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | LÖVE 11.5 |
| **Language** | Lua 5.4 |
| **Project Pinned** | 2026-04-21 |

## Notes

LÖVE2D is stable. No significant API breaks between 11.x versions.
LLM knowledge of LÖVE2D API is generally reliable — verify physics and
shader APIs against https://love2d.org/wiki/Main_Page for edge cases.
```

**Time**: 5 min
- [ ] `docs/engine-reference/love2d/VERSION.md` created

### 2c. Set project stage

Write `production/stage.txt` with value `pre-production` so phase detection
is authoritative rather than heuristic.

**Content**: `pre-production`
**Time**: 2 min
- [ ] `production/production/stage.txt` created with value `pre-production`

---

## Step 3: Bootstrap Infrastructure

Run these in order — each step depends on the previous one.

### 3a. Create systems index

Decompose the game concept into a systems table that all downstream skills use.

**Command**: `/map-systems`
**Time**: 30 min
- [ ] `design/gdd/systems-index.md` created with all 4+ systems listed

### 3b. Author GDDs for each system

Four systems need formal design documents. Run `/design-system` for each:

1. **Player movement** — WASD/click movement, interact with SPACE
   - [ ] `design/gdd/player-movement.md`
2. **Customer AI** — tables, orders, patience timers, patience loss on wrong orders
   - [ ] `design/gdd/customer-system.md`
3. **Buff system** — roguelike level-up, 4 buffs, pause-on-select
   - [ ] `design/gdd/buff-system.md`
4. **Score system** — earn points for correct orders, lose for mistakes, score ×2 buff
   - [ ] `design/gdd/score-system.md`

**Command**: `/design-system` (run once per system)
**Time**: 30–45 min per GDD
- [ ] All 4 GDDs created and approved

### 3c. Record architecture decisions

Key technical choices made so far need ADRs. Run `/architecture-decision` for each:

1. Engine choice — why LÖVE2D / Lua
2. Module structure — flat root layout vs. src/ subdirectory
3. State management — global state table in main.lua
4. Config pattern — all constants in config.lua

**Command**: `/architecture-decision` (run once per decision)
**Time**: 20 min per ADR
- [ ] 4 ADRs created in `docs/architecture/`

### 3d. Bootstrap requirement registry

**Command**: `/architecture-review`
**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` created

### 3e. Create control manifest

**Command**: `/create-control-manifest`
**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` created

### 3f. Create sprint tracking

**Command**: `/sprint-plan`
**Time**: 30 min
- [ ] `production/sprint-status.yaml` created

---

## Step 4: Medium-Priority Gaps

### 4a. Add automated tests for core math

The buff system and score calculations are deterministic — good candidates for
unit tests you can read and understand. Specifically:

- Speed buff: +20% movement speed calculation
- Patience buff: +2 seconds to timer
- Score multiplier: ×2 current score
- Score deduction: points lost for wrong order

**Command**: `/test-setup` to scaffold the framework, then `/test-helpers` for
LÖVE2D-specific test utilities.
**Time**: 1 session
- [ ] Test framework scaffolded in `tests/`
- [ ] Unit tests written for buff math and score calculations

### 4b. Organize speculative assets

`FreeAssets/` (city sprites) and `Ghostpixxells_pixelfood/` (103 food sprites) are
in the project root. These should live under `assets/` to keep root clean and match
the template layout.

This can wait until the assets are needed — don't move them until you're actively
using them.
**Time**: 10 min (when ready)
- [ ] `FreeAssets/` → `assets/FreeAssets/`
- [ ] `Ghostpixxells_pixelfood/` → `assets/food-sprites/`

---

## Step 5: Optional Improvements

### 5a. Write a narrative doc

Even a one-page "setting and tone" doc helps if you ever want to add dialogue,
customer names, or story flavor.
**Command**: `/design-system` with narrative focus
- [ ] `design/narrative/setting.md` created

### 5b. Plan a first sprint

Once GDDs exist, plan the first formal sprint from the Ideas.txt backlog.
**Command**: `/sprint-plan`
- [ ] `production/sprints/sprint-01.md` created

### 5c. Copy review-mode.txt

Review mode is already set to `lean` in the Claude Code Game Studios workspace.
Copy or recreate it in Proyecto Rome's `production/` directory.
**Content**: `lean`
- [ ] `production/review-mode.txt` created with value `lean`

---

## What to Expect from Existing Stories

No stories exist yet — this section will apply once `/create-stories` runs.
When stories are created from GDDs, existing ones are never regenerated.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved.
