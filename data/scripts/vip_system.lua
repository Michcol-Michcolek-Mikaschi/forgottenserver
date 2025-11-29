-- VIP Status System
-- Storage keys
STORAGE_VIP_DAYS = 89600  -- Days remaining of VIP status

-- VIP Configuration
VIP_NAME_COLOR = 154  -- Purple/Violet color (154 is a nice purple)

-- Check if player has VIP status
function Player:isVip()
    local vipDays = self:getStorageValue(STORAGE_VIP_DAYS)
    return vipDays and vipDays > 0
end

-- Get remaining VIP days
function Player:getVipDays()
    local vipDays = self:getStorageValue(STORAGE_VIP_DAYS)
    if vipDays < 0 then
        return 0
    end
    return math.floor(vipDays)  -- Ensure integer
end

-- Add VIP days to player
function Player:addVipDays(days)
    local currentDays = self:getVipDays()
    local newDays = math.floor(currentDays + days)  -- Ensure integer
    self:setStorageValue(STORAGE_VIP_DAYS, newDays)
    
    -- Send message to player
    self:sendTextMessage(MESSAGE_INFO_DESCR, "You have received " .. math.floor(days) .. " days of VIP Status! Total: " .. newDays .. " days remaining.")
    
    -- Broadcast VIP status to all players for name color
    if broadcastVipStatus then
        broadcastVipStatus()
    end
    
    return true
end

-- Remove VIP day (called daily)
function Player:decreaseVipDays()
    local currentDays = self:getVipDays()
    if currentDays > 0 then
        local newDays = currentDays - 1
        self:setStorageValue(STORAGE_VIP_DAYS, newDays)
        
        if newDays <= 0 then
            self:sendTextMessage(MESSAGE_INFO_DESCR, "Your VIP Status has expired!")
            -- Broadcast to update name colors
            if broadcastVipStatus then
                broadcastVipStatus()
            end
        elseif newDays <= 3 then
            self:sendTextMessage(MESSAGE_INFO_DESCR, "Warning: Your VIP Status will expire in " .. newDays .. " days!")
        end
    end
end

-- VIP Login Event - Apply VIP effects on login
local VipLoginEvent = CreatureEvent("VipLogin")

function VipLoginEvent.onLogin(player)
    -- Check VIP status and notify
    local vipDays = player:getVipDays()
    if vipDays > 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Welcome back! You have " .. vipDays .. " days of VIP Status remaining.")
    end
    
    return true
end

VipLoginEvent:register()

-- Global event to decrease VIP days at midnight (server save)
local VipDailyDecrease = GlobalEvent("VipDailyDecrease")

function VipDailyDecrease.onTime(interval)
    -- Decrease VIP days for all online players
    for _, player in ipairs(Game.getPlayers()) do
        if player:getVipDays() > 0 then
            player:decreaseVipDays()
        end
    end
    
    -- Also update database for offline players
    db.asyncQuery("UPDATE `player_storage` SET `value` = `value` - 1 WHERE `key` = " .. STORAGE_VIP_DAYS .. " AND `value` > 0")
    
    return true
end

-- Run at midnight (00:00)
VipDailyDecrease:time("00:00")
VipDailyDecrease:register()

-- Talk action to check VIP status
local VipCheckTalkAction = TalkAction("!vip", "!vipstatus")

function VipCheckTalkAction.onSay(player, words, param)
    local vipDays = player:getVipDays()
    
    if vipDays > 0 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You have " .. vipDays .. " days of VIP Status remaining.")
    else
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You don't have VIP Status. Visit the shop to purchase it!")
    end
    
    return false
end

VipCheckTalkAction:separator(" ")
VipCheckTalkAction:register()

print("[VIP System] VIP Status system loaded successfully!")
