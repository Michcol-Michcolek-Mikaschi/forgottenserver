local autoloot = {
    talkaction = "!autoloot",
    storageBase = 50000,
    storageModeKey = 49999,
    storageBlacklistBase = 49000,
    storageBlacklistEnabledKey = 48999,
    freeAccountLimit = 10,
    premiumAccountLimit = 20,
    blacklistLimit = 30,
    currencyToBank = true,
    modes = {
        [1] = {name = "All except food", collectFood = false, collectNonFood = true},
        [2] = {name = "All items + food", collectFood = true, collectNonFood = true},
        [3] = {name = "Only food", collectFood = true, collectNonFood = false},
        [4] = {name = "Disabled", collectFood = false, collectNonFood = false}
    }
}

local currencyItems = {}
if autoloot.currencyToBank then
    for index, item in pairs(Game.getCurrencyItems()) do
        currencyItems[item:getId()] = true
    end
end

local autolootCache = {}
local blacklistCache = {}
local textEditRequests = {}

local function getPlayerLimit(player)
    return player:isPremium() and autoloot.premiumAccountLimit or autoloot.freeAccountLimit
end

local function getPlayerAutolootItems(player)
    local limits = getPlayerLimit(player)
    local guid = player:getGuid()
    local itemsCache = autolootCache[guid]
    if itemsCache then
        if #itemsCache > limits then
            local newChache = {unpack(itemsCache, 1, limits)}
            autolootCache[guid] = newChache
            return newChache
        end
        return itemsCache
    end

    local items = {}
    for i = 1, limits do
        local itemType = ItemType(math.max(player.storage[autoloot.storageBase + i], 0))
        if itemType and itemType:getId() ~= 0 then
            items[#items +1] = itemType:getId()
        end
    end

    autolootCache[guid] = items
    return items
end

local function setPlayerAutolootItems(player, newItems)
    -- Clear all storage first
    for i = 1, getPlayerLimit(player) do
        player:setStorageValue(autoloot.storageBase + i, -1)
    end
    
    -- Set new items
    for i = 1, #newItems do
        local itemId = newItems[i]
        if itemId and itemId > 0 then
            player:setStorageValue(autoloot.storageBase + i, itemId)
        end
    end
    
    return true
end

local function addPlayerAutolootItem(player, itemId)
    local items = getPlayerAutolootItems(player)
    for _, id in pairs(items) do
        if itemId == id then
            return false
        end
    end
    items[#items +1] = itemId
    return setPlayerAutolootItems(player, items)
end

local function removePlayerAutolootItem(player, itemId)
    local items = getPlayerAutolootItems(player)
    for i, id in pairs(items) do
        if itemId == id then
            table.remove(items, i)
            return setPlayerAutolootItems(player, items)
        end
    end
    return false
end

local function hasPlayerAutolootItem(player, itemId)
    for _, id in pairs(getPlayerAutolootItems(player)) do
        if itemId == id then
            return true
        end
    end
    return false
end

local function getPlayerAutolootMode(player)
    local mode = player:getStorageValue(autoloot.storageModeKey)
    if mode < 1 or mode > 4 then
        return 1 -- Default mode: all except food
    end
    return mode
end

local function setPlayerAutolootMode(player, mode)
    if mode >= 1 and mode <= 4 then
        player:setStorageValue(autoloot.storageModeKey, mode)
        return true
    end
    return false
end

local function getPlayerBlacklist(player)
    local guid = player:getGuid()
    local cache = blacklistCache[guid]
    if cache then
        return cache
    end

    local items = {}
    for i = 1, autoloot.blacklistLimit do
        local itemId = player:getStorageValue(autoloot.storageBlacklistBase + i)
        if itemId > 0 then
            items[#items + 1] = itemId
        end
    end

    blacklistCache[guid] = items
    return items
end

local function setPlayerBlacklist(player, newItems)
    local items = getPlayerBlacklist(player)
    for i = autoloot.blacklistLimit, 1, -1 do
        local itemId = newItems[i]
        if itemId then
            player:setStorageValue(autoloot.storageBlacklistBase + i, itemId)
            items[i] = itemId
        else
            player:setStorageValue(autoloot.storageBlacklistBase + i, -1)
            if items[i] then
                table.remove(items, i)
            end
        end
    end
    return true
end

local function isBlacklistEnabled(player)
    return player:getStorageValue(autoloot.storageBlacklistEnabledKey) == 1
end

local function setBlacklistEnabled(player, enabled)
    player:setStorageValue(autoloot.storageBlacklistEnabledKey, enabled and 1 or 0)
end

local function isItemInBlacklist(player, itemId)
    if not isBlacklistEnabled(player) then
        return false
    end
    
    for _, id in pairs(getPlayerBlacklist(player)) do
        if itemId == id then
            return true
        end
    end
    return false
end

local function isFood(itemType)
    -- Check if item is food (regenerates health/mana)
    local group = itemType:getGroup()
    if group == ITEM_GROUP_FOOD then
        return true
    end
    
    -- Additional check: items with nutrition/regeneration
    local name = itemType:getName():lower()
    local foodKeywords = {"meat", "ham", "bread", "cheese", "fish", "salmon", "northern pike", "shrimp", "roll",
                          "cookie", "muffin", "carrot", "red apple", "orange", "banana", "blueberry", "coconut",
                          "pear", "egg", "dragon ham", "brown mushroom", "grapes", "cherry", "strawberry"}
    
    for _, keyword in ipairs(foodKeywords) do
        if name:find(keyword) then
            return true
        end
    end
    
    return false
end

local ec = EventCallback

function ec.onDropLoot(monster, corpse)
    if not corpse:getType():isContainer() then
        return
    end

    local corpseOwner = Player(corpse:getCorpseOwner())
    if not corpseOwner then
        return
    end

    local mode = getPlayerAutolootMode(corpseOwner)
    local modeConfig = autoloot.modes[mode]
    
    -- Mode 4 = disabled
    if mode == 4 then
        return
    end

    local items = corpse:getItems()
    local warningCapacity = false
    for _, item in pairs(items) do
        local itemId = item:getId()
        local itemType = item:getType()
        
        -- Currency always goes to bank (even in mode 4)
        if currencyItems[itemId] then
            local worth = item:getWorth()
            local newBalance = corpseOwner:getBankBalance() + worth
            corpseOwner:setBankBalance(newBalance)
            corpseOwner:sendTextMessage(MESSAGE_STATUS_SMALL, string.format("Your balance increases by %d gold coins.", worth))
            -- Send updated balance to client
            corpseOwner:sendExtendedOpcode(200, tostring(newBalance))
            item:remove()
        -- Skip blacklisted items and check mode
        elseif mode ~= 4 and not isItemInBlacklist(corpseOwner, itemId) then
            local itemIsFood = isFood(itemType)
            local shouldCollect = false
            
            -- Mode 1: ONLY non-food (skip if food)
            -- Mode 2: everything (food + non-food)
            -- Mode 3: ONLY food (skip if non-food)
            if mode == 1 then
                -- Mode 1: collect only if NOT food
                if not itemIsFood then
                    shouldCollect = true
                end
            elseif mode == 2 then
                -- Mode 2: collect everything
                shouldCollect = true
            elseif mode == 3 then
                -- Mode 3: collect only if IS food
                if itemIsFood then
                    shouldCollect = true
                end
            end
            
            if shouldCollect then
                if not item:moveTo(corpseOwner, 0) then
                    warningCapacity = true
                end
            end
        end
    end

    if warningCapacity then
        corpseOwner:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You no have capacity.")
    end
end

ec:register(3)

local talkAction = TalkAction(autoloot.talkaction)

function talkAction.onSay(player, words, param, type)
    local split = param:splitTrimmed(",")
    local action = split[1]
    if not action then
        local currentMode = getPlayerAutolootMode(player)
        local modeInfo = autoloot.modes[currentMode]
        player:showTextDialog(1948, string.format("Examples of use:\n%s add,gold coin\n%s remove,gold coin\n%s clear\n%s show\n%s edit\n%s mode,<1-4>\n%s blacklist\n\n~Available slots~\nfreeAccount: %d\npremiumAccount: %d\ncurrency to bank: %s\n\n~Current Mode: %d - %s~\n1 = All except food\n2 = All items + food\n3 = Only food\n4 = Disabled", words, words, words, words, words, words, words, autoloot.freeAccountLimit, autoloot.premiumAccountLimit, autoloot.currencyToBank and "yes" or "no", currentMode, modeInfo.name), false)
        return false
    end

    if action == "clear" then
        setPlayerAutolootItems(player, {})
        player:sendCancelMessage("Autoloot list cleaned.")
        return false
    elseif action == "show" then
        local items = getPlayerAutolootItems(player)
        local description = {string.format('~ Your autoloot list, capacity: %d/%d ~\n', #items, getPlayerLimit(player))}
        for i, itemId in pairs(items) do
            description[#description +1] = string.format("%d) %s", i, ItemType(itemId):getName())
        end
        player:showTextDialog(1948, table.concat(description, '\n'), false)
        return false
    elseif action == "edit" then
        local items = getPlayerAutolootItems(player)
        if #items == 0 then
            -- Example
            items = {2160,2672,2432}
        end
        local description = {}
        for i, itemId in pairs(items) do
            description[#description +1] = ItemType(itemId):getName()
        end
        player:registerEvent("autolootTextEdit")
        player:showTextDialog(1948, string.format("To add articles you just have to write their IDs or names on each line\nfor example:\n\n%s", table.concat(description, '\n')), true, 666)
        textEditRequests[player:getGuid()] = true
        return false
    elseif action == "mode" then
        local modeNum = tonumber(split[2])
        if not modeNum or modeNum < 1 or modeNum > 4 then
            player:sendCancelMessage("Invalid mode! Use: !autoloot mode,<1-4>")
            return false
        end
        
        setPlayerAutolootMode(player, modeNum)
        local modeInfo = autoloot.modes[modeNum]
        player:sendCancelMessage(string.format("Autoloot mode changed to: %d - %s", modeNum, modeInfo.name))
        return false
    elseif action == "blacklist" then
        local blacklist = getPlayerBlacklist(player)
        if #blacklist == 0 then
            -- Example
            blacklist = {2148, 2152}
        end
        local description = {}
        for i, itemId in pairs(blacklist) do
            description[#description +1] = ItemType(itemId):getName()
        end
        player:registerEvent("autolootBlacklistEdit")
        player:showTextDialog(1948, string.format("~Autoloot Blacklist (max %d items)~\nWrite IDs or names of items to EXCLUDE from autoloot\nOne item per line\n\nExample:\n%s", autoloot.blacklistLimit, table.concat(description, '\n')), true, 667)
        return false
    elseif action == "blacklist_toggle" then
        local enabled = split[2] == "1" or split[2] == "true"
        setBlacklistEnabled(player, enabled)
        player:sendCancelMessage(string.format("Blacklist %s", enabled and "enabled" or "disabled"))
        return false
    elseif action == "blacklist_add" then
        local itemName = split[2]
        if not itemName then
            player:sendCancelMessage("Usage: !autoloot blacklist_add,item name or id")
            return false
        end
        
        -- Get item type
        local itemType = ItemType(itemName)
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(tonumber(itemName) or 0)
            if not itemType or itemType:getId() == 0 then
                player:sendCancelMessage(string.format("Item '%s' not found!", itemName))
                return false
            end
        end
        
        local blacklist = getPlayerBlacklist(player)
        if #blacklist >= autoloot.blacklistLimit then
            player:sendCancelMessage(string.format("Blacklist is full! (max %d items)", autoloot.blacklistLimit))
            return false
        end
        
        -- Check if already in blacklist
        for _, id in pairs(blacklist) do
            if id == itemType:getId() then
                player:sendCancelMessage(string.format("'%s' is already in blacklist!", itemType:getName()))
                return false
            end
        end
        
        -- Add to blacklist
        table.insert(blacklist, itemType:getId())
        setPlayerBlacklist(player, blacklist)
        player:sendCancelMessage(string.format("Added '%s' to blacklist", itemType:getName()))
        return false
    elseif action == "blacklist_remove" then
        local itemName = split[2]
        if not itemName then
            player:sendCancelMessage("Usage: !autoloot blacklist_remove,item name or id")
            return false
        end
        
        -- Get item type
        local itemType = ItemType(itemName)
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(tonumber(itemName) or 0)
            if not itemType or itemType:getId() == 0 then
                player:sendCancelMessage(string.format("Item '%s' not found!", itemName))
                return false
            end
        end
        
        local blacklist = getPlayerBlacklist(player)
        local removed = false
        for i, id in pairs(blacklist) do
            if id == itemType:getId() then
                table.remove(blacklist, i)
                removed = true
                break
            end
        end
        
        if removed then
            setPlayerBlacklist(player, blacklist)
            player:sendCancelMessage(string.format("Removed '%s' from blacklist", itemType:getName()))
        else
            player:sendCancelMessage(string.format("'%s' not found in blacklist", itemType:getName()))
        end
        return false
    elseif action == "blacklist_clear" then
        setPlayerBlacklist(player, {})
        player:sendCancelMessage("Blacklist cleared!")
        return false
    elseif action == "status" then
        local mode = getPlayerAutolootMode(player)
        local modeInfo = autoloot.modes[mode]
        local blacklistStatus = isBlacklistEnabled(player) and "enabled" or "disabled"
        local blacklistCount = #getPlayerBlacklist(player)
        player:sendCancelMessage(string.format("Mode: %d - %s | Blacklist: %s (%d items)", mode, modeInfo.name, blacklistStatus, blacklistCount))
        return false
    end

    local function getItemType()
        local itemType = ItemType(split[2])
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(math.max(tonumber(split[2]) or 0), 0)
            if not itemType or itemType:getId() == 0 then
                player:sendCancelMessage(string.format("The item %s does not exists!", split[2]))
                return false
            end
        end
        return itemType
    end

    if action == "add" then
        local itemType = getItemType()
        if itemType then
            local limits = getPlayerLimit(player)
            if #getPlayerAutolootItems(player) >= limits then
                player:sendCancelMessage(string.format("Your auto loot only allows you to add %d items.", limits))
                return false
            end

            if addPlayerAutolootItem(player, itemType:getId()) then
                player:sendCancelMessage(string.format("Perfect you have added to the list: %s", itemType:getName()))
            else
                player:sendCancelMessage(string.format("The item %s already exists!", itemType:getName()))
            end
        end
        return false
    elseif action == "remove" then
        local itemType = getItemType()
        if itemType then
            if removePlayerAutolootItem(player, itemType:getId()) then
                player:sendCancelMessage(string.format("Perfect you have removed to the list the article: %s", itemType:getName()))
            else
                player:sendCancelMessage(string.format("The item %s does not exists in the list.", itemType:getName()))
            end
        end
        return false
    end

    return false
end

talkAction:separator(" ")
talkAction:register()

local creatureEvent = CreatureEvent("autolootCleanCache")

function creatureEvent.onLogout(player)
    local guid = player:getGuid()
    setPlayerAutolootItems(player, getPlayerAutolootItems(player))
    autolootCache[guid] = nil
    blacklistCache[guid] = nil
    return true
end

creatureEvent:register()

creatureEvent = CreatureEvent("autolootTextEdit")

function creatureEvent.onTextEdit(player, item, text)
    player:unregisterEvent("autolootTextEdit")

    local split = text:splitTrimmed("\n")
    local items = {}
    for index, name in pairs(split) do repeat
        local itemType = ItemType(name)
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(tonumber(name))
            if not itemType or itemType:getId() == 0 then
                break
            end

            break
        end

        items[#items +1] = itemType:getId()
    until true end
    setPlayerAutolootItems(player, items)
    player:sendCancelMessage(string.format("Perfect, you have modified the list of articles manually."))
    return true
end

creatureEvent:register()

creatureEvent = CreatureEvent("autolootBlacklistEdit")

function creatureEvent.onTextEdit(player, item, text)
    player:unregisterEvent("autolootBlacklistEdit")

    local split = text:splitTrimmed("\n")
    local items = {}
    for index, name in pairs(split) do
        if #items >= autoloot.blacklistLimit then
            break
        end
        
        repeat
            local itemType = ItemType(name)
            if not itemType or itemType:getId() == 0 then
                itemType = ItemType(tonumber(name))
                if not itemType or itemType:getId() == 0 then
                    break
                end
            end

            items[#items + 1] = itemType:getId()
        until true
    end
    
    setPlayerBlacklist(player, items)
    player:sendCancelMessage(string.format("Blacklist updated! %d items excluded from autoloot.", #items))
    return true
end

creatureEvent:register()