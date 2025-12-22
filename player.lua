-- player.lua
-- Player state and mechanics

local player_module = {}

function player_module.create(config)
    return {
        x = 120,
        y = config.WINDOW_H / 2,
        w = 56,
        h = 80,
        speed = config.PLAYER_SPEED,
        hasPlate = false,
        plateOrder = nil,
        playerImage = love.graphics.newImage('assets/player.png'),
        targetX = nil,
        targetY = nil,
    }
end

function player_module.move(player, dt, config)
    if player.targetX and player.targetY then
        local dx = player.targetX - (player.x + player.w / 2)
        local dy = player.targetY - (player.y + player.h / 2)
        local dist = (dx * dx + dy * dy) ^ 0.5
        
        if dist > 5 then  -- threshold to stop moving
            dx, dy = dx / dist, dy / dist
            local newX = player.x + dx * player.speed * dt
            local newY = player.y + dy * player.speed * dt
            
            player.x = math.max(0, math.min(config.WINDOW_W - player.w, newX))
            player.y = math.max(0, math.min(config.WINDOW_H - player.h, newY))
        else
            player.targetX = nil
            player.targetY = nil
        end
    end
end
function player_module.setTarget(player, x, y)
    player.targetX = x
    player.targetY = y
end

function player_module.getCenter(player)
    return {x = player.x + player.w / 2, y = player.y + player.h / 2}
end

return player_module
