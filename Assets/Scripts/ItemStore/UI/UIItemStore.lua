--!Type(UI)

-- Importing necessary modules for UI utilities, game management, saving data, utility functions, and item store management.
local UIUtils: UIUtils = require("UIUtils")
local GM: GameManager = require("GameManager")
local SaveManager: SaveManager = require("SaveManager")
local Utils: Utils = require("Utils")
local ItemStore: ItemStore = require("ItemStore")

--!SerializeField
-- Template for currency balance, initialized to nil.
local _currencyBalanceTemplate: CurrencyTemplate = nil

-- UI elements for the store interface.
local _content: VisualElement = nil
local _entryParent: VisualElement = nil
local _currencyBalanceLabel: Label = nil
local _loadSpinnerParent: VisualElement = nil
local _loadingSpinner: VisualElement = nil

-- Function to get the root visual element of the UI.
function GetRoot()
	return _content
end

-- Function to show or hide the loading spinner.
-- @param show: Boolean indicating whether to display the spinner.
local function ShowLoadSpinner(show)
	_loadSpinnerParent:SetDisplay(show) -- Set the display of the spinner parent.
	if not _loadingSpinner then
		-- Create a new loading spinner if it doesn't exist.
		_loadingSpinner = UIUtils.NewLoadingSpinner(_loadSpinnerParent, { "loading-spinner" })
	end
	_loadingSpinner:SetDisplay(show) -- Set the display of the loading spinner.
end

-- Function to close the UI for the item store.
local function CloseUI()
	GM.UIManager.CloseUI(GM.UIManager.UINames.ItemStoreUI) -- Close the item store UI.
end

-- Function to clear all entries from the entry parent.
local function ClearEntries()
	if _entryParent then
		_entryParent:Clear() -- Clear the entries if the entry parent exists.
	end
end

-- Function to create entries for the items in the store.
local function CreateEntries()
	local storeItems = GM.Settings.GetStoreItems() -- Get the list of store items.
	local rowCount = #storeItems / 3 -- Calculate the number of rows needed.
	local count = 0
	local rowEntry = nil
	for _, storeItem in ipairs(storeItems) do
		if count % 3 == 0 then
			-- Create a new row entry for every three items.
			rowEntry = UIUtils.NewVisualElement(_entryParent, { "storeentryrow", "horizontal-layout", "centered" })
		end
		CreateStoreEntry(storeItem, rowEntry) -- Create a store entry for the current item.
		count = count + 1
	end
end

-- Function to refresh the UI, updating entries and currency balance.
local function Refresh()
	ClearEntries() -- Clear existing entries.

	-- Update the currency balance.
	local playerData = SaveManager.GetClientPlayerData() -- Get player data.
	local amt = SaveManager.GetCurrencyAmount(playerData, _currencyBalanceTemplate.Id) -- Get currency amount.
	_currencyBalanceLabel.text = tostring(amt) -- Update the currency balance label.

	CreateEntries() -- Create new entries for the store items.
end

-- Function to handle the response after an item purchase attempt.
-- @param response: The response from the purchase request.
-- @param template: The template of the store item being purchased.
local function OnPurchasedItem(response: ItemStore.PurchaseItemResponse, template: StoreItemTemplate)
	if response == nil then
		GM.UIManager.OpenGenericPopupUI("Unknown error", nil) -- Show error if response is nil.
		return
	end

	if response.Code ~= ItemStore.ErrorCode.None then
		-- Show error message if the purchase failed.
		GM.UIManager.OpenGenericPopupUI(
			"Failed to purchase item. Please try again later. Error code: " .. response.Code,
			nil
		)
		return
	end

	local items: { GM.GameItemAmount } = {}
	table.insert(items, { Template = template, Amount = 1 }) -- Prepare the item for reward UI.
	local rewardUI: UIReward = GM.UIManager.OpenRewardUI() -- Open the reward UI.
	rewardUI.Init(items, nil) -- Initialize the reward UI with the purchased item.
end

-- Function to handle the click event on a store item entry.
-- @param entry: The visual element representing the store item.
-- @param template: The template of the store item.
local function OnClickedItem(entry: VisualElement, template: StoreItemTemplate)
	GM.UIManager.OpenGenericPopupPurchaseUI(
		"Purchase "
			.. template.DisplayData.Name
			.. " for "
			.. template.Cost
			.. " "
			.. template.CurrencyCostTemplate.DisplayData.Name
			.. "?",
		"Purchase",
		function()
			ShowLoadSpinner(true) -- Show loading spinner while processing purchase.
			ItemStore.RequestPurchaseItem(template.Id, function(response)
				ShowLoadSpinner(false) -- Hide loading spinner after response.
				OnPurchasedItem(response, template) -- Handle the purchase response.
				Refresh() -- Refresh the UI after purchase.
			end)
		end,
		nil
	)
end

