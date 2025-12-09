-- draw.lua
-- All drawing and rendering logic

local draw_module = {}

function draw_module.drawMenu(config)
    local lg = love.graphics
    lg.setColor(1, 1, 1)
    lg.printf("Dinner Dash - Prototype", 0, 120, config.WINDOW_W, 'center')
    lg.printf("Presiona ENTER o SPACE para empezar", 0, 180, config.WINDOW_W, 'center')
    lg.printf("Movimiento: WASD / Flechas. Interactuar: ESPACIO. Reiniciar: R", 0, 240, config.WINDOW_W, 'center')
end



function draw_module.drawKitchen(kitchen, entities, config)
    local lg = love.graphics
    -- Draw kitchen block
    lg.setColor(unpack(config.COLORS.kitchen))
    lg.rectangle('fill', kitchen.x, kitchen.y, kitchen.w, kitchen.h, 6, 6)
    lg.setColor(unpack(config.COLORS.text_white))
    lg.printf("KITCHEN", kitchen.x, kitchen.y - 20, kitchen.w, 'center')

    -- Draw colored rectangles for each order type (grid layout)
    local rectW, rectH = 110, 44
    local gapX, gapY = 12, 16
    local cols = 1
    local startX = kitchen.x + 5
    local startY = kitchen.y + 6

    -- simple color palette for orders (will cycle if more orders than colors)
    local palette = {
        {0.85, 0.35, 0.35}, -- red-ish
        {0.35, 0.75, 0.35}, -- green-ish
        {0.35, 0.55, 0.9},  -- blue-ish
        {0.95, 0.8, 0.25},  -- yellow-ish
        {0.7, 0.4, 0.9},    -- purple-ish
    }

    -- prepare or clear orders entity list so other systems can reference them
    entities.orders = entities.orders or {}
    for i, order in ipairs(config.ORDERS) do
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (rectW + gapX)
        local y = startY + row * (rectH + gapY) + 10

        -- label on top of the rectangle
        lg.setColor(unpack(config.COLORS.text_white))
        lg.printf(order, x, y - 18, rectW, 'center')

        -- rectangle colored by palette
        local color = palette[((i - 1) % #palette) + 1]
        lg.setColor(unpack(color))
        lg.rectangle('fill', x, y, rectW, rectH, 6, 6)

        -- border
        lg.setColor(unpack(config.COLORS.table_empty))
        lg.rectangle('line', x, y, rectW, rectH, 6, 6)
        
        -- save rectangle as an order entity so game logic can reference its position and size
        entities.orders[i] = { name = order, x = x, y = y, w = rectW, h = rectH }
    end
end

function draw_module.drawTables(tables, config)
    local lg = love.graphics
    for _, t in ipairs(tables) do
        if t.occupied then
            lg.setColor(unpack(config.COLORS.table_occupied))
        else
            lg.setColor(unpack(config.COLORS.table_empty))
        end
        lg.rectangle('fill', t.x, t.y, t.w, t.h, 6, 6)
    end
end

function draw_module.drawCustomers(customers, config)
    local lg = love.graphics
    for _, c in ipairs(customers) do
        lg.setColor(1, 1 - c.anger, 1 - c.anger)
        lg.circle('fill', c.x, c.y - 22, 18)
        lg.setColor(0, 0, 0)
        lg.printf(c.order, c.x - 40, c.y + 2, 80, 'center')
        
        -- Patience bar
        local barW = 60
        local pct = math.max(0, c.patience / config.CUSTOMER_PATIENCE)
        lg.setColor(0.15, 0.15, 0.15)
        lg.rectangle('fill', c.x - barW / 2, c.y + 28, barW, 8)
        lg.setColor(0.2, 0.8, 0.2)
        lg.rectangle('fill', c.x - barW / 2, c.y + 28, barW * pct, 8)
    end
end

function draw_module.drawCube(cube, config)
    local lg = love.graphics
    lg.push()
    lg.translate(cube.x, cube.y)
    lg.rotate(cube.rotation)
    lg.setColor(unpack(config.COLORS.cube))
    lg.rectangle('fill', -cube.size / 2, -cube.size / 2, cube.size, cube.size)
    lg.setColor(unpack(config.COLORS.cube_border))
    lg.rectangle('line', -cube.size / 2, -cube.size / 2, cube.size, cube.size)
    lg.pop()
end

function draw_module.drawPlayer(player, config)
    local lg = love.graphics
    lg.setColor(unpack(config.COLORS.player))
    lg.rectangle('fill', player.x, player.y, player.w, player.h, 4, 4)
    
    if player.hasPlate then
        lg.setColor(unpack(config.COLORS.text_white))
        lg.circle('fill', player.x + player.w / 2, player.y - 12, 10)
        lg.setColor(0, 0, 0)
        lg.printf(player.plateOrder, player.x - 40, player.y - 30, 120, 'center')
    end
end

function draw_module.drawUI(gameTimer, score, misses, buffsSelected, config)
    local lg = love.graphics
    local floor = math.floor
    
    lg.setColor(unpack(config.COLORS.text_white))
    lg.print(string.format("Tiempo: %02d:%02d", floor(gameTimer / 60), floor(gameTimer % 60)), 10, 10)
    lg.print("Puntaje: " .. score, 10, 30)
    lg.print("Errores: " .. misses, 10, 50)

    if buffsSelected < 3 then
        lg.printf("Presiona R para reiniciar | ESC para salir | E cerca del cubo para buff (" .. buffsSelected .. "/3)", 0, config.WINDOW_H - 30, config.WINDOW_W, 'center')
    else
        lg.printf("Presiona R para reiniciar | ESC para salir | Buffs completos!", 0, config.WINDOW_H - 30, config.WINDOW_W, 'center')
    end
end

function draw_module.drawBuffMenu(buffChoices, selectedMenuItem, config)
    local lg = love.graphics
    for i, buff in ipairs(buffChoices) do
        local x = 100 + (i - 1) * 200
        local y = 200

        if i == selectedMenuItem then
            lg.setColor(unpack(config.COLORS.text_yellow))
        else
            lg.setColor(unpack(config.COLORS.text_white))
        end

        lg.rectangle("line", x, y, 180, 100)
        lg.print(buff.name, x + 20, y + 40)
    end
end

function draw_module.drawGameOver(score, config)
    local lg = love.graphics
    lg.setColor(0, 0, 0, 0.6)
    lg.rectangle('fill', 0, 0, config.WINDOW_W, config.WINDOW_H)
    lg.setColor(unpack(config.COLORS.text_white))
    lg.printf("GAME OVER", 0, config.WINDOW_H / 2 - 60, config.WINDOW_W, 'center')
    lg.printf("Puntaje final: " .. score, 0, config.WINDOW_H / 2 - 20, config.WINDOW_W, 'center')
    lg.printf("Presiona R para jugar otra vez", 0, config.WINDOW_H / 2 + 20, config.WINDOW_W, 'center')
end

return draw_module
