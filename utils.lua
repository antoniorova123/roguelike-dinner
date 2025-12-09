-- utils.lua
-- Utility functions

local utils = {}

function utils.distance(a, b)
    return ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) ^ 0.5
end

function utils.isNearKitchen(player, kitchen)
    return (player.x < kitchen.x + kitchen.w + 20 and
            player.y + player.h / 2 > kitchen.y - 20 and
            player.y + player.h / 2 < kitchen.y + kitchen.h + 20)
end

function utils.isNearCustomer(player, customer, range)
    return utils.distance({x = player.x + player.w / 2, y = player.y + player.h / 2}, {x = customer.x, y = customer.y}) < range
end

function utils.isNearCube(player, cube, range)
    return utils.distance({x = player.x + player.w / 2, y = player.y + player.h / 2}, {x = cube.x, y = cube.y}) < range
end

return utils
