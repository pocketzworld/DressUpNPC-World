--!Type(Module)

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

-- UIState defines the possible states of the UI (Open or Closed)
UIState = {
	Open = 1, -- UI is currently open
	Closed = 2, -- UI is currently closed
}

-- UIData is a structure that holds information about a UI component
type UIData = {
	UI: GameObject, -- The GameObject representing the UI
	Component: any, -- The specific component of the UI
	State: number, -- The current state of the UI (Open or Closed)
}

-- AnimType defines the types of animations that can be applied to the UI
AnimType = {
	None = 0, -- No animation
	ScaleUp = 1, -- Scale up animation
	SlideUp = 2, -- Slide up animation
}

-- UINames holds the names of various UI components for easy reference
UINames = {
	NodeUI = "NodeUI",
	ClothingChoicePopup = "ClothingChoicePopup",
	DressUpUI = "DressUpUI",
	DialogUI = "DialogUI",
	RewardUI = "RewardUI",
	QuestHud = "QuestHud",
	ContestVoting = "ContestVoting",
	Contest = "Contest",
	ContestResults = "ContestResults",
	GenericPopup = "GenericPopup",
	DressUpCloset = "DressUpCloset",
	WelcomePopup = "WelcomePopup",
	ItemStoreUI = "ItemStoreUI",
}

-------------------------------------------------------------------------------
-- Properties
-------------------------------------------------------------------------------

-- Importing the animation helper module for UI animations
local AnimateHelper = require("UIPopupAnimateHelper")

-- Prefabs for different UI components, marked for serialization
--!SerializeField
local _nodeUIPrefab: GameObject = nil
--!SerializeField
local _clothingChoiceUIPrefab: GameObject = nil
--!SerializeField
local _dressUpUIPrefab: GameObject = nil
--!SerializeField
local _dialogUIPrefab: GameObject = nil
--!SerializeField
local _rewardUIPrefab: GameObject = nil
--!SerializeField
local _questHudPrefab: GameObject = nil
--!SerializeField
local _contestVotingPrefab: GameObject = nil
--!SerializeField
local _contestPrefab: GameObject = nil
--!SerializeField
local _contestResultsPrefab: GameObject = nil
--!SerializeField
local _genericPopupPrefab: GameObject = nil
--!SerializeField
local _dressUpClosetPrefab: GameObject = nil
--!SerializeField
local _welcomePopupPrefab: GameObject = nil
--!SerializeField
local _itemStoreUIPrefab: GameObject = nil

-- Table to hold data about currently opened UIs
local _uiData: { [string]: UIData } = {}

-- Events for UI opening and closing
UIOpenedEvent = Event.new("UIOpenedEvent")
UIClosedEvent = Event.new("UIClosedEvent")

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- Opens the Node UI and returns its component
function OpenNodeUI(): UIDressUpNode
	local popup = Object.Instantiate(_nodeUIPrefab) -- Instantiate the Node UI prefab
	local node = popup:GetComponent(UIDressUpNode) -- Get the UIDressUpNode component
	return node
end

-- Opens the Clothing Choice Popup UI and returns its component
function OpenClothingChoicePopupUI(id: string): UIOutfitChoicePopup
	local ui = OpenPopup(_clothingChoiceUIPrefab, id) -- Open the popup with the given prefab and id
	local popup = ui:GetComponent(UIOutfitChoicePopup) -- Get the UIOutfitChoicePopup component
	_uiData[id].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens the Dress Up UI and returns its component
function OpenDressUpUI(id: string): UIDressUp
	local ui = OpenPopup(_dressUpUIPrefab, id) -- Open the popup with the given prefab and id
	local popup = ui:GetComponent(UIDressUp) -- Get the UIDressUp component
	_uiData[id].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.SlideUp) -- Perform slide up animation
	return popup
end

-- Opens the Dialog UI and returns its component
function OpenDialogUI(id: string): UIDialog
	local ui = OpenPopup(_dialogUIPrefab, id) -- Open the popup with the given prefab and id
	local popup = ui:GetComponent(UIDialog) -- Get the UIDialog component
	_uiData[id].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens the Reward UI and returns its component
function OpenRewardUI(): UIReward
	local ui = OpenPopup(_rewardUIPrefab, UINames.RewardUI) -- Open the Reward UI
	local popup = ui:GetComponent(UIReward) -- Get the UIReward component
	_uiData[UINames.RewardUI].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	return popup
end

-- Opens the Quest HUD UI and returns its component
function OpenQuestHudUI(id: string): UIQuestHud
	local ui = OpenPopup(_questHudPrefab, id) -- Open the popup with the given prefab and id
	local popup = ui:GetComponent(UIQuestHud) -- Get the UIQuestHud component
	_uiData[id].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens the Contest Voting UI and returns its component
function OpenContestVotingUI(): UIContestVoting
	local ui = OpenPopup(_contestVotingPrefab, UINames.ContestVoting) -- Open the Contest Voting UI
	local popup = ui:GetComponent(UIContestVoting) -- Get the UIContestVoting component
	_uiData[UINames.ContestVoting].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens the Contest UI and returns its component
function OpenContestUI(): UIContest
	local ui = OpenPopup(_contestPrefab, UINames.Contest) -- Open the Contest UI
	local popup = ui:GetComponent(UIContest) -- Get the UIContest component
	_uiData[UINames.Contest].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	return popup
