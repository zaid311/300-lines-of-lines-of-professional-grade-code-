-- Advanced Shop & Trading System
-- A comprehensive marketplace system with player-to-player trading, 
-- price tracking, inventory management, and transaction history
-- Author: ZAID

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

-- Trading System Class
local TradingSystem = {}
TradingSystem.__index = TradingSystem

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
    }
}

-- Initialize Trading System
function TradingSystem.new()
    local self = setmetatable({}, TradingSystem)
    self.activeListings = {}
    self.playerInventories = {}
    self.priceHistory = {}
    self.transactionLog = {}
    
    -- Load market data on startup
    self:loadMarketData()
    
    return self
end

-- Player Data Management
function TradingSystem:getPlayerData(player)
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        return data
    else
        -- Default player data
        return {
            inventory = {
                ["Speed_Potion"] = 3,
                ["Jump_Boots"] = 1
            },
            currency = 1000,
            totalTrades = 0,
            reputation = 100
        }
    end
end

function TradingSystem:savePlayerData(player, data)
    pcall(function()
        PlayerDataStore:SetAsync(player.UserId, data)
    end)
end

-- Market Data Management
function TradingSystem:loadMarketData()
    local success, data = pcall(function()
        return MarketDataStore:GetAsync("GlobalMarket")
    end)
    
    if success and data then
        self.activeListings = data.listings or {}
        self.priceHistory = data.priceHistory or {}
    end
end

function TradingSystem:saveMarketData()
    local marketData = {
        listings = self.activeListings,
        priceHistory = self.priceHistory,
        lastUpdated = os.time()
    }
    
    pcall(function()
        MarketDataStore:SetAsync("GlobalMarket", marketData)
    end)
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
    self:saveMarketData()
    
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
    
    -- Process seller payment
    local seller = Players:GetPlayerByUserId(listing.sellerId)
    if seller then
        local sellerData = self:getPlayerData(seller)
        sellerData.currency = sellerData.currency + listing.price
        sellerData.totalTrades = sellerData.totalTrades + 1
        self:savePlayerData(seller, sellerData)
    end
    
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
    self:saveMarketData()
    
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
        
        -- Price change calculation (last 7 days vs previous 7 days)
        local recent = self:getAveragePrice(itemId, 7)
        local previous = self:getAveragePrice(itemId, 14) - recent
        
        if previous > 0 then
            analytics.priceChange = ((recent - previous) / previous) * 100
        end
    end
    
    return analytics
end

-- Event Handlers
function TradingSystem:setupEventHandlers()
    createListingEvent.OnServerEvent:Connect(function(player, itemId, quantity, price)
        local success, message = self:createListing(player, itemId, quantity, price)
        -- Send response back to client
        createListingEvent:FireClient(player, success, message)
    end)
    
    buyItemEvent.OnServerEvent:Connect(function(player, listingId)
        local success, message = self:buyItem(player, listingId)
        -- Send response back to client
        buyItemEvent:FireClient(player, success, message)
    end)
    
    getMarketDataEvent.OnServerInvoke = function(player, requestType, filters)
        if requestType == "listings" then
            return self:searchListings(filters)
        elseif requestType == "analytics" then
            return self:getMarketAnalytics(filters.itemId)
        elseif requestType == "inventory" then
            local playerData = self:getPlayerData(player)
            return playerData.inventory, playerData.currency
        end
    end
end

-- Cleanup and Maintenance
function TradingSystem:cleanupExpiredListings()
    local currentTime = os.time()
    local expireTime = 7 * 24 * 60 * 60 -- 7 days
    
    for i = #self.activeListings, 1, -1 do
        local listing = self.activeListings[i]
        if currentTime - listing.timestamp > expireTime then
            -- Return items to seller if possible
            local seller = Players:GetPlayerByUserId(listing.sellerId)
            if seller then
                local sellerData = self:getPlayerData(seller)
                if not sellerData.inventory[listing.itemId] then
                    sellerData.inventory[listing.itemId] = 0
                end
                sellerData.inventory[listing.itemId] = sellerData.inventory[listing.itemId] + listing.quantity
                self:savePlayerData(seller, sellerData)
            end
            
            table.remove(self.activeListings, i)
        end
    end
    
    self:saveMarketData()
end

-- Initialize System
local tradingSystem = TradingSystem.new()
tradingSystem:setupEventHandlers()

-- Periodic maintenance
spawn(function()
    while true do
        wait(300) -- Every 5 minutes
        tradingSystem:cleanupExpiredListings()
        tradingSystem:saveMarketData()
    end
end)

-- Player connection handling
Players.PlayerAdded:Connect(function(player)
    local playerData = tradingSystem:getPlayerData(player)
    tradingSystem.playerInventories[player.UserId] = playerData.inventory
end)

Players.PlayerRemoving:Connect(function(player)
    tradingSystem.playerInventories[player.UserId] = nil
end)

print("Advanced Trading System initialized successfully!")
print("System supports:")
print("- Player-to-player trading")
print("- Dynamic pricing with history tracking") 
print("- Advanced search and filtering")
print("- Market analytics and reporting")
print("- Data persistence across sessions")
print("- Transaction logging and cleanup")
