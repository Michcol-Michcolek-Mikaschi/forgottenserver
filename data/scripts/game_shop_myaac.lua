-- MyAAC Gesior Shop System Integration
-- Updated to work with MyAAC instead of Znote AAC
local DONATION_URL = "http://localhost/?p=points"
local GAME_SHOP = nil
local SECOND_CURRENCY_ENABLED = false

if not GlobalStorage then
    GlobalStorage = {}
end
GlobalStorage.GameShopRefreshCount = 89412

-- Storage keys for aura effects
local STORAGE_OWNED_AURAS = 89500  -- Bitmask of owned auras
local STORAGE_ACTIVE_AURA = 89501  -- Currently active aura ID (0 = none)
local STORAGE_VIP_DAYS = 89600     -- VIP days remaining (shared with vip_system.lua)

-- Aura effect definitions (effectId, name, price, description)
local AURA_EFFECTS = {
	{effectId = 301, name = "Fire Aura", price = 50, description = "A blazing fire aura surrounds your character.\n\n- permanent visual effect\n- can be toggled on/off anytime\n- once purchased, yours forever"},
	{effectId = 302, name = "Ice Aura", price = 50, description = "A freezing ice aura surrounds your character.\n\n- permanent visual effect\n- can be toggled on/off anytime\n- once purchased, yours forever"},
	{effectId = 303, name = "Lightning Aura", price = 75, description = "Electric sparks crackle around your character.\n\n- permanent visual effect\n- can be toggled on/off anytime\n- once purchased, yours forever"}
}

local pointsCache = {}
local secondPointsCache = {}
local shopInitialized = false

local LoginEvent = CreatureEvent("GameShopLogin")

local ExtendedOPCodes = {
	CODE_GAMESHOP = 201
}

function LoginEvent.onLogin(player)
	player:registerEvent("GameShopExtended")
	
	local accountId = player:getAccountId()
	
	-- Use premium_points from accounts table (MyAAC)
	local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. accountId)
	if resultId ~= false then
		local points = result.getNumber(resultId, "premium_points")
		result.free(resultId)
		
		pointsCache[accountId] = {
			points = points,
			time = os.time()
		}
	end
	
	-- Send aura data on login (delayed to ensure protocol is ready)
	addEvent(function(playerId)
		local p = Player(playerId)
		if p then
			sendPlayerAuraData(p)
		end
	end, 1000, player:getId())
	
	return true
end

-- Category mapping from Gesior Shop to OTClient
local CATEGORY_ITEMS = 1          -- Items
local CATEGORY_VIP_STATUS = 2     -- Vip Status
local CATEGORY_PET = 3             -- Kuchiyose [PET]
local CATEGORY_PREMIUM = 4         -- Premium Account
local CATEGORY_BOOST = 5           -- Boost
local CATEGORY_OTHER = 6           -- Other
local CATEGORY_AURA = 7            -- Aura Effects

-- Icon mapping for categories
local categoryIcons = {
	[1] = 6,   -- Items (CATEGORY_ITEM = 1)
	[2] = 15,  -- Vip Status (Outfit) (CATEGORY_OUTFIT = 3)
	[3] = 6,   -- Pet (Item category to show images) (CATEGORY_ITEM = 1)
	[4] = 20,  -- Premium Account (CATEGORY_PREMIUM = 0)
	[5] = 17,  -- Boost (CATEGORY_EXTRAS = 5)
	[6] = 9,   -- Other (Extras) (CATEGORY_EXTRAS = 5)
	[7] = 17   -- Aura Effects (CATEGORY_EXTRAS = 5)
}

-- Explicit metadata for offers that need fixed server/client sprite ids
local SPECIAL_ITEM_METADATA = {
	["Kuchiyose [PET]"] = {
		serverId = 56973, -- ring that summons the pet
		clientId = 51954 -- sprite id so OTClient/MyAAC can display icon
	}
}

-- PNG overrides for specific offers (value without .png extension)
local NAME_TO_IMAGE = {
	["PACC 30"] = "PACC_30",
	["50 Crystal Coins"] = "crystal_coin",
	["[PET] Random Box"] = "pet"
}

