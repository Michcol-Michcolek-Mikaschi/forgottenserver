local config = {
    itemId = 12700, -- Id przedmiotu, który zostanie użyty
    backpackId = 12715, -- Id plecaka, który zostanie stworzony
    minSenzuId = 12694, -- Minimalne Id senzu
    maxSenzuId = 12699, -- Maksymalne Id senzu
    senzuPerSlot = 100, -- Ilość senzu do dodania na slot
    backpackSize = 90 -- Rozmiar plecaka
}

function onUse(player, item, fromPosition, itemEx, toPosition)
    if item.itemid ~= config.itemId then
        return false
    end

    local backpack = player:addItem(config.backpackId, 1)
    if not backpack then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'Cannot create backpack, please check your weight.')
        return true
    end

    -- Losuj ID senzu
    local randomSenzuId = math.random(config.minSenzuId, config.maxSenzuId)

    -- Dodaj senzu do każdego slotu w plecaku
    for i = 1, config.backpackSize do
        backpack:addItem(randomSenzuId, config.senzuPerSlot)
    end

    -- Wyślij wiadomość
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a backpack full of " .. ItemType(randomSenzuId):getName() .. "!")

    -- Usuń przedmiot
    item:remove(1)

    return true
end
