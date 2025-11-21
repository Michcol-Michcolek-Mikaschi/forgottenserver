local conf = {
   ["level"] = {
   -- [item_level] = {successPercent= CHANCE TO UPGRADE ITEM, downgradeLevel = ITEM GETS THIS LEVEL IF UPGRADE FAILS}
     [0] = {successPercent = 90, downgradeLevel = 0, destroyChance = 10},
     [1] = {successPercent = 85, downgradeLevel = 0, destroyChance = 10},
     [2] = {successPercent = 80, downgradeLevel = 1, destroyChance = 10},
     [3] = {successPercent = 85, downgradeLevel = 2, destroyChance = 10},
     [4] = {successPercent = 80, downgradeLevel = 3, destroyChance = 10},
     [5] = {successPercent = 75, downgradeLevel = 4, destroyChance = 10},
     [6] = {successPercent = 70, downgradeLevel = 5, destroyChance = 10},
     [7] = {successPercent = 65, downgradeLevel = 0, destroyChance = 10},
     [8] = {successPercent = 60, downgradeLevel = 0, destroyChance = 10},
     [9] = {successPercent = 55, downgradeLevel = 0, destroyChance = 10},
     [10] = {successPercent = 45, downgradeLevel = 0, destroyChance = 10}
   },

   ["upgrade"] = { -- how many percent attributes are rised?
     attack = 5, -- attack %
     defense = 5, -- defense %
     extraDefense = 10, -- extra defense %
     armor = 5, -- armor %
     hitChance = 5, -- hit chance %
   }
}

-- // do not touch // --
-- Upgrading system by Azi [Ersiu] --
-- Edited for TFS 1.x by GitHub Copilot --

local upgrading = {
  upValue = function (value, level, percent)
    if value < 0 then return 0 end
    if level == 0 then return value end
    local nVal = value
    for i = 1, level do
      nVal = nVal + (math.ceil((nVal/100*percent)))
    end
    return nVal > 0 and nVal or value
  end,

  getLevel = function (item)
    local name = item:getName():split('+')
    if (#name == 1) then
      return 0
    end
    return math.abs(tonumber(name[2]) or 0)
  end,
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
   if not target or not target:isItem() then
      player:sendTextMessage(MESSAGE_INFO_DESCR, "You must use this on an item.")
      return true
   end

   local itemType = target:getType()
   
   -- Sprawdź czy to broń lub zbroja i nie jest stackable
   if (itemType:getWeaponType() > 0 or itemType:getArmor() > 0) and not itemType:isStackable() then
      local level = upgrading.getLevel(target)
      
      if level == 0 or level == nil then
         level = 0
         target:setAttribute(ITEM_ATTRIBUTE_NAME, itemType:getName() .. "+" .. level)
      end

      if level < #conf["level"] then
         local nLevel = (conf["level"][(level+1)].successPercent >= math.random(1,100)) and (level+1) or conf["level"][level].downgradeLevel
         
         if nLevel > level then
            toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Upgrade to level " .. nLevel .. " /10 successful!")
         else
            toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
            if math.random(1, 100) <= conf["level"][level].destroyChance then
               target:remove(1)
               player:sendTextMessage(MESSAGE_INFO_DESCR, "Upgrade failed. Your " .. itemType:getName() .. " has been destroyed!")
               item:remove(1)
               return true
            else
               player:sendTextMessage(MESSAGE_INFO_DESCR, "Upgrade failed. Your " .. itemType:getName() .. " is now on level " .. nLevel .. " /10")
            end
         end
         
         -- Ustaw atrybuty
         target:setAttribute(ITEM_ATTRIBUTE_NAME, itemType:getName() .. ((nLevel > 0) and "+" .. nLevel or ""))
         target:setAttribute(ITEM_ATTRIBUTE_ATTACK, upgrading.upValue(itemType:getAttack(), nLevel, conf["upgrade"].attack))
         target:setAttribute(ITEM_ATTRIBUTE_DEFENSE, upgrading.upValue(itemType:getDefense(), nLevel, conf["upgrade"].defense))
         target:setAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE, upgrading.upValue(itemType:getExtraDefense(), nLevel, conf["upgrade"].extraDefense))
         target:setAttribute(ITEM_ATTRIBUTE_ARMOR, upgrading.upValue(itemType:getArmor(), nLevel, conf["upgrade"].armor))
         target:setAttribute(ITEM_ATTRIBUTE_HITCHANCE, upgrading.upValue(itemType:getHitChance(), nLevel, conf["upgrade"].hitChance))
         item:remove(1)
      else
         player:sendTextMessage(MESSAGE_INFO_DESCR, "Your " .. itemType:getName() .. " is on max level 10 already.")
      end
   else
      player:sendTextMessage(MESSAGE_INFO_DESCR, "You cannot upgrade this item.")
   end
   
   return true
end