local function resolveClientId(itemId, currentClientId, offerId, offerName)
	if currentClientId and currentClientId > 0 then
		return currentClientId
	end

	if not itemId or itemId <= 0 then
		return currentClientId
	end

	local it = ItemType(itemId)
	if it then
		local clientId = it:getClientId()
		if clientId and clientId > 0 then
			if offerId then
				db.query(string.format("UPDATE `z_shop_offer` SET `itemid2` = %d WHERE `id` = %d", clientId, offerId))
				print(string.format("Shop: Offer '%s' clientId synchronized to %d", offerName, clientId))
			end
			return clientId
		end
	end

	return currentClientId
end

function gameShopInitialize()
	if shopInitialized then
		return
	end
	
	GAME_SHOP = {
		categories = {},
		categoriesId = {},
		offers = {}
	}
	
	-- Load categories from MyAAC Gesior Shop database
	local categoriesQuery = db.storeQuery("SELECT `id`, `name`, `hidden` FROM `z_shop_categories` WHERE `hidden` = 0 ORDER BY `id`")
	if categoriesQuery then
		repeat
			local catId = result.getNumber(categoriesQuery, "id")
			local catName = result.getString(categoriesQuery, "name")
			local iconId = categoryIcons[catId] or 9
			
			addCategory(nil, catName, iconId, catId, "")
		until not result.next(categoriesQuery)
		result.free(categoriesQuery)
	end
	
	-- Add Aura Effects category
	addCategory(nil, "Aura Effects", categoryIcons[CATEGORY_AURA], CATEGORY_AURA, "Permanent visual effects for your character")
	
	-- Add aura offers
	for _, aura in ipairs(AURA_EFFECTS) do
		addItem("Aura Effects", aura.name, aura.effectId, aura.price, false, 1, aura.description, "aura", nil)
	end
	
	-- Load offers from MyAAC Gesior Shop database
	local offersQuery = db.storeQuery("SELECT `id`, `category_id`, `offer_name`, `points`, `itemid1`, `itemid2`, `count1`, `offer_type`, `offer_description`, `hidden` FROM `z_shop_offer` WHERE `hidden` = 0 ORDER BY `ordering`, `id`")
	if offersQuery then
			repeat
			local offerId = result.getNumber(offersQuery, "id")
			local categoryId = result.getNumber(offersQuery, "category_id")
			local offerName = result.getString(offersQuery, "offer_name")
			local points = result.getNumber(offersQuery, "points")
			local itemId = result.getNumber(offersQuery, "itemid1")
			local count = result.getNumber(offersQuery, "count1")
			local clientId = result.getNumber(offersQuery, "itemid2") or 0
			local offerType = result.getString(offersQuery, "offer_type")
			local description = result.getString(offersQuery, "offer_description")

			local metadata = SPECIAL_ITEM_METADATA[offerName]
			if metadata then
				if metadata.serverId and itemId ~= metadata.serverId then
					itemId = metadata.serverId
					db.query(string.format("UPDATE `z_shop_offer` SET `itemid1` = %d WHERE `id` = %d", itemId, offerId))
					print(string.format("Shop: Offer '%s' serverId forced to %d", offerName, itemId))
				end

				if metadata.clientId and clientId ~= metadata.clientId then
					clientId = metadata.clientId
					db.query(string.format("UPDATE `z_shop_offer` SET `itemid2` = %d WHERE `id` = %d", clientId, offerId))
					print(string.format("Shop: Offer '%s' clientId forced to %d", offerName, clientId))
				end
			end

			if offerType == "item" then
				clientId = resolveClientId(itemId, clientId, offerId, offerName)
			end
			
			-- Get category name for parent
				local categoryName = ""
			for _, cat in ipairs(GAME_SHOP.categories) do
				if cat.categoryId == categoryId then
					categoryName = cat.title
					break
				end
			end
			
			if categoryName ~= "" then
				-- Add description based on offer type
				if description == "" or description == nil then
					if offerType == "item" and (offerName:lower():find("pet") or offerName:lower():find("random box")) then
						description = "The item is a box that, when used, randomly draws a pet summoning ring.\n\n- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign"
					elseif offerType == "item" then
						description = "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded"
					elseif offerType == "pacc" then
						description = "Enhance your gaming experience by gaining additional abilities and advantages:\n\n* access to Premium areas\n* use transport system\n* more spells\n* rent houses\n* found guilds\n* larger Depots\n* and many more\n\n- valid for all characters on this account\n- activated at purchase"
					elseif offerType == "mount" then
						description = "- only usable by purchasing character\n- provides character with a speed boost"
					elseif offerType == "addon" then
						description = "- only usable by purchasing character\n- colours can be changed using the Outfit dialog\n- includes addon(s) which can be selected individually"
					else
						description = "Purchase this item from the shop.\n\n- only usable by purchasing character\n- activated at purchase"
					end
				end
				
				-- Use serverId for items - number for item sprites, string for PNG images
				local serverId = itemId
				if not clientId or clientId <= 0 then
					clientId = nil
				end
				if offerType == "pacc" then
					-- Format count as integer to avoid decimal issues (30.0 -> 30)
					serverId = "PACC_" .. math.floor(count)
				elseif offerType == "changename" then
					serverId = "Name_Change"
				elseif offerType == "changesex" then
					serverId = "Sex_Change"
				end
				
				addItem(categoryName, offerName, serverId, points, false, count, description, offerType, clientId)
			end
		until not result.next(offersQuery)
		result.free(offersQuery)
	end
	
	shopInitialized = true
