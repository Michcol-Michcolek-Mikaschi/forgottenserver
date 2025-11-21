-- Summon Think Event
-- Teleportuje peta gdy jest za daleko od gracza

function onThink(creature, interval)
    local master = creature:getMaster()
    if not master then
        creature:remove()
        return false
    end
    
    local creaturePos = creature:getPosition()
    local masterPos = master:getPosition()
    
    -- Sprawdź czy pet jest na tym samym piętrze
    if creaturePos.z ~= masterPos.z then
        creature:teleportTo(masterPos)
        masterPos:sendMagicEffect(CONST_ME_TELEPORT)
        return true
    end
    
    -- Sprawdź dystans
    local distance = math.max(
        math.abs(creaturePos.x - masterPos.x),
        math.abs(creaturePos.y - masterPos.y)
    )
    
    -- Jeśli pet jest za daleko (więcej niż 7 sqm), teleportuj go
    if distance > 7 then
        creature:teleportTo(masterPos)
        masterPos:sendMagicEffect(CONST_ME_TELEPORT)
    end
    
    return true
end
