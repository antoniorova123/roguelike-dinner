-- utils.lua
-- Utility functions

local utils = {}

function utils.distance(a, b)
    return ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) ^ 0.5
end

function utils.isNearOrder(player, orders)
    -- check if player (center) is over an order rectangle
    local px, py = player.x + player.w/2, player.y + player.h/2
    for i, o in ipairs(orders) do
        if px >= o.x and px <= o.x + o.w and py >= o.y and py <= o.y + o.h then
            return true, o.name
        end
    end
    return false, nil
end

function utils.isNearTrash(player, trash)
    local px, py = player.x + player.w/2, player.y + player.h/2
    if px >= trash.x and px <= trash.x + trash.w and py >= trash.y and py <= trash.y + trash.h then
        return true
    end
    return false
end

function utils.isNearCustomer(player, customer, range)
    return utils.distance({x = player.x + player.w / 2, y = player.y + player.h / 2}, {x = customer.x, y = customer.y}) < range
end

function utils.isNearCube(player, cube, range)
    return utils.distance({x = player.x + player.w / 2, y = player.y + player.h / 2}, {x = cube.x, y = cube.y}) < range
end

return utils
