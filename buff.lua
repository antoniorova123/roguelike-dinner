-- buff.lua
-- Buff definitions and buff menu logic

local buff_module = {}

function buff_module.getBuff(config)
    return {
        { name = "Speed +", apply = function(player, config) player.speed = player.speed * 1.2 end },
        { name = "Patience +", apply = function(player, config) config.CUSTOMER_PATIENCE = config.CUSTOMER_PATIENCE + 2 end },
        { name = "Score x2", apply = function(player, config) return "score_x2" end },
        { name = "Stamina +", apply = function(player, config) player.stamina = player.stamina + 20 end },
    }
end

function buff_module.openMenu(game_state, config)
    game_state.gameState = "buffs_paused"
    game_state.menuOpen = true
    game_state.selectedMenuItem = 1
    game_state.buffChoices = {}

    local buffs = buff_module.getBuff(config)
    local pool = {}
    
    for i, v in ipairs(buffs) do
        pool[i] = v
    end

    for i = 1, 3 do
        if #pool > 0 then
            local idx = love.math.random(#pool)
            table.insert(game_state.buffChoices, pool[idx])
            table.remove(pool, idx)
        end
    end
end

function buff_module.selectBuff(game_state, buff, score)
    local selectedBuff = game_state.buffChoices[game_state.selectedMenuItem]
    buff:apply(game_state.player, game_state.config)
    
    if selectedBuff.name == "Score x2" then
        score = score * 2
    end
    
    game_state.buffsSelected = game_state.buffsSelected + 1
    game_state.gameState = "play"
    game_state.menuOpen = false
    
    return score
end

return buff_module
