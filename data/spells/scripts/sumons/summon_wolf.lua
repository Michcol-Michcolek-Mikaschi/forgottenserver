local summonName = "Wolf"
local manaCost = 315

function onCastSpell(creature, var)

    local creaturePosition = creature:getPosition()
    local MAX_WOLFS_ALLOWED = 5
    local wolfs = 0

    -- CHECK IF PLAYER HAS MANA
    if creature:getMana() < manaCost and not creature:hasFlag(PlayerFlag_HasInfiniteMana) then
        creature:sendCancelMessage(RETURNVALUE_NOTENOUGHMANA)
        creature:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- COUNTS HOW MANY SUMMONED WOLFS YOU HAVE SUMMONED
    local creatureSummons = creature:getSummons()
    for _, summon in pairs(creatureSummons) do
        if summon:getName() == summonName then
            wolfs = wolfs + 1
        end
    end

    -- IF YOU HAVENT SUMMONED TOO MANY WOLFS THEN SUMMON ELSE DONT SUMMON
    if wolfs < MAX_WOLFS_ALLOWED then
        local summon = Game.createMonster(summonName, creaturePosition)
        if summon == nil then
            creature:sendCancelMessage("Could not summon the creature.")
            return false
        end
        creature:addMana(-manaCost)
        creature:addManaSpent(manaCost)
        summon:setMaster(creature)
        summon:setDropLoot(false)
        summon:say("Grrrr!", TALKTYPE_MONSTER_SAY)
        summon:registerEvent('SummonThink')
        creature:getPosition():sendMagicEffect(48)
    
    else
        creature:sendCancelMessage("You are already at max summons.") -- error msg
    end
 
    return true
end







