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
        stamina = 0,
        hasPlate = false,
        plateOrder = nil,
        playerImage = love.graphics.newImage('assets/player.png'),
        targetX = nil,
        targetY = nil,
    }
end

function player_module.move(player, dt, config, keys)
    -- WASD/Arrow key movement takes priority and cancels click-to-move
    if keys then
        local dx, dy = 0, 0
        if keys.left  then dx = dx - 1 end
        if keys.right then dx = dx + 1 end
        if keys.up    then dy = dy - 1 end
        if keys.down  then dy = dy + 1 end

        if dx ~= 0 or dy ~= 0 then
            local len = (dx * dx + dy * dy) ^ 0.5
            dx, dy = dx / len, dy / len
            player.x = math.max(0, math.min(config.WINDOW_W - player.w, player.x + dx * player.speed * dt))
            player.y = math.max(0, math.min(config.WINDOW_H - player.h, player.y + dy * player.speed * dt))
            player.targetX = nil
            player.targetY = nil
            return
        end
    end

    -- Click-to-move
    if player.targetX and player.targetY then
        local dx = player.targetX - (player.x + player.w / 2)
        local dy = player.targetY - (player.y + player.h / 2)
        local dist = (dx * dx + dy * dy) ^ 0.5

        if dist > 5 then
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