end

-- Opens the Contest Results UI and returns its component
function OpenContestResultsUI(): UIContestResults
	local ui = OpenPopup(_contestResultsPrefab, UINames.ContestResults) -- Open the Contest Results UI
	local popup = ui:GetComponent(UIContestResults) -- Get the UIContestResults component
	_uiData[UINames.ContestResults].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens a generic popup UI with a message and a callback function
function OpenGenericPopupUI(message: string, callback): UIGenericPopup
	local ui = OpenPopup(_genericPopupPrefab, UINames.GenericPopup) -- Open the Generic Popup UI
	local popup = ui:GetComponent(UIGenericPopup) -- Get the UIGenericPopup component
	_uiData[UINames.GenericPopup].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	popup.Init(message, callback) -- Initialize the popup with message and callback
	return popup
end

-- Opens a generic popup for purchase confirmation with a message and callbacks
function OpenGenericPopupPurchaseUI(message: string, confirmText: string, callback, cancelCallback): UIGenericPopup
	local ui = OpenPopup(_genericPopupPrefab, UINames.GenericPopup) -- Open the Generic Popup UI
	local popup = ui:GetComponent(UIGenericPopup) -- Get the UIGenericPopup component
	_uiData[UINames.GenericPopup].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	popup.InitPurchase(message, confirmText, callback, cancelCallback) -- Initialize the popup for purchase
	return popup
end

-- Opens the Dress Up Closet UI and returns its component
function OpenDressUpClosetUI(): UIDressUpCloset
	local ui = OpenPopup(_dressUpClosetPrefab, UINames.DressUpCloset) -- Open the Dress Up Closet UI
	local popup = ui:GetComponent(UIDressUpCloset) -- Get the UIDressUpCloset component
	_uiData[UINames.DressUpCloset].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.None) -- Perform no animation
	return popup
end

-- Opens the Welcome Popup UI and returns its component
function OpenWelcomePopupUI(): UIWelcomePopup
	local ui = OpenPopup(_welcomePopupPrefab, UINames.WelcomePopup) -- Open the Welcome Popup UI
	local popup = ui:GetComponent(UIWelcomePopup) -- Get the UIWelcomePopup component
	_uiData[UINames.WelcomePopup].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	return popup
end

-- Opens the Item Store UI and returns its component
function OpenItemStoreUI(): UIItemStore
	local ui = OpenPopup(_itemStoreUIPrefab, UINames.ItemStoreUI) -- Open the Item Store UI
	local popup = ui:GetComponent(UIItemStore) -- Get the UIItemStore component
	_uiData[UINames.ItemStoreUI].Component = popup -- Store the component in the UI data
	DoAnimation(popup, AnimType.ScaleUp) -- Perform scale up animation
	return popup
end

-- Performs the specified animation on the UI component
function DoAnimation(ui, animType: number)
	local animated = animType > AnimType.None -- Check if an animation type is specified
	if animated then
		if animType == AnimType.ScaleUp then
			AnimateHelper.PlayOpenAnim(ui) -- Play scale up animation
		elseif animType == AnimType.SlideUp then
			AnimateHelper.PlaySlideUpAnim(ui) -- Play slide up animation
		end
	end
end

-- Opens a popup UI and returns the instantiated GameObject
function OpenPopup(uiPrefab: GameObject, id: string): GameObject
	local popup = Object.Instantiate(uiPrefab) -- Instantiate the UI prefab

	-- Create a new UIData entry for the opened UI
	local data = {
		UI = popup, -- Store the instantiated UI
		State = UIState.Open, -- Set the state to Open
	}

	_uiData[id] = data -- Store the UI data in the table

	UIOpenedEvent:Fire(id) -- Fire the UI opened event
	return popup -- Return the instantiated popup
end

-- Checks if a UI is currently open based on its ID
function IsUIOpen(id: string)
	local data = _uiData[id] -- Retrieve the UI data by ID
	return data and data.State ~= UIState.Closed -- Return true if the UI is open
end

-- Retrieves the component of an open UI by its ID
function GetUI(id: string): any
	local data = _uiData[id] -- Retrieve the UI data by ID
	if not data then
		return nil -- Return nil if no data found
	end
	return data.Component -- Return the UI component
end

-- Destroys the specified UI GameObject
local function DestroyUI(ui: GameObject)
	Object.Destroy(ui) -- Destroy the UI GameObject
end

-- Counts the number of currently open UIs, ignoring a specified ID
function GetOpenUICount(ignoredId: string): number
	local count = 0 -- Initialize count
	for id, data in pairs(_uiData) do -- Iterate through the UI data
		if id ~= ignoredId and data.State == UIState.Open then
			count = count + 1 -- Increment count for each open UI
		end
	end
	return count -- Return the total count of open UIs
end

-- Closes a UI by its ID
function CloseUI(id: string)
	local data = _uiData[id] -- Retrieve the UI data by ID
	if data and data.State ~= UIState.Closed then -- Check if the UI is open
		data.State = UIState.Closed -- Set the state to Closed
		DestroyUI(data.UI) -- Destroy the UI GameObject
		-- Remove UI from the table
		_uiData[id] = nil -- Remove the UI data entry
		UIClosedEvent:Fire(id) -- Fire the UI closed event
	end
end
