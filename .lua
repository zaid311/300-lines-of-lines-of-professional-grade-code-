-- Advanced Shop & Trading System - COMPLETE WITH TEST DATA
-- A comprehensive marketplace system with player-to-player trading, 
-- price tracking, inventory management, and transaction history
-- Author: [Your Name]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Data Stores
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
local MarketDataStore = DataStoreService:GetDataStore("MarketData_v1")
local TransactionStore = DataStoreService:GetDataStore("Transactions_v1")

-- Remote Events Setup
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "TradingSystem"
remoteEvents.Parent = ReplicatedStorage

local createListingEvent = Instance.new("RemoteEvent")
createListingEvent.Name = "CreateListing"
createListingEvent.Parent = remoteEvents

local buyItemEvent = Instance.new("RemoteEvent")
buyItemEvent.Name = "BuyItem"
buyItemEvent.Parent = remoteEvents

local getMarketDataEvent = Instance.new("RemoteFunction")
getMarketDataEvent.Name = "GetMarketData"
getMarketDataEvent.Parent = remoteEvents

print("✅ Remote events created in ReplicatedStorage")

-- Item Database
local ITEMS_DATABASE = {
	["Speed_Potion"] = {
		name = "Speed Potion",
		rarity = "Common",
		category = "Consumables",
		basePrice = 50,
		description = "Increases speed for 5 minutes"
	},
	["Jump_Boots"] = {
		name = "Jump Boots",
		rarity = "Rare", 
		category = "Equipment",
		basePrice = 200,
		description = "Permanent jump boost"
	},
	["Golden_Trophy"] = {
		name = "Golden Trophy",
		rarity = "Legendary",
		category = "Collectibles", 
		basePrice = 1000,
		description = "Shows your greatness"
	},
	["Diamond_Sword"] = {
		name = "Diamond Sword",
		rarity = "Epic",
		category = "Weapons",
		basePrice = 500,
		description = "Powerful combat weapon"
	},
	["Magic_Wand"] = {
		name = "Magic Wand",
		rarity = "Rare",
		category = "Weapons",
		basePrice = 300,
		description = "Casts magical spells"
	},
	["Health_Potion"] = {
		name = "Health Potion",
		rarity = "Common",
		category = "Consumables",
		basePrice = 25,
		description = "Restores full health"
	}
}

-- Trading System Class
local TradingSystem = {}
TradingSystem.__index = TradingSystem

-- Initialize Trading System
function TradingSystem.new()
	local self = setmetatable({}, TradingSystem)
	self.activeListings = {}
	self.playerInventories = {}
	self.priceHistory = {}
	self.transactionLog = {}

	-- Create test listings immediately
	self:createTestListings()

	-- Initialize price history
	self:initializePriceHistory()

	print("✅ Trading System initialized with test data")

	return self
end