end

function addCategory(parent, title, iconId, categoryId, description)
	GAME_SHOP.categoriesId[title] = categoryId
	table.insert(GAME_SHOP.categories, {
		title = title,
		parent = parent,
		iconId = iconId,
		categoryId = categoryId,
		description = description
	})
end

function addItem(parent, name, serverId, price, isSecondPrice, count, description, offerType, clientId)
	if not GAME_SHOP.offers[parent] then
		GAME_SHOP.offers[parent] = {}
	end

	local displayImage = nil
	local displayId = clientId or serverId

	if not clientId then
		if NAME_TO_IMAGE[name] then
			displayImage = NAME_TO_IMAGE[name]
			print(string.format("Shop: Offer '%s' will use image: %s.png", name, displayImage))
		elseif type(serverId) ~= "number" and type(serverId) ~= "nil" then
			-- Legacy behaviour where ID already contains the image name
			displayImage = tostring(serverId)
		end
	end

	table.insert(GAME_SHOP.offers[parent], {
		parent = parent,
		name = name,
		serverId = serverId,  -- Keep original server ID for purchase
		id = displayId,
		clientId = clientId,
		image = displayImage,
		price = price,
		isSecondPrice = isSecondPrice,
		count = count,
		description = description,
		categoryId = GAME_SHOP.categoriesId[parent],
		offerType = offerType
	})
end

function gameShopPurchase(player, offer)
	local offers = GAME_SHOP.offers[offer.parent]
	if not offers then
		return errorMsg(player, "Something went wrong, try again or contact server admin [#1]!")
	end

	for i = 1, #offers do
		if offers[i].name == offer.name and offers[i].price == offer.price and offers[i].count == offer.count then
			local points = 0
			local accountId = player:getAccountId()
			
			points = getPoints(player)
			
			if offers[i].price > points then
				return errorMsg(player, "You don't have enough points! Visit the website to purchase points.")
			end

			offer.serverId = offers[i].serverId
			offer.offerType = offers[i].offerType
			local status = finalizePurchase(player, offer)
			if status then
				return errorMsg(player, status)
			end

			-- Update premium_points in accounts table
			db.query("UPDATE `accounts` SET `premium_points` = `premium_points` - " .. offers[i].price .. " WHERE `id` = " .. accountId)
			
			if pointsCache[accountId] then
				pointsCache[accountId].points = pointsCache[accountId].points - offers[i].price
				pointsCache[accountId].time = os.time()
			end
			
			-- Insert into z_shop_history (Gesior Shop System structure)
			-- Structure: id, comunication_id, to_name, to_account, from_nick, from_account, price, offer_id, trans_state, trans_start, trans_real, is_pacc
			local historyData = {
				"INSERT INTO `z_shop_history` VALUES (NULL, 0, ",
				db.escapeString(player:getName()),
				", ",
				tostring(accountId), 
				", 'Shop', 0, ",
				tostring(offers[i].price),
				", 0, 'realized', ",
				tostring(os.time()),
				", ",
				tostring(os.time()),
				", ",
				offers[i].offerType == "pacc" and "1" or "0",
				")"
			}
			
			db.asyncQuery(table.concat(historyData))
			
			addEvent(updatePlayerShopData, 1000, player:getId())
			
			return infoMsg(player, "You've bought " .. offers[i].name .. "!", true)
		end
	end
	
	return errorMsg(player, "Something went wrong, try again or contact server admin [#3]!")
