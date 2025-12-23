-- config.lua
-- Game configuration and constants

local config = {}

-- Window settings
config.WINDOW_W = 800
config.WINDOW_H = 600

-- Game timing
config.SPAWN_INTERVAL = 4      -- seconds between new customers
config.GAME_TIME = 90          -- total game time in seconds
config.CUSTOMER_PATIENCE = 20  -- seconds before they leave

-- Game mechanics
config.PLAYER_SPEED = 240
config.ORDERS = {
    { name = "Burger", image = "Ghostpixxells_pixelfood/16_burger_dish.png" },
    { name = "Salad",  image = "Ghostpixxells_pixelfood/68_macncheese_dish.png" },
    { name = "Soup",   image = "Ghostpixxells_pixelfood/87_ramen.png" },
    { name = "Fries",  image = "Ghostpixxells_pixelfood/45_frenchfries_dish.png" },
    { name = "Taco",   image = "Ghostpixxells_pixelfood/100_taco_dish.png" },
}

-- UI Colors
config.COLORS = {
    background = {0.15, 0.17, 0.2},
    kitchen = {0.2, 0.35, 0.2},
    trash = {0.2, 0.35, 0.2},
    table_occupied = {0.45, 0.35, 0.25},
    table_empty = {0.25, 0.25, 0.25},
    player = {0.2, 0.6, 1},
    cube = {1, 0.8, 0.2},
    cube_border = {0.8, 0.6, 0},
    text_white = {1, 1, 1},
    text_yellow = {1, 1, 0},
}


return config
