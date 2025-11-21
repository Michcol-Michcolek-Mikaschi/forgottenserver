local healSpell = 10 -- ID zaklęcia "heal"
local healPercentage = 25 -- Procent maksymalnego zdrowia mistrza, który zostanie przywrócony
local healCooldown = 5 -- Czas w sekundach między kolejnymi użyciami leczenia przez peta

local lastHealTimes = {} -- Tablica przechowująca czasy ostatniego leczenia dla poszczególnych potworów

function onThink(creature)
    if creature:isMonster() and creature:getName() == "[Pet] Dende" then
        local master = creature:getMaster()
        if master then
            local masterMaxHealth = master:getMaxHealth()
            local masterHealth = master:getHealth()
            
            local lastHealTime = lastHealTimes[creature:getId()] or 0
            local currentTime = os.time()
            
            if currentTime - lastHealTime >= healCooldown and masterHealth < masterMaxHealth then
                local healAmount = math.floor(masterMaxHealth * healPercentage / 100)
                creature:say("Dende used heal friends on " .. master:getName() .. "!", TALKTYPE_MONSTER_SAY)
                master:addHealth(healAmount)
                creature:say(healSpell)
                
                lastHealTimes[creature:getId()] = currentTime
            end
        end
    end
    return true
end