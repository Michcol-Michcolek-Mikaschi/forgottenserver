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
    return vipDays
end

-- Add VIP days to player
function Player:addVipDays(days)
    local currentDays = self:getVipDays()
    self:setStorageValue(STORAGE_VIP_DAYS, currentDays + days)
    
    -- Send message to player
    self:sendTextMessage(MESSAGE_INFO_DESCR, "You have received " .. days .. " days of VIP Status! Total: " .. (currentDays + days) .. " days remaining.")
    
    -- Broadcast VIP status to all players
    if broadcastVipStatus then
        broadcastVipStatus()
    end
    
    return true
end

-- Remove VIP day (called daily)
function Player:decreaseVipDays()
    local currentDays = self:getVipDays()
    if currentDays > 0 then
        self:setStorageValue(STORAGE_VIP_DAYS, currentDays - 1)
        
        if currentDays - 1 <= 0 then
            self:sendTextMessage(MESSAGE_INFO_DESCR, "Your VIP Status has expired!")
        elseif currentDays - 1 <= 3 then
            self:sendTextMessage(MESSAGE_INFO_DESCR, "Warning: Your VIP Status will expire in " .. (currentDays - 1) .. " days!")
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

-- Extended Opcode for VIP system
local VIP_OPCODE = 202

-- Send VIP status to all players when someone logs in or VIP status changes
function broadcastVipStatus()
    local vipPlayers = {}
    for _, player in ipairs(Game.getPlayers()) do
        if player:isVip() then
            table.insert(vipPlayers, player:getName())
        end
    end
    
    local data = json.encode({
        action = "vipList",
        data = { players = vipPlayers }
    })
    
    for _, player in ipairs(Game.getPlayers()) do
        player:sendExtendedOpcode(VIP_OPCODE, data)
    end
end

-- Send VIP status to a specific player
function sendVipStatusToPlayer(player)
    local vipPlayers = {}
    for _, p in ipairs(Game.getPlayers()) do
        if p:isVip() then
            table.insert(vipPlayers, p:getName())
        end
    end
    
    player:sendExtendedOpcode(VIP_OPCODE, json.encode({
        action = "vipList",
        data = { players = vipPlayers }
    }))
end

-- Update the login event to broadcast VIP status
local VipLoginBroadcast = CreatureEvent("VipLoginBroadcast")

function VipLoginBroadcast.onLogin(player)
    -- Delay to ensure player is fully loaded
    addEvent(function(playerId)
        local p = Player(playerId)
        if p then
            sendVipStatusToPlayer(p)
            -- If this player is VIP, broadcast to everyone
            if p:isVip() then
                broadcastVipStatus()
            end
        end
    end, 1000, player:getId())
    
    return true
end

VipLoginBroadcast:register()

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
