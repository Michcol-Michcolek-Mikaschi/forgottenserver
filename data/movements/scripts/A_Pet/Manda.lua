local summonName = "[Pet] Manda"

local function doSummonPet(playerId)
    local player = Player(playerId)
    if not player then
        return
    end
    
    local playerPosition = player:getPosition()
    local tile = Tile(playerPosition)
    
    -- Check if player is in protection zone
    if tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        player:sendCancelMessage("You can't summon pets in protection zone!")
        return
    end
    
    -- Check if pet is already summoned
    local playerSummons = player:getSummons()
    for _, summon in pairs(playerSummons) do
        if summon:getName() == summonName then
            return -- Pet already exists, don't summon again
        end
    end
    
    -- Try to create the monster
    local summon = Game.createMonster(summonName, playerPosition)
    if not summon then
        player:sendCancelMessage("Could not summon Manda here.")
        return
    end
    
    summon:setMaster(player)
    summon:setDropLoot(false)
    summon:registerEvent('SummonThink')
    player:say("Summoning Jutsu: Manda!", TALKTYPE_MONSTER_SAY)
end

function onEquip(player, item, slot, isCheck)
    if isCheck then
        return true
    end
    
    -- Delay summon to ensure player is fully loaded (fixes login crash)
    addEvent(doSummonPet, 1000, player:getId())
    
    return true
end

function onDeEquip(creature, item, slot)

local creatureSummons = creature:getSummons(summonName)
local creaturePosition = creature:getPosition()
 
for _,summon in pairs(creatureSummons) do
    if summon:getName() == summonName  then
        summon:getPosition():sendMagicEffect(6) -- 3 = poff, 6 = explosion
        doRemoveCreature(summon:getId())
    else
        -- nothing happens
    end
end

return true
end