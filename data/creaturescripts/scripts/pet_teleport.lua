-- Pet Teleport System
-- Automatycznie teleportuje peta gdy gracz zmienia piętro

local petRings = {
    [56974] = "[Pet] Pakkun",
    [56975] = "[Pet] Gamabunta",
    [56976] = "[Pet] Katsuyu",
    [56977] = "[Pet] Manda"
}

function onChangeZone(player, fromZone, toZone)
    -- Sprawdź czy gracz ma założony pierścień z petem
    local ring = player:getSlotItem(CONST_SLOT_RING)
    if not ring then
        return true
    end
    
    local petName = petRings[ring:getId()]
    if not petName then
        return true
    end
    
    -- Znajdź peta gracza
    local summons = player:getSummons()
    for _, summon in ipairs(summons) do
        if summon:getName() == petName then
            -- Teleportuj peta do gracza
            local playerPos = player:getPosition()
            summon:teleportTo(playerPos)
            playerPos:sendMagicEffect(CONST_ME_TELEPORT)
            break
        end
    end
    
    return true
end
