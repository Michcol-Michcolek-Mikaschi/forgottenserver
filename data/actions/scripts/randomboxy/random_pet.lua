-- Random Pet Box - Naruto Edition
-- Gives one random pet summoning item

local petItems = {
    {id = 56974, name = "Pakkun Collar"},
    {id = 56975, name = "Toad Contract (Gamabunta)"},
    {id = 56976, name = "Slug Contract (Katsuyu)"},
    {id = 56977, name = "Snake Contract (Manda)"}
}

function onUse(player, item, fromPosition, itemEx, toPosition, isHotkey)
    local randomPet = petItems[math.random(#petItems)]
    
    player:addItem(randomPet.id, 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "You received: " .. randomPet.name .. "!")
    item:remove(1)

    return true
end