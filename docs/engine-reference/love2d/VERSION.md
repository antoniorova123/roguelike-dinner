# LÖVE2D — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | LÖVE 11.5 |
| **Runtime Language** | Lua (LuaJIT / Lua 5.1 + select 5.2 extensions) |
| **Release Date** | December 3, 2023 |
| **Project Pinned** | 2026-04-21 |
| **Last Docs Verified** | 2026-04-21 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | LOW — version is within LLM training data |

## Notes

LÖVE 11.x has been stable since 11.0 (2019). No significant breaking changes
within the 11.x series. LLM knowledge of the LÖVE2D 11.5 API is reliable.

Verify against https://love2d.org/wiki/Main_Page for edge cases in:
- `love.physics` (Box2D wrapper — joint/body API can be subtle)
- `love.graphics.newShader` (GLSL dialect is LÖVE-specific)
- `love.audio` (OpenAL-based — platform behavior varies)

## LÖVE 12 Watch

LÖVE 12 is in development (targets Lua 5.4 natively, drops LuaJIT).
If/when it releases, run `/setup-engine upgrade 11.5 12.0` to get a
migration audit before switching.
