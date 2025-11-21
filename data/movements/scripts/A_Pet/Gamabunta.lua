local summonName = "[Pet] Gamabunta"

function onEquip(player, item, slot, isCheck)
    if isCheck then
        return true
    end
 
    local playerSummons = player:getSummons(summonName)
    local playerPosition = player:getPosition()
    local summonsCount = 0

   
     if Tile(playerPosition):hasFlag(TILESTATE_PROTECTIONZONE) then
        return player:sendCancelMessage("You mustn't be in PZ!")-- error msg
    end
 
    for _,summon in pairs(playerSummons) do
        if summon:getName() == summonName then
            summonsCount = 1
        end
    end
 
    if summonsCount == 0 then
        local summon = Game.createMonster(summonName, playerPosition)
        summon:setMaster(player)
        summon:setDropLoot(false)
        summon:registerEvent('SummonThink')
        player:say("Summoning Jutsu: Gamabunta!", TALKTYPE_MONSTER_SAY)
    else
        player:sendCancelMessage("Gamabunta is already summoned.")-- error msg
    end
 
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