-- Function to create a store entry for a specific item.
-- @param template: The template of the store item.
-- @param rowEntry: The visual element representing the row for the item.
function CreateStoreEntry(template: StoreItemTemplate, rowEntry: VisualElement)
	local rewardEntry = UIUtils.NewVisualElement(rowEntry, { "storeentry" }, false) -- Create a new entry for the store item.

	local entryTop = UIUtils.NewVisualElement(rewardEntry, { "storeentrytop" }) -- Top section of the entry.

	local icon = UIUtils.NewImage(entryTop, { "storeicon" }) -- Image for the store item icon.
	if template.DisplayData and template.DisplayData.ImageSprite then
		icon.image = template.DisplayData.ImageSprite.texture -- Set the icon image if available.
	end

	local entryBot = UIUtils.NewVisualElement(rewardEntry, { "storeentrybot", "vertical-layout", "centered" }) -- Bottom section of the entry.
	local nameLabel =
		UIUtils.NewLabel(entryBot, { "storename", "wrap", "white", "font12", "centertext" }, template.DisplayData.Name) -- Label for the item name.
	UIUtils.ZeroPadding(nameLabel) -- Remove padding from the name label.

	local playerData = SaveManager.GetClientPlayerData() -- Get player data to check ownership and currency.
	local owned = Utils.IsInTable(playerData.ItemsPurchased, template.Id) -- Check if the item is owned.
	local canPurchase = SaveManager.HasEnoughCurrency(playerData, template.CurrencyCostTemplate.Id, template.Cost) -- Check if the player can afford the item.

	if owned then
		local costLabel = UIUtils.NewLabel(entryBot, { "white", "font14" }, "Owned") -- Label indicating the item is owned.
		UIUtils.ZeroMargin(costLabel) -- Remove margin from the cost label.
		UIUtils.ZeroPadding(nameLabel) -- Remove padding from the name label.
	else
		if canPurchase then
			-- Register a callback for when the item is clicked if the player can purchase it.
			rewardEntry:RegisterPressCallback(function()
				OnClickedItem(rewardEntry, template)
			end)
		end

		local currencyDisplay =
			UIUtils.NewVisualElement(entryBot, { "storecurrencydisplay", "horizontal-layout", "centered" }) -- Display for currency cost.
		local costImage = UIUtils.NewImage(currencyDisplay, { "storecostimage" }) -- Image for the currency type.
		costImage.image = template.CurrencyCostTemplate.DisplayData.ImageSprite.texture -- Set the currency image.
		local textColor = canPurchase and "white" or "red" -- Set text color based on purchase ability.
		local costLabel = UIUtils.NewLabel(currencyDisplay, { "storecost", textColor, "font14" }, template.Cost) -- Label for the cost of the item.
		UIUtils.ZeroMargin(costLabel) -- Remove margin from the cost label.
		UIUtils.ZeroPadding(costLabel) -- Remove padding from the cost label.
	end
end

-- Function called when the client is initialized.
function self.ClientAwake()
	local playerData = SaveManager.GetClientPlayerData() -- Get player data.
	if not playerData then
		CloseUI() -- Close UI if no player data is found.
		return
	end

	-- Create a close overlay to close the UI when clicked.
	local closeOverlay = UIUtils.NewVisualElement(view, { "fill-parent", "absolute" }, false)
	closeOverlay:RegisterCallback(PointerDownEvent, CloseUI) -- Register callback to close UI on click.
	_content = UIUtils.NewVisualElement(view, { "storecontent", "vertical-layout" }, false) -- Main content area for the store.

	-- Create a close button for the UI.
	local closeLabel = UIUtils.NewLabel(_content, { "storeclose", "left", "top" }, "X", false)
	UIUtils.ZeroMargin(closeLabel) -- Remove margin from the close label.
	UIUtils.ZeroPadding(closeLabel) -- Remove padding from the close label.
	closeLabel:RegisterPressCallback(CloseUI) -- Register callback to close UI on click.

	-- Create title section for the store.
	local titleSection = UIUtils.NewVisualElement(_content, { "storetitlesection", "horizontal-layout", "centered" })
	local title = UIUtils.NewLabel(titleSection, { "font26" }, "Store") -- Title label for the store.
	local divider = UIUtils.NewVisualElement(_content, { "divider" }) -- Divider element for UI layout.
	local currencyBalanceSection =
		UIUtils.NewVisualElement(titleSection, { "storecurrencybalance", "horizontal-layout", "right", "centered" }) -- Section for displaying currency balance.

	-- Create image and label for currency balance.
	local costImage = UIUtils.NewImage(currencyBalanceSection, { "storecostimage" })
	costImage.image = _currencyBalanceTemplate.DisplayData.ImageSprite.texture -- Set the currency image.
	_currencyBalanceLabel = UIUtils.NewLabel(currencyBalanceSection, { "storecurrencybalancelabel", "white" }, "") -- Label for currency balance.

	_entryParent = UIUtils.NewVisualElement(_content, { "storeentryparent", "vertical-layout", "flexstart" }) -- Parent element for store entries.
	Refresh() -- Refresh the UI to display items.

	_loadSpinnerParent = UIUtils.NewVisualElement(view, { "fill-parent", "absolute", "modal" }, false) -- Parent element for loading spinner.
	ShowLoadSpinner(false) -- Initially hide the loading spinner.
end
