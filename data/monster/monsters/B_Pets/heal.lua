local healSpell = 10 -- ID zaklęcia "heal"
local healPercentage = 25 -- Procent maksymalnego zdrowia mistrza, który zostanie przywrócony

function onThink(creature)
    if creature:isMonster() and creature:getName() == "[Pet] Dende" then
        local master = creature:getMaster()
        if master then
            local masterMaxHealth = master:getMaxHealth()
            local masterHealth = master:getHealth()
            if masterHealth < masterMaxHealth then
                local healAmount = math.floor(masterMaxHealth * healPercentage / 100)
                creature:say("Dende used heal friends on " .. master:getName() .. "!", TALKTYPE_MONSTER_SAY)
                master:addHealth(healAmount)
                creature:saySpell(healSpell)
            end
        end
    end
    return true
end