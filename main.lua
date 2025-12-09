-- main.lua
-- Dinner Dash - Simple Prototype for LÖVE (love2d)
-- Entry point that orchestrates the game

-- Import modules
local config = require("config")
local player_module = require("player")
local customer_module = require("customer")
local buff_module = require("buff")
local draw_module = require("draw")
local utils = require("utils")

-- Game state
local game = {
    gameState = "menu",          -- menu, play, buffs_paused, gameover
    score = 0,
    misses = 0,
    gameTimer = config.GAME_TIME,
    spawnTimer = 0,
    buffsSelected = 0,
    menuOpen = false,
    selectedMenuItem = 1,
    buffChoices = {},
}

-- Entities
local player
local entities = {}
local kitchen
local cube

-- Helper function to get current key states
local function getInputKeys()
    return {
        left = love.keyboard.isDown('left') or love.keyboard.isDown('a'),
        right = love.keyboard.isDown('right') or love.keyboard.isDown('d'),
        up = love.keyboard.isDown('up') or love.keyboard.isDown('w'),
        down = love.keyboard.isDown('down') or love.keyboard.isDown('s'),
    }
end

function love.load()
    love.window.setMode(config.WINDOW_W, config.WINDOW_H)
    love.window.setTitle("Dinner Dash - LÖVE (Prototype)")
    love.graphics.setFont(love.graphics.newFont(14))

    -- Initialize kitchen
    kitchen = {
        x = 60,
        y = config.WINDOW_H / 2 - 60,
        w = 120,
        h = 305,
    }
    -- Initialize Trash
    trash = {
        x = config.WINDOW_W - 150 - 20,
        y = config.WINDOW_H - 150 - 20,
        w = 90,
        h = 60,
    }

    -- Initialize player
    player = player_module.create(config)
    game.player = player

    -- Initialize entities
    customer_module.setupTables(entities, config)
    
    -- Initialize cube
    cube = {
        x = 450,
        y = 450,
        size = 60,
        rotation = 0,
    }

    love.math.setRandomSeed(os.time())
end

function love.update(dt)
    -- Update cube rotation (only during gameplay)
    if game.gameState == "play" then
        cube.rotation = cube.rotation + dt * 1.5
    end

    if game.gameState == "play" then
        -- Spawn timer
        game.spawnTimer = game.spawnTimer - dt
        if game.spawnTimer <= 0 then
            customer_module.spawnCustomer(entities, config)
            game.spawnTimer = config.SPAWN_INTERVAL
        end

        -- Game timer
        game.gameTimer = game.gameTimer - dt
        if game.gameTimer <= 0 then
            game.gameState = "gameover"
            return
        end

        -- Update player movement
        local keys = getInputKeys()
        player_module.move(player, dt, config, keys)

        -- Update customers
        customer_module.update(entities, config, dt)
    end
end

function love.keypressed(key)
    if key == 'escape' then love.event.quit() end

    if game.gameState == 'menu' then
        if key == 'return' or key == 'space' then
            resetGame()
        end
        return
    end

    if game.gameState == 'gameover' then
        if key == 'r' then resetGame() end
        return
    end

    if game.gameState == 'buffs_paused' then
        if key == "left" or key == "a" then
            game.selectedMenuItem = game.selectedMenuItem - 1
            if game.selectedMenuItem < 1 then game.selectedMenuItem = 3 end
            return
        elseif key == "right" or key == "d" then
            game.selectedMenuItem = game.selectedMenuItem + 1
            if game.selectedMenuItem > 3 then game.selectedMenuItem = 1 end
            return
        end

        if key == "return" or key == "space" then
            local selectedBuff = game.buffChoices[game.selectedMenuItem]
            selectedBuff.apply(player, config)
            
            if selectedBuff.name == "Score x2" then
                game.score = game.score * 2
            end
            
            game.buffsSelected = game.buffsSelected + 1
            game.gameState = "play"
            game.menuOpen = false
            return
        end
        return
    end

    if game.gameState == 'play' then
        if key == 'r' then resetGame(); return end

        -- Interact with cube for buff selection
        if key == 'e' then
            if utils.isNearCube(player, cube, 100) and game.buffsSelected < 3 then
                buff_module.openMenu(game, config)
                return
            end
        end

        -- Interact with kitchen or customers
        if key == 'space' then
            local isNearOrder, oName = utils.isNearOrder(player, entities.orders)
            if isNearOrder and not player.hasPlate then
                player.hasPlate = true
                player.plateOrder = oName
                return
            end
            local isNearTrash = utils.isNearTrash(player, trash)
            if isNearTrash and player.hasPlate then
                -- Discard plate
                player.hasPlate = false
                player.plateOrder = nil
                game.misses = game.misses + 1
                return
            end
            -- Try to serve customers
            local servedAny = false
            for i = #entities.customers, 1, -1 do
                local c = entities.customers[i]
                if utils.isNearCustomer(player, c, 60) then
                    if player.hasPlate then
                        if player.plateOrder == c.order then
                            game.score = game.score + 100 + math.floor(c.patience) * 2
                        else
                            game.misses = game.misses + 1
                            game.score = math.max(0, game.score - 30)
                        end
                        c.table.occupied = false
                        table.remove(entities.customers, i)
                        player.hasPlate = false
                        player.plateOrder = nil
                        servedAny = true
                        break
                    end
                end
            end

            -- Drop plate if not serving
            if not servedAny and player.hasPlate then
                player.hasPlate = false
                player.plateOrder = nil
                game.misses = game.misses + 1
            end
        end
    end
end

function resetGame()
    game.gameState = "play"
    game.score = 0
    game.misses = 0
    game.gameTimer = config.GAME_TIME
    game.spawnTimer = 1
    game.buffsSelected = 0
    game.menuOpen = false
    game.selectedMenuItem = 1
    game.buffChoices = {}
    
    player.x = 120
    player.y = config.WINDOW_H / 2
    player.hasPlate = false
    player.plateOrder = nil
    
    customer_module.reset(entities)
    customer_module.setupTables(entities, config)
end

function love.draw()
    love.graphics.clear(unpack(config.COLORS.background))

    if game.gameState == 'menu' then
        draw_module.drawMenu(config)
        return
    end

    -- Draw game elements
    draw_module.drawKitchen(kitchen, entities, config)
    draw_module.drawTables(entities.tables, config)
    draw_module.drawTrash(trash, config)
    draw_module.drawCustomers(entities.customers, config)
    draw_module.drawCube(cube, config)
    draw_module.drawPlayer(player, config)

    -- Draw UI
    draw_module.drawUI(game.gameTimer, game.score, game.misses, game.buffsSelected, config)

    -- Draw buff menu if open
    if game.menuOpen then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle('fill', 0, 0, config.WINDOW_W, config.WINDOW_H)
        draw_module.drawBuffMenu(game.buffChoices, game.selectedMenuItem, config)
    end

    -- Draw game over screen
    if game.gameState == 'gameover' then
        draw_module.drawGameOver(game.score, config)
    end
end