end

function finalizePurchase(player, offer)
	local offerType = offer.offerType
	
	if offerType == "pacc" then
		return defaultPremiumCallback(player, offer)
	elseif offerType == "item" then
		return defaultItemCallback(player, offer)
	elseif offerType == "mount" then
		return defaultMountCallback(player, offer)
	elseif offerType == "addon" then
		return defaultOutfitCallback(player, offer)
	elseif offerType == "changename" then
		return defaultChangeNameCallback(player, offer)
	elseif offerType == "changesex" then
		return defaultChangeSexCallback(player)
	elseif offerType == "aura" then
		return defaultAuraCallback(player, offer)
	elseif offerType == "vip" then
		return defaultVipCallback(player, offer)
	else
		-- Default to item
		return defaultItemCallback(player, offer)
	end

	return "Something went wrong, try again or contact server admin [#2]!"
end

-- Aura purchase callback
function defaultAuraCallback(player, offer)
	local effectId = offer.serverId
	if not effectId or type(effectId) ~= "number" then
		return "Invalid aura effect."
	end
	
	-- Check if player already owns this aura
	local ownedAuras = player:getStorageValue(STORAGE_OWNED_AURAS)
	if ownedAuras < 0 then
		ownedAuras = 0
	end
	
	-- Calculate bit position (effectId 301 = bit 0, 302 = bit 1, etc.)
	local bitPos = effectId - 301
	local auraBit = bit.lshift(1, bitPos)
	
	if bit.band(ownedAuras, auraBit) ~= 0 then
		return "You already own this aura effect."
	end
	
	-- Add aura to owned list
	ownedAuras = bit.bor(ownedAuras, auraBit)
	player:setStorageValue(STORAGE_OWNED_AURAS, ownedAuras)
	
	-- Notify client about new owned aura
	sendPlayerAuraData(player)
	
	return false
end

-- Send aura data to client
function sendPlayerAuraData(player)
	local ownedAuras = player:getStorageValue(STORAGE_OWNED_AURAS)
	if ownedAuras < 0 then
		ownedAuras = 0
	end
	
	local activeAura = player:getStorageValue(STORAGE_ACTIVE_AURA)
	if activeAura < 0 then
		activeAura = 0
	end
	
	-- Build list of owned aura IDs
	local ownedList = {}
	for _, aura in ipairs(AURA_EFFECTS) do
		local bitPos = aura.effectId - 301
		local auraBit = bit.lshift(1, bitPos)
		if bit.band(ownedAuras, auraBit) ~= 0 then
			table.insert(ownedList, aura.effectId)
		end
	end
	
	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({
		action = "auraData",
		data = {
			owned = ownedList,
			active = activeAura
		}
	}))
end

-- Activate/deactivate aura
function setPlayerAura(player, effectId)
	local ownedAuras = player:getStorageValue(STORAGE_OWNED_AURAS)
	if ownedAuras < 0 then
		ownedAuras = 0
	end
	
	-- If effectId is 0, deactivate aura
	if effectId == 0 then
		player:setStorageValue(STORAGE_ACTIVE_AURA, 0)
		sendPlayerAuraData(player)
		return true
	end
	
	-- Check if player owns this aura
	local bitPos = effectId - 301
	local auraBit = bit.lshift(1, bitPos)
	
	if bit.band(ownedAuras, auraBit) == 0 then
		return false -- Player doesn't own this aura
	end
	
	player:setStorageValue(STORAGE_ACTIVE_AURA, effectId)
	sendPlayerAuraData(player)
	return true
