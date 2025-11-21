local summonName = "Wolf"
local summonNamex = "Wolf"

function onCastSpell(creature, var)
 
    local creatureSummons = creature:getSummons(summonName)
    local creaturePosition = creature:getPosition()
    local summonscountFuriousTroll = 0
    local summonscountFrostTroll = 0
 
    for _,creature in pairs(creatureSummons) do
        if creature:getName() == "Wolf" then
            summonscountFrostTroll = 1
        end
        if creature:getName() == "Wolf" then
            summonscountFuriousTroll = 1
        end
    end
    
    if summonscountFrostTroll == 0 then
        local summon = Game.createMonster(summonName, creaturePosition)
        if summon == nil then
            creature:sendCancelMessage("Could not summon the creature.")
            return false
        end
        summon:setMaster(creature)
        summon:setDropLoot(false)
        summon:registerEvent('SummonThink')
    else
        creature:sendCancelMessage("Frost Troll is already summoned.")-- error msg
    end
 
    if summonscountFuriousTroll == 0 then
        local summonx = Game.createMonster(summonNamex, creaturePosition)
        if summonx == nil then
            creature:sendCancelMessage("Could not summon the creature.")
            return false
        end
        summonx:setMaster(creature)
        summonx:setDropLoot(false)
        summonx:registerEvent('SummonThink')
    else
        creature:sendCancelMessage("Furious Troll is already summoned.")-- error msg
    end
 
    return true
end
