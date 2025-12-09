<<<<<<< HEAD
# roguelike-dinner
=======
# Dinner Dash - Rome Edition

A simple Dinner Dash-style game prototype built with LÖVE (love2d) in Lua. Manage tables, serve customers, and level up with buffs in a roguelike-inspired fast-paced restaurant game.

## Features

- **Fast-paced Gameplay**: Serve customers before their patience runs out
- **Buff System**: Select 3 buffs during gameplay to enhance your abilities (roguelike style)
- **Dynamic Customers**: Customers appear at tables with random orders and patience levels
- **Score System**: Earn points for correct orders, lose points for mistakes
- **Pause on Buff Selection**: Game pauses while you choose buffs, similar to roguelike leveling

## Game Mechanics

- **Movement**: WASD or Arrow Keys
- **Interact**: SPACE (pick up plates at kitchen, serve customers)
- **Buff Menu**: E (near the cube to select buffs)
- **Restart**: R
- **Quit**: ESC

## Project Structure

```
├── main.lua          # Entry point and game orchestration
├── config.lua        # Game configuration and constants
├── player.lua        # Player mechanics and movement
├── customer.lua      # Customer and table management
├── buff.lua          # Buff system definitions
├── draw.lua          # All rendering and UI
├── utils.lua         # Utility functions
└── music/            # Audio assets
```

## Running the Game

1. Install LÖVE from [love2d.org](https://love2d.org)
2. Navigate to the project directory
3. Run: `love .`

## Development

The code is organized into modular files for easy maintenance and extension:
- **config.lua**: Adjust game balance and colors
- **buff.lua**: Add new buff types and effects
- **draw.lua**: Modify UI and visual elements
- **player.lua**: Tweak player movement and mechanics

## Buffs

- **Speed +**: Increases player movement speed by 20%
- **Patience +**: Adds 2 seconds to customer patience
- **Score x2**: Doubles your current score
- **Stamina +**: Adds 20 stamina points

## Future Improvements

- [ ] Sound effects and background music
- [ ] More buff varieties and effects
- [ ] Difficulty levels
- [ ] High score tracking
- [ ] More customer types
- [ ] Animated sprites

## License

MIT - Feel free to modify and use as you wish!
>>>>>>> 694fa76 (Primera version del juego)
