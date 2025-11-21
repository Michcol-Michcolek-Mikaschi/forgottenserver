local itemIds = {12680, 12680, 12680, 12680, 12680, 12680, 12680, 12680, 12680, 12680, -- 10 kopii dla 10%
                 12681, 12682, 12683, 12684, 
                 12681, 12682, 12683, 12684, 
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684, 
                 12681, 12682, 12683, 12684, 
                 12681, 12682, 12683, 12684, 
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                 12681, 12682, 12683, 12684,
                } -- kolejne kopie dla reszty 22.5% każde

function onUse(player, item, fromPosition, target, toPosition)
    -- Losuj indeks z tablicy
    local randomIndex = math.random(1, #itemIds)
    
    -- Pobierz ID przedmiotu z wylosowanego indeksu
    local randomItemId = itemIds[randomIndex]
    
    -- Dodaj przedmiot do ekwipunku gracza
    player:addItem(randomItemId, 1)
    
    -- Usuń przedmiot
    item:remove(1)
    
    return true
end