end

function defaultPremiumCallback(player, offer)
	player:addPremiumDays(offer.count)
	return false
end

-- VIP Status purchase callback
function defaultVipCallback(player, offer)
	local vipDays = offer.count
	if not vipDays or vipDays <= 0 then
		return "Invalid VIP duration."
	end
	
	-- Add VIP days to player
	local currentVipDays = player:getStorageValue(STORAGE_VIP_DAYS)
	if currentVipDays < 0 then
		currentVipDays = 0
	end
	
	player:setStorageValue(STORAGE_VIP_DAYS, currentVipDays + vipDays)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "You have received " .. vipDays .. " days of VIP Status! Total: " .. (currentVipDays + vipDays) .. " days remaining.")
	
	return false
end

function defaultItemCallback(player, offer)
	local inPz = player:getTile():hasFlag(TILESTATE_PROTECTIONZONE)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if not inPz and inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end

	local serverId = offer.serverId
	if type(serverId) == "string" then
		return "This item cannot be delivered automatically."
	end

	local weight = ItemType(serverId):getWeight(offer.count)
	if player:getFreeCapacity() < weight then
		return "This item is too heavy for you!"
	end

	local item = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not item then
		return "You don't have enough space in backpack."
	end

	local slots = item:getEmptySlots(true)
	if slots <= 0 then
		return "You don't have enough space in backpack."
	end
	
	if inPz then
		player:addItem(serverId, offer.count, false)
		return false
	else
		return "You must be in protection zone."
	end

	return "Something went wrong, item couldn't be added."
end

function defaultMountCallback(player, offer)
	local mountId = Game.getMountIdByClientId(offer.id)
	if player:hasMount(mountId) then
		return "You already have this mount."
	end

	if not player:addMount(mountId) then
		return "Something went wrong, mount cannot be added."
	end

	return false
end

function defaultOutfitCallback(player, offer)
	local id = offer.id
	if player:hasOutfit(id, offer.count) then
		return "You already have this outfit addon."
	end
	player:addOutfitAddon(id, offer.count)
	return false
end

function defaultChangeSexCallback(player)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end

	local inPz = player:getTile():hasFlag(TILESTATE_PROTECTIONZONE)
	if inPz then
		player:setSex(player:getSex() == PLAYERSEX_FEMALE and PLAYERSEX_MALE or PLAYERSEX_FEMALE)
	else
		return "You must be in protection zone."
	end
	
	local outfit = player:getOutfit()
	if player:getSex() == PLAYERSEX_MALE then
		outfit.lookType = 128
	else
		outfit.lookType = 136
	end

	player:setOutfit(outfit)
	return false
end

function defaultChangeNameCallback(player, offer)
	return "Name change must be purchased through the website at " .. DONATION_URL
end

function gameShopUpdateHistory(player)
	if type(player) == "number" then
		player = Player(player)
	end
	
	if not player then
		return
	end

	local history = {}
	local accountId = player:getAccountId()
	
	-- Query z_shop_history using Gesior Shop System structure
	local resultId = db.storeQuery("SELECT `id`, `to_name`, `price`, `trans_start` FROM `z_shop_history` WHERE `to_account` = " .. accountId .. " ORDER BY `id` DESC LIMIT 50")
	if resultId ~= false then
		repeat
			local timestamp = result.getNumber(resultId, "trans_start")
			local dateStr = os.date("%Y-%m-%d %H:%M:%S", timestamp)
			
			table.insert(history, {
				date = dateStr,
				price = -result.getNumber(resultId, "price"),  -- Negative to show spent points
				isSecondPrice = false,
				name = "Shop Purchase",
				count = 1
			})
		until not result.next(resultId)
		result.free(resultId)
	end
	
	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "history", data = history}))
end

