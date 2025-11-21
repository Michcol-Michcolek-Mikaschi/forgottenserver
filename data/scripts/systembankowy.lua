local banking = TalkAction("!balance","!deposit","!withdraw","!transfer")
function banking.onSay(player, words, param)
    if (words == "!balance") then
        player:popupFYI("[Balance]: "..player:getBankBalance())
        return false
        
    elseif (words == "!deposit") or (words == "!withdraw") then
        if param == "" then
            player:sendCancelMessage("Usage: !deposit all / !deposit amount")
            return false
        end
    
        local amount = nil
        if param == "all" then
            if (words == "!withdraw") then
                player:sendCancelMessage("You must type an amount to withdraw. You cannot without all.")
                return false
            end
            amount = player:getMoney()
        elseif tonumber(param) ~= nil then
            amount = math.abs(tonumber(param) or 0)
        end
    
        if amount <= 0 or amount > 100000000 then
            player:sendCancelMessage("You can only withdraw or deposit 1-100kk gold.")
            return false
        end
        
        if (words == "!deposit") then
            if player:removeMoney(amount) then
                local oldBalance = player:getBankBalance()
                local newBalance = oldBalance + amount
                player:setBankBalance(newBalance)
                player:popupFYI("[Old Balance]: "..oldBalance.."\n[New Balance]: "..newBalance.."\n\n[Deposit]: "..amount)
                player:sendExtendedOpcode(200, tostring(newBalance))
            else
                player:sendCancelMessage("You do not have that much gold.")
            end
        elseif (words == "!withdraw") then
            if player:getBankBalance() < amount then
                player:sendCancelMessage("You do not have that much gold in your bank.")
            return false
            end
            
            local oldBalance = player:getBankBalance()
            local newBalance = oldBalance - amount
            player:setBankBalance(newBalance)
            player:addMoney(amount)
            player:popupFYI("[Old Balance]: "..oldBalance.."\n[New Balance]: "..newBalance.."\n\n[Withdraw]: "..amount)
            player:sendExtendedOpcode(200, tostring(newBalance))
        end
        
    elseif (words == "!transfer") then
        local t = param:split(",")
        local target = t[1]
        local amount = t[2]
            
        if not target or not amount then
            player:sendCancelMessage("Usage: !transfer player, amount")
        return false
        end
        
        if tonumber(amount) == nil then
            player:sendCancelMessage("Usage: !transfer player, amount")
            return false
        end
        
        if target:lower() == player:getName():lower() then
            player:sendCancelMessage("Why even try.")
            return false
        end
        
        amount = math.abs(tonumber(amount) or 0)
        
        if amount <= 0 or amount > 100000000 then
            player:sendCancelMessage("You can only transfer 1-100kk gold.")
            return false
        end
        
        if player:getBankBalance() < amount then
            player:sendCancelMessage("You do not have that much gold in your bank.")
            return false
        end
        
        local oldBalance = player:getBankBalance()
        player:transferMoneyTo(target, amount)
        local newBalance = player:getBankBalance()
        player:popupFYI("[Old Balance]: "..oldBalance.."\n[New Balance]: "..newBalance.."\n\n[Transfer]: "..amount)
        player:sendExtendedOpcode(200, tostring(newBalance))
    end    
    return false
end

banking:separator(" ")
banking:register()