local config = {
    minBallId = 12662, -- Minimalne Id senzu
    maxballId = 12679, -- Maksymalne Id senzu
}
function onUse(player, item, fromPosition, itemEx, toPosition, isHotkey)
    local randomSenzuId = math.random(config.minBallId, config.maxballId)
    player:addItem(randomSenzuId, 1)
    item:remove(1)

    return true
end