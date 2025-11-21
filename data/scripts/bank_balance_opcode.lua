local bankBalanceOpcode = CreatureEvent("BankBalanceOpcode")

function bankBalanceOpcode.onExtendedOpcode(player, opcode, buffer)
    if opcode == 200 then
        -- Bank balance request
        if buffer == "request" then
            local balance = player:getBankBalance()
            player:sendExtendedOpcode(200, tostring(balance))
        end
    end
    return true
end

bankBalanceOpcode:register()