-- Create Test Listings for Demo
function TradingSystem:createTestListings()
	local testListings = {
		{
			id = "test_listing_1",
			sellerId = 999999999,
			sellerName = "ProTrader",
			itemId = "Speed_Potion",
			quantity = 3,
			price = 75,
			timestamp = os.time(),
			status = "active"
		},
		{
			id = "test_listing_2", 
			sellerId = 888888888,
			sellerName = "ItemCollector",
			itemId = "Jump_Boots",
			quantity = 1,
			price = 250,
			timestamp = os.time(),
			status = "active"
		},
		{
			id = "test_listing_3",
			sellerId = 777777777,
			sellerName = "DiamondDealer",
			itemId = "Diamond_Sword",
			quantity = 2,
			price = 500,
			timestamp = os.time(),
			status = "active"
		},
		{
			id = "test_listing_4",
			sellerId = 666666666,
			sellerName = "TrophyHunter",
			itemId = "Golden_Trophy",
			quantity = 1,
			price = 1200,
			timestamp = os.time(),
			status = "active"
		},
		{
			id = "test_listing_5",
			sellerId = 555555555,
			sellerName = "MagicShop",
			itemId = "Magic_Wand",
			quantity = 1,
			price = 350,
			timestamp = os.time(),
			status = "active"
		},
		{
			id = "test_listing_6",
			sellerId = 444444444,
			sellerName = "PotionMaster",
			itemId = "Health_Potion",
			quantity = 5,
			price = 30,
			timestamp = os.time(),
			status = "active"
		}
	}

	self.activeListings = testListings
	print("✅ Created", #testListings, "test listings for marketplace demo")
end

-- Initialize Price History
function TradingSystem:initializePriceHistory()
	-- Add realistic price history data
	self:updatePriceHistory("Speed_Potion", 70)
	self:updatePriceHistory("Speed_Potion", 80)
	self:updatePriceHistory("Speed_Potion", 75)

	self:updatePriceHistory("Jump_Boots", 240)
	self:updatePriceHistory("Jump_Boots", 260)

	self:updatePriceHistory("Diamond_Sword", 480)
	self:updatePriceHistory("Diamond_Sword", 520)

	self:updatePriceHistory("Golden_Trophy", 1100)
	self:updatePriceHistory("Golden_Trophy", 1300)

	self:updatePriceHistory("Magic_Wand", 320)
	self:updatePriceHistory("Health_Potion", 25)

	print("✅ Price history initialized")
end

-- Player Data Management
function TradingSystem:getPlayerData(player)
	-- For demo purposes, return rich test data
	return {
		inventory = {
			["Speed_Potion"] = 5,
			["Jump_Boots"] = 2,
			["Health_Potion"] = 8,
			["Magic_Wand"] = 1,
			["Diamond_Sword"] = 1
		},
		currency = 2500,
		totalTrades = 15,
		reputation = 98
	}
end

function TradingSystem:savePlayerData(player, data)
	-- In a real system, this would save to DataStore
	-- For demo, we just print what would be saved
	print("💾 Would save data for", player.Name, "- Currency:", data.currency)
end

-- Price Analysis System
function TradingSystem:updatePriceHistory(itemId, price)
	if not self.priceHistory[itemId] then
		self.priceHistory[itemId] = {}
	end

	table.insert(self.priceHistory[itemId], {
		price = price,
		timestamp = os.time()
	})

	-- Keep only last 50 transactions
	if #self.priceHistory[itemId] > 50 then
		table.remove(self.priceHistory[itemId], 1)
	end
end

function TradingSystem:getAveragePrice(itemId, days)
	days = days or 7
	local cutoffTime = os.time() - (days * 24 * 60 * 60)
	local prices = {}

	if self.priceHistory[itemId] then
		for _, record in ipairs(self.priceHistory[itemId]) do
			if record.timestamp >= cutoffTime then
				table.insert(prices, record.price)
			end
		end
	end

	if #prices == 0 then
		return ITEMS_DATABASE[itemId] and ITEMS_DATABASE[itemId].basePrice or 0
	end

	local sum = 0
	for _, price in ipairs(prices) do
		sum = sum + price
	end

	return math.floor(sum / #prices)
end

-- Listing Management
function TradingSystem:createListing(player, itemId, quantity, price)
	local playerData = self:getPlayerData(player)

	-- Validation checks
	if not ITEMS_DATABASE[itemId] then
		return false, "Item doesn't exist"
	end

	if not playerData.inventory[itemId] or playerData.inventory[itemId] < quantity then
		return false, "Insufficient items in inventory"
	end

	if price <= 0 then
		return false, "Invalid price"
	end

	-- Create unique listing ID
	local listingId = HttpService:GenerateGUID(false)

	-- Remove items from player inventory
	playerData.inventory[itemId] = playerData.inventory[itemId] - quantity
	self:savePlayerData(player, playerData)

	-- Create listing
	local listing = {
		id = listingId,
		sellerId = player.UserId,
		sellerName = player.Name,
		itemId = itemId,
		quantity = quantity,
		price = price,
		timestamp = os.time(),
		status = "active"
	}

	table.insert(self.activeListings, listing)

	print("✅ Created listing:", itemId, "for", price, "by", player.Name)

	return true, "Listing created successfully"
end

function TradingSystem:buyItem(buyer, listingId)
	local listing = nil
	local listingIndex = nil

	-- Find the listing
	for i, l in ipairs(self.activeListings) do
		if l.id == listingId and l.status == "active" then
			listing = l
			listingIndex = i
			break
		end
	end

	if not listing then
		return false, "Listing not found or no longer available"
	end

	-- Can't buy your own items
	if listing.sellerId == buyer.UserId then
		return false, "Cannot buy your own items"
	end

	local buyerData = self:getPlayerData(buyer)

	-- Check if buyer has enough currency
	if buyerData.currency < listing.price then
		return false, "Insufficient funds"
	end

	-- Process transaction
	buyerData.currency = buyerData.currency - listing.price

	-- Add item to buyer inventory
	if not buyerData.inventory[listing.itemId] then
		buyerData.inventory[listing.itemId] = 0
	end
	buyerData.inventory[listing.itemId] = buyerData.inventory[listing.itemId] + listing.quantity
	buyerData.totalTrades = buyerData.totalTrades + 1

	-- Save buyer data
	self:savePlayerData(buyer, buyerData)

	-- Update price history
	self:updatePriceHistory(listing.itemId, listing.price)

	-- Log transaction
	local transaction = {
		id = HttpService:GenerateGUID(false),
		buyerId = buyer.UserId,
		buyerName = buyer.Name,
		sellerId = listing.sellerId,
		sellerName = listing.sellerName,
		itemId = listing.itemId,
		quantity = listing.quantity,
		price = listing.price,
		timestamp = os.time()
	}

	table.insert(self.transactionLog, transaction)

	-- Remove listing
	table.remove(self.activeListings, listingIndex)

	print("✅ Purchase completed:", buyer.Name, "bought", listing.itemId, "for", listing.price)

	return true, "Purchase successful"
end

-- Search and Filter System
function TradingSystem:searchListings(filters)
	filters = filters or {}
	local results = {}

	for _, listing in ipairs(self.activeListings) do
		if listing.status == "active" then
			local include = true

			-- Category filter
			if filters.category then
				local item = ITEMS_DATABASE[listing.itemId]
				if not item or item.category ~= filters.category then
					include = false
				end
			end

			-- Price range filter
			if filters.minPrice and listing.price < filters.minPrice then
				include = false
			end

			if filters.maxPrice and listing.price > filters.maxPrice then
				include = false
			end

			-- Rarity filter
			if filters.rarity then
				local item = ITEMS_DATABASE[listing.itemId]
				if not item or item.rarity ~= filters.rarity then
					include = false
				end
			end

			-- Seller filter
			if filters.excludeSeller and listing.sellerId == filters.excludeSeller then
				include = false
			end

			if include then
				-- Add market analysis data
				listing.averagePrice = self:getAveragePrice(listing.itemId)
				listing.priceComparison = listing.price / listing.averagePrice
				table.insert(results, listing)
			end
		end
	end

	-- Sort results
	if filters.sortBy == "price_low" then
		table.sort(results, function(a, b) return a.price < b.price end)
	elseif filters.sortBy == "price_high" then
		table.sort(results, function(a, b) return a.price > b.price end)
	elseif filters.sortBy == "newest" then
		table.sort(results, function(a, b) return a.timestamp > b.timestamp end)
	end

	return results
end

-- Analytics and Reporting
function TradingSystem:getMarketAnalytics(itemId)
	if not ITEMS_DATABASE[itemId] then
		return nil
	end

	local analytics = {
		itemInfo = ITEMS_DATABASE[itemId],
		currentListings = 0,
		lowestPrice = math.huge,
		averageListingPrice = 0,
		historicalAverage = self:getAveragePrice(itemId),
		totalVolume = 0,
		priceChange = 0
	}

	local listingPrices = {}

	-- Analyze current listings
	for _, listing in ipairs(self.activeListings) do
		if listing.itemId == itemId and listing.status == "active" then
			analytics.currentListings = analytics.currentListings + 1
			analytics.lowestPrice = math.min(analytics.lowestPrice, listing.price)
			table.insert(listingPrices, listing.price)
		end
	end

	-- Calculate average listing price
	if #listingPrices > 0 then
		local sum = 0
		for _, price in ipairs(listingPrices) do
			sum = sum + price
		end
		analytics.averageListingPrice = sum / #listingPrices
	end

	-- Calculate volume and price changes
	if self.priceHistory[itemId] then
		for _, record in ipairs(self.priceHistory[itemId]) do
			analytics.totalVolume = analytics.totalVolume + 1
		end
	end

	return analytics
end

-- Event Handlers
function TradingSystem:setupEventHandlers()
	createListingEvent.OnServerEvent:Connect(function(player, itemId, quantity, price)
		print("📝 Create listing request from", player.Name)
		local success, message = self:createListing(player, itemId, quantity, price)
		createListingEvent:FireClient(player, success, message)
	end)

	buyItemEvent.OnServerEvent:Connect(function(player, listingId)
		print("💰 Buy item request from", player.Name)
		local success, message = self:buyItem(player, listingId)
		buyItemEvent:FireClient(player, success, message)
	end)

	getMarketDataEvent.OnServerInvoke = function(player, requestType, filters)
		print("📊 Market data request:", requestType, "from", player.Name)

		if requestType == "listings" then
			local listings = self:searchListings(filters)
			print("📋 Returning", #listings, "listings")
			return listings
		elseif requestType == "analytics" then
			return self:getMarketAnalytics(filters.itemId)
		elseif requestType == "inventory" then
			local playerData = self:getPlayerData(player)
			print("🎒 Returning inventory for", player.Name, "- Currency:", playerData.currency)
			return playerData.inventory, playerData.currency
		end
	end

	print("✅ Event handlers connected")
end

-- Cleanup and Maintenance
function TradingSystem:cleanupExpiredListings()
	local currentTime = os.time()
	local expireTime = 7 * 24 * 60 * 60 -- 7 days

	for i = #self.activeListings, 1, -1 do
		local listing = self.activeListings[i]
		if currentTime - listing.timestamp > expireTime then
			table.remove(self.activeListings, i)
		end
	end
end

-- Initialize System
print("🚀 Initializing Advanced Trading System...")
local tradingSystem = TradingSystem.new()
tradingSystem:setupEventHandlers()

-- Periodic maintenance
spawn(function()
	while true do
		wait(300) -- Every 5 minutes
		tradingSystem:cleanupExpiredListings()
	end
end)

-- Player connection handling
Players.PlayerAdded:Connect(function(player)
	print("👋 Player joined:", player.Name)
	local playerData = tradingSystem:getPlayerData(player)
	tradingSystem.playerInventories[player.UserId] = playerData.inventory
end)

Players.PlayerRemoving:Connect(function(player)
	print("👋 Player left:", player.Name)
	tradingSystem.playerInventories[player.UserId] = nil
end)

-- System Status Report
wait(1)
print("🎉 ADVANCED TRADING SYSTEM FULLY OPERATIONAL!")
print("📊 System Features:")
print("   • Player-to-player trading marketplace")
print("   • Dynamic pricing with historical analysis") 
print("   • Advanced search and filtering capabilities")
print("   • Market analytics and reporting systems")
print("   • Transaction logging and audit trails")
print("   • Automated maintenance and cleanup")
print("📈 Demo Data:")
print("   • Active Listings:", #tradingSystem.activeListings)
print("   • Items in Database:", #ITEMS_DATABASE)
print("   • Price History Records: Multiple items tracked")
print("✅ Ready for demonstration!")-- PURCHASE SUCCESS NOTIFICATIONS - Add to end of ServerScript
buyItemEvent.OnServerEvent:Connect(function(player, listingId)
	print("💰 Processing purchase for", player.Name)
	local success, message = tradingSystem:buyItem(player, listingId)

	if success then
		-- Find what they bought for the notification
		local boughtItem = "item"
		for _, listing in ipairs(tradingSystem.activeListings) do
			if listing.id == listingId then
				boughtItem = listing.itemId:gsub("_", " ")
				break
			end
		end

		-- Create purchase notification GUI
		spawn(function()
			wait(0.5) -- Small delay

			local gui = Instance.new("ScreenGui")
			local notificationFrame = Instance.new("Frame")
			local titleLabel = Instance.new("TextLabel")
			local itemLabel = Instance.new("TextLabel")
			local inventoryLabel = Instance.new("TextLabel")

			gui.Name = "PurchaseNotification"
			gui.Parent = player.PlayerGui

			notificationFrame.Size = UDim2.new(0, 350, 0, 150)
			notificationFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
			notificationFrame.BackgroundColor3 = Color3.new(0, 0.8, 0)
			notificationFrame.BorderSizePixel = 3
			notificationFrame.BorderColor3 = Color3.new(1, 1, 1)
			notificationFrame.Parent = gui

			titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
			titleLabel.Text = "🎉 PURCHASE SUCCESS! 🎉"
			titleLabel.TextScaled = true
			titleLabel.BackgroundTransparency = 1
			titleLabel.TextColor3 = Color3.new(1, 1, 1)
			titleLabel.Parent = notificationFrame

			itemLabel.Size = UDim2.new(1, 0, 0.3, 0)
			itemLabel.Position = UDim2.new(0, 0, 0.4, 0)
			itemLabel.Text = "✅ " .. boughtItem .. " added to inventory!"
			itemLabel.TextScaled = true
			itemLabel.BackgroundTransparency = 1
			itemLabel.TextColor3 = Color3.new(1, 1, 0)
			itemLabel.Parent = notificationFrame

			inventoryLabel.Size = UDim2.new(1, 0, 0.3, 0)
			inventoryLabel.Position = UDim2.new(0, 0, 0.7, 0)
			inventoryLabel.Text = "📦 Check your inventory to see it!"
			inventoryLabel.TextScaled = true
			inventoryLabel.BackgroundTransparency = 1
			inventoryLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
			inventoryLabel.Parent = notificationFrame

			-- Animate in
			notificationFrame.Size = UDim2.new(0, 0, 0, 0)
			notificationFrame:TweenSize(
				UDim2.new(0, 350, 0, 150),
				"Out", "Back", 0.5, true
			)

			-- Auto-remove after 4 seconds
			wait(4)
			notificationFrame:TweenSize(
				UDim2.new(0, 0, 0, 0),
				"In", "Back", 0.3, true
			)
			wait(0.3)
			gui:Destroy()
		end)
	end

	-- Send response to client
	buyItemEvent:FireClient(player, success, message)
end)
