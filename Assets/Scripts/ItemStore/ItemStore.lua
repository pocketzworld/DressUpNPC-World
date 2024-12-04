--!Type(Module)

-- Importing necessary modules for managing saves, game logic, and utility functions
local SaveManager: SaveManager = require("SaveManager")
local GM: GameManager = require("GameManager")
local Utils: Utils = require("Utils")

-- Enum for error codes related to item purchasing
ErrorCode = {
	None = 0, -- No error
	NotEnoughCurrency = 1, -- Player does not have enough currency
	AlreadyOwned = 2, -- Player already owns the item
	ItemNotFound = 3, -- Item not found in the store
	UnknownError = 4, -- An unknown error occurred
}

-- Type definition for the response received after a purchase item request
export type PurchaseItemResponse = {
	Code: number, -- Error code from the purchase attempt
	Success: boolean, -- Indicates if the purchase was successful
	PlayerData: SaveManager.PlayerData, -- Updated player data after the purchase
}

--!SerializeField
-- Game settings that will be used to retrieve item templates
local _gameSettings: GameSettings = nil

-- Callback function to handle the response of a purchase item request
local _purchaseItemCallback: (PurchaseItemResponse) -> () = nil

-- Events for handling purchase item requests and responses
local PurchaseItemRequestEvent = Event.new("PurchaseItemRequestEvent")
local PurchaseItemResponseEvent = Event.new("PurchaseItemResponseEvent")

-------------------------------------------------------------------------------
-- Server-side functions
-------------------------------------------------------------------------------

-- Function to handle item purchase requests from players
function OnPurchaseItemRequest(player: Player, itemId: string)
	-- Retrieve the item template based on the provided item ID
	local itemTemplate: StoreItemTemplate = _gameSettings.GetItemStoreTemplate(itemId)
	if not itemTemplate then
		-- If the item template is not found, notify the player with an error
		PurchaseItemResponseEvent:FireClient(player, { Code = ErrorCode.ItemNotFound, Success = false })
		return
	end

	-- Get the player's data from the SaveManager
	local playerData: SaveManager.PlayerData = SaveManager.ServerGetPlayerData(player.user.id)
	if not playerData then
		-- If player data is not found, notify the player with an unknown error
		PurchaseItemResponseEvent:FireClient(player, { Code = ErrorCode.UnknownError, Success = false })
		return
	end

	-- Check if the player already owns the item
	if Utils.IsInTable(playerData.ItemsPurchased, itemTemplate.Id) then
		-- If the player already owns the item, notify them
		PurchaseItemResponseEvent:FireClient(player, { Code = ErrorCode.AlreadyOwned, Success = false })
		return
	end

	-- Check if the player has enough currency to purchase the item
	if not SaveManager.HasEnoughCurrency(playerData, itemTemplate.CurrencyCostTemplate.Id, itemTemplate.Cost) then
		-- If not enough currency, notify the player
		PurchaseItemResponseEvent:FireClient(player, { Code = ErrorCode.NotEnoughCurrency, Success = false })
		return
	end

	-- Deduct the currency from the player's account
	SaveManager.SpendCurrency(playerData, itemTemplate.CurrencyCostTemplate.Id, itemTemplate.Cost)
	-- Add the purchased item to the player's list of items
	table.insert(playerData.ItemsPurchased, itemTemplate.Id)

	-- Add the reward associated with the purchased item to the player's reward list
	table.insert(playerData.RewardList, { Id = itemTemplate.ClothingCollectionRewardTemplate.Id, Amount = 1 })

	-- Save the updated player data and notify the player of a successful purchase
	SaveManager.ServerSavePlayerData(player, playerData, function()
		PurchaseItemResponseEvent:FireClient(player, {
			Code = ErrorCode.None, -- No error
			Success = true, -- Purchase was successful
			PlayerData = playerData, -- Return the updated player data
		})
	end, false)
end

-- Function to initialize the server and connect the purchase item request event
function self.ServerAwake()
	PurchaseItemRequestEvent:Connect(OnPurchaseItemRequest)
end

-------------------------------------------------------------------------------
-- Client-side functions
-------------------------------------------------------------------------------

-- Function to request an item purchase from the server
function RequestPurchaseItem(itemId: string, callback: (PurchaseItemResponse) -> ())
	_purchaseItemCallback = callback -- Store the callback for handling the response
	PurchaseItemRequestEvent:FireServer(itemId) -- Fire the request to the server
end

-- Function to handle the response from the server after a purchase item request
function OnPurchaseItemResponse(response: PurchaseItemResponse)
	if _purchaseItemCallback then
		-- Update the client-side player data with the response data
		SaveManager.ClientSetPlayerData(response.PlayerData)
		-- Call the stored callback with the response
		_purchaseItemCallback(response)
	end
end

-- Function to initialize the client and connect the purchase item response event
function self.ClientAwake()
	PurchaseItemResponseEvent:Connect(OnPurchaseItemResponse)
end
