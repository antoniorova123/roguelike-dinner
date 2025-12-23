-- customer.lua
-- Customer state and management

local customer_module = {}

function customer_module.create(config)
    return {
        customers = {},
        tables = {},
    }
end

function customer_module.setupTables(entities, config)
    entities.tables = {}
    local cols = 3
    local rows = 2
    local startX = 300
    local startY = 120
    local gapX = 150
    local gapY = 150
    
    for r = 1, rows do
        for c = 1, cols do
            local tx = startX + (c - 1) * gapX
            local ty = startY + (r - 1) * gapY
            table.insert(entities.tables, {x = tx, y = ty, w = 80, h = 50, occupied = false, id = #entities.tables + 1})
        end
    end
end

function customer_module.spawnCustomer(entities, config)
    -- Find free table
    local free = nil
    for _, t in ipairs(entities.tables) do
        if not t.occupied then
            free = t
            break
        end
    end
    if not free then return end
    
    free.occupied = true
    index = love.math.random(#config.ORDERS)
    local order = config.ORDERS[index].name
    for _, item in ipairs(config.ORDERS) do
        if item.name == order then
            foodImage = love.graphics.newImage(item.image)
            break
        end
    end
    local cust = {
        x = free.x + free.w / 2,
        y = free.y + free.h / 2,
        table = free,
        order = order,
        patience = config.CUSTOMER_PATIENCE,
        served = false,
        anger = 0,
        foodImage = foodImage
    }
    table.insert(entities.customers, cust)
end

function customer_module.update(entities, config, dt)
    for i = #entities.customers, 1, -1 do
        local c = entities.customers[i]
        if not c.served then
            c.patience = c.patience - dt
            c.anger = math.max(0, 1 - (c.patience / config.CUSTOMER_PATIENCE))
            if c.patience <= 0 then
                c.table.occupied = false
                table.remove(entities.customers, i)
            end
        end
    end
end

function customer_module.reset(entities)
    entities.customers = {}
    for _, t in ipairs(entities.tables) do
        t.occupied = false
    end
end

return customer_module