local ExtendedEvent = CreatureEvent("GameShopExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode == ExtendedOPCodes.CODE_GAMESHOP then
		if not shopInitialized then
			gameShopInitialize()
			if getGlobalStorageValue(GlobalStorage.GameShopRefreshCount) == -1 then
				setGlobalStorageValue(GlobalStorage.GameShopRefreshCount, 0)
				addEvent(refreshPlayersPoints, 10 * 1000)
			end
		end

		local status, json_data = pcall(function() return json.decode(buffer) end)
		if not status then
			return
		end

		local action = json_data.action
		local data = json_data.data
		if not action or not data then
			return
		end

		if action == "fetch" then
			gameShopFetch(player)
		elseif action == "getDescription" then
			gameShopGetDescription(player, data)
		elseif action == "purchase" then
			gameShopPurchase(player, data)
		elseif action == "getAuraData" then
			sendPlayerAuraData(player)
		elseif action == "setAura" then
			local effectId = data.effectId or 0
			if setPlayerAura(player, effectId) then
				if effectId > 0 then
					infoMsg(player, "Aura effect activated!")
				else
					infoMsg(player, "Aura effect deactivated.")
				end
			else
				errorMsg(player, "You don't own this aura effect.")
			end
		end
	end
end

function gameShopGetDescription(player, data)
	local category = data.category
	local name = data.name
	
	if GAME_SHOP.offers[category] then
		for _, offer in ipairs(GAME_SHOP.offers[category]) do
			if offer.name == name then
				player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({
					action = "fetchDescription",
					data = {
						category = category,
						name = name,
						description = offer.description
					}
				}))
				return
			end
		end
	end
end

function gameShopFetch(player)
	gameShopUpdatePoints(player)
	gameShopUpdateHistory(player)
	sendPlayerAuraData(player)

	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "fetchBase", data = {categories = GAME_SHOP.categories, url = DONATION_URL}}))

	for category, offersTable in pairs(GAME_SHOP.offers) do
		local offersWithoutDesc = {}
		for _, offer in ipairs(offersTable) do
			local offerCopy = {}
			for k, v in pairs(offer) do
				if k ~= "description" then
					offerCopy[k] = v
				end
			end
			table.insert(offersWithoutDesc, offerCopy)
		end
		player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "fetchOffers", data = {category = category, offers = offersWithoutDesc}}))
	end
end

function gameShopUpdatePoints(player)
	if type(player) == "number" then
		player = Player(player)
	end
	
	if not player then
		return
	end

	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({
		action = "points", 
		data = {
			points = getPoints(player), 
			secondPoints = -1
		}
	}))
end

function getPoints(player)
	local accountId = player:getAccountId()
	
	if pointsCache[accountId] and pointsCache[accountId].time > os.time() - 300 then
		return pointsCache[accountId].points
	end
	
	local points = 0
	local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. accountId)
	if resultId ~= false then
		points = result.getNumber(resultId, "premium_points")
		result.free(resultId)
		
		pointsCache[accountId] = {
			points = points,
			time = os.time()
		}
	end

	return points
end

function errorMsg(player, msg)
	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "msg", data = {type = "error", msg = msg}}))
end

function infoMsg(player, msg, close)
	if not close then
		close = false
	end

	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "msg", data = {type = "info", msg = msg, close = close}}))
end

function refreshPlayersPoints()
	for _, p in ipairs(Game.getPlayers()) do
		if p:isPlayer() then
			gameShopUpdatePoints(p)
		end
	end
	addEvent(refreshPlayersPoints, 10 * 1000)
end

function updatePlayerShopData(playerId)
	local player = Player(playerId)
	if player then
		gameShopUpdatePoints(player)
		gameShopUpdateHistory(player)
	end
end

local LogoutEvent = CreatureEvent("GameShopLogout")

function LogoutEvent.onLogout(player)
	local accountId = player:getAccountId()
	pointsCache[accountId] = nil
	secondPointsCache[accountId] = nil
	
	return true
end

LoginEvent:type("login")
LoginEvent:register()

LogoutEvent:type("logout")
LogoutEvent:register()

ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()
