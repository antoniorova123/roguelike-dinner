# Proyecto Rome — Game Studio Config

Restaurant management game (Dinner Dash + roguelike buffs) built in LÖVE2D / Lua.

## Technology Stack

- **Engine**: LÖVE2D 11.5
- **Language**: Lua (LuaJIT / Lua 5.1)
- **Version Control**: Git with trunk-based development
- **Build System**: LÖVE2D runtime (`love .` to run; love-release for distribution)
- **Asset Pipeline**: LÖVE2D asset loader (love.graphics, love.audio)

## Engine Version Reference

@docs/engine-reference/love2d/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Project Structure

- `main.lua` — entry point and game loop
- `config.lua` — all game constants and tuning values
- `player.lua` — player movement and interaction
- `customer.lua` — customer AI and table management
- `buff.lua` — roguelike buff system
- `draw.lua` — all rendering and UI
- `utils.lua` — shared utility functions
- `design/` — game design documents (GDDs)
- `docs/` — architecture decisions and technical docs
- `production/` — sprint plans, milestones, session state
- `tests/` — automated tests

## Coding Standards

- Gameplay values must come from `config.lua`, never hardcoded inline
- All public functions should be testable (pass state as arguments, avoid globals where possible)
- Comments only for non-obvious WHY, not WHAT

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
