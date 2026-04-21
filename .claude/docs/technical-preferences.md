# Technical Preferences

## Engine & Language

- **Engine**: LÖVE2D 11.5
- **Language**: Lua (LuaJIT / Lua 5.1)
- **Rendering**: LÖVE2D 2D renderer (OpenGL / Metal backend)
- **Physics**: LÖVE2D physics (Box2D wrapper) — or custom per-object timers

## Input & Platform

- **Target Platforms**: PC (Windows, macOS, Linux)
- **Input Methods**: Keyboard, Mouse
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: None (future consideration)
- **Touch Support**: None
- **Platform Notes**: WASD / Arrow Keys for movement, SPACE for interact

## Naming Conventions

- **Modules/Files**: snake_case (player.lua, customer.lua, buff.lua)
- **Global tables**: PascalCase (Player, Customer, Buff)
- **Functions**: camelCase (updateCustomers, drawHUD)
- **Variables**: camelCase (moveSpeed, patienceTimer)
- **Constants**: UPPER_SNAKE_CASE in config.lua (MAX_SPEED, TABLE_COUNT)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms (love.update + love.draw combined)
- **Draw Calls**: Not a primary concern for 2D — focus on update loop cost
- **Memory Ceiling**: Not yet defined

## Testing

- **Framework**: busted (Lua BDD test framework)
- **Minimum Coverage**: Core math in buff.lua and scoring logic in main.lua
- **Required Tests**: Buff calculations, score delta on correct/incorrect orders

## Forbidden Patterns

- [None configured yet]

## Allowed Libraries / Addons

- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: gameplay-programmer (Lua gameplay code — no dedicated LÖVE2D specialist exists)
- **Language/Code Specialist**: gameplay-programmer
- **Shader Specialist**: technical-artist (for any custom GLSL shaders via love.graphics.newShader)
- **UI Specialist**: ui-programmer (HUD and menus via love.graphics draw calls)
- **Routing Notes**: LÖVE2D is not a natively supported engine in the template. Use gameplay-programmer for all Lua code review and implementation. Use lead-programmer for architecture decisions.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.lua files) | gameplay-programmer |
| Shader files (.glsl — via love.graphics.newShader) | technical-artist |
| Config / data (.lua config files) | gameplay-programmer |
| General architecture review | lead-programmer |
