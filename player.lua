-- player.lua
-- Player state and mechanics

local player_module = {}

function player_module.create(config)
    return {
        x = 120,
        y = config.WINDOW_H / 2,
        w = 28,
        h = 40,
        speed = config.PLAYER_SPEED,
        hasPlate = false,
        plateOrder = nil,
    }
end

function player_module.move(player, dt, config, keys)
    local dx, dy = 0, 0
    if keys.left then dx = dx - 1 end
    if keys.right then dx = dx + 1 end
    if keys.up then dy = dy - 1 end
    if keys.down then dy = dy + 1 end
    
    if dx ~= 0 or dy ~= 0 then
        local len = (dx * dx + dy * dy) ^ 0.5
        dx, dy = dx / len, dy / len
        
        local newX = player.x + dx * player.speed * dt
        local newY = player.y + dy * player.speed * dt
        
        player.x = math.max(0, math.min(config.WINDOW_W - player.w, newX))
        player.y = math.max(0, math.min(config.WINDOW_H - player.h, newY))
    end
end

function player_module.getCenter(player)
    return {x = player.x + player.w / 2, y = player.y + player.h / 2}
end

return player_module
