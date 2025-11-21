function onUse(player, item, fromPosition, target, toPosition)
    -- Stwórz nowy plecak
    local backpack = Game.createItem(12716)

    if not backpack then
        print("Failed to create backpack. Check if item id is correct.")
        return true
    end

    -- Losuj ilość slotów, które będą wypełnione złotem (od 1 do 8)
    local randomSlots = math.random(1, 8)

    -- Wypełnij wylosowaną ilość slotów w plecaku złotem (100 złota na slot)
    for i = 1, randomSlots do
        backpack:addItem(12724, 100) -- Dodaj 100 złota do plecaka
    end

    -- Dodaj wypełniony plecak do ekwipunku gracza
    local result = player:addItemEx(backpack)
    if not result == RETURNVALUE_NOERROR then
        print("Failed to add backpack to the player's inventory.")
        backpack:remove()
        return true
    end

    -- Usuń użyty item
    item:remove(1)

    return true
end