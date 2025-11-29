-- MyAAC/Gesior Shop Delivery System
-- Przetwarza zakupy z tabeli z_ots_comunication przy logowaniu gracza

function onLogin(player)
    local resultId = db.storeQuery("SELECT * FROM `z_ots_comunication` WHERE `name` = " .. db.escapeString(player:getName()) .. " AND `action` = 'give_item' AND `delete_it` = '1'")
    
    if not resultId then
        return true
    end
    
    repeat
        local id = result.getNumber(resultId, "id")
        local offerType = result.getString(resultId, "param5")
        local param1 = result.getNumber(resultId, "param1")
        local param2 = result.getNumber(resultId, "param2")
        local param3 = result.getNumber(resultId, "param3")
        local param4 = result.getNumber(resultId, "param4")
        local offerName = result.getString(resultId, "param6")
        
        local success = false
        local message = ""
        
        if offerType == "item" then
            -- Przedmiot: param1 = itemId, param2 = count
            local itemType = ItemType(param1)
            if itemType:getId() > 0 then
                local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
                if inbox then
                    local item = inbox:addItem(param1, param2)
                    if item then
                        success = true
                        message = "You received: " .. param2 .. "x " .. itemType:getName()
                    end
                end
            end
            
        elseif offerType == "addon" then
            -- Addon: param1 = female looktype, param2 = male looktype, param3 = female addons, param4 = male addons
            local femaleLook = param1
            local maleLook = param2
            local femaleAddons = param3
            local maleAddons = param4
            
            local sex = player:getSex()
            if sex == PLAYERSEX_FEMALE then
                player:addOutfitAddon(femaleLook, femaleAddons)
            else
                player:addOutfitAddon(maleLook, maleAddons)
            end
            success = true
            message = "You received addon: " .. offerName
            
        elseif offerType == "mount" then
            -- Mount: param1 = mountId
            player:addMount(param1)
            success = true
            message = "You received mount: " .. offerName
            
        elseif offerType == "container" then
            -- Container: param1 = itemId, param2 = item count, param3 = containerId, param4 = container count
            local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
            if inbox then
                for i = 1, param4 do
                    local container = inbox:addItem(param3, 1)
                    if container and container:isContainer() then
                        for j = 1, param2 do
                            container:addItem(param1, 1)
                        end
                    end
                end
                success = true
                message = "You received container with items: " .. offerName
            end
            
        elseif offerType == "vip" then
            -- VIP: param1 = days - use Player:addVipDays from vip_system.lua
            if player.addVipDays then
                player:addVipDays(param1)
                success = true
                message = "You received " .. param1 .. " VIP days! Use !vip to check status."
            else
                -- Fallback if vip_system not loaded
                local STORAGE_VIP_DAYS = 89600
                local currentDays = player:getStorageValue(STORAGE_VIP_DAYS)
                if currentDays < 0 then currentDays = 0 end
                player:setStorageValue(STORAGE_VIP_DAYS, currentDays + param1)
                success = true
                message = "You received " .. param1 .. " VIP days! Total: " .. (currentDays + param1) .. " days."
            end
        end
        
        if success then
            -- Oznacz jako dostarczone
            db.asyncQuery("DELETE FROM `z_ots_comunication` WHERE `id` = " .. id)
            -- Aktualizuj historię
            db.asyncQuery("UPDATE `z_shop_history` SET `trans_state` = 'realized', `trans_real` = " .. os.time() .. " WHERE `comunication_id` = " .. id)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "[Shop] " .. message)
        else
            if message ~= "" then
                player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Shop] Failed to deliver: " .. offerName .. ". " .. message)
            end
        end
        
    until not result.next(resultId)
    
    result.free(resultId)
    return true
end
