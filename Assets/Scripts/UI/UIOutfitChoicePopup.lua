--!Type(UI)

-- Define a type for a choice entry, which includes an index and a visual element.
type ChoiceEntry = {
	Index: number, -- The index of the choice entry.
	Element: VisualElement, -- The visual element associated with the choice entry.
}

-- Require the GameManager module to access game management functionalities.
local GameManager = require("GameManager")

--!Bind
-- Declare and bind the root visual element for the UI.
local _root: VisualElement = nil
--!Bind
-- Declare and bind the parent element for the choice entries.
local _entryParent: VisualElement = nil
--!Bind
-- Declare and bind the confirm button for the UI.
local _confirmButton: UIButton = nil
--!Bind
-- Declare and bind the label for displaying goal text.
local _goalText: Label = nil

-- Declare variables for the parent controller and node data.
local _parent: NPCDressUpTaskController = nil
local _nodeData: DressUpNode = nil
-- Declare a table to hold the choice entries.
local _entries: { ChoiceEntry } = nil
-- Declare a variable to hold the currently selected visual element.
local _selectedElement: VisualElement = nil

-- Function to get the root visual element.
function GetRoot(): VisualElement
	return _root
end

-- Function to get the parent element for the choice entries.
function GetEntryParent(): VisualElement
	return _entryParent
end

-- Callback function that is triggered when the confirm button is clicked.
local function OnConfirmClicked()
	local uiManager: UIManager = GameManager.UIManager
	-- Close the clothing choice popup UI.
	uiManager.CloseUI(uiManager.UINames.ClothingChoicePopup)
	-- Notify the parent controller that the clothing choice has been confirmed.
	_parent.OnClothingChoiceConfirmed()
end

-- Function to initialize the UI with the parent controller and node data.
function Init(parent: NPCDressUpTaskController, data: DressUpNode)
	_parent = parent -- Set the parent controller.
	_nodeData = data -- Set the node data.
	_entries = {} -- Initialize the entries table.

	-- Check for nil values in the node data and print warnings if found.
	if _nodeData == nil then
		print("Node data is nil")
	end

	if _nodeData.ClothingChoices == nil then
		print("Clothing choices is nil")
	end

	if _nodeData.ClothingChoices.clothing == nil then
		print("Clothing is nil")
	end

	-- Iterate through the clothing choices and create entries for each.
	for i, choice in ipairs(_nodeData.ClothingChoices.clothing) do
		local entry = CreateEntry(i, choice) -- Create a new entry.
		table.insert(_entries, entry) -- Add the entry to the entries table.
		_entryParent:Add(entry.Element) -- Add the entry's visual element to the parent.
	end

	-- Set the goal text based on the quest template.
	_goalText.text = parent.GetQuestTemplate().GoalDescription

	-- Register the confirm button's click callback.
	_confirmButton:RegisterPressCallback(OnConfirmClicked)
end

-- Function to get the currently selected visual element, creating it if it doesn't exist.
local function GetSelectedElement()
	if not _selectedElement then
		_selectedElement = VisualElement.new() -- Create a new visual element for selection.
		_selectedElement:AddToClassList("selected") -- Add a class to indicate selection.
	end
	return _selectedElement
end

-- Function to update the selection index based on the provided index.
local function SelectedIndex(index: number)
	local selectedElement = GetSelectedElement() -- Get the selected visual element.
	for i = 1, #_entries do
		local entry = _entries[i]
		-- If the entry index matches and the selected element is not already added, add it.
		if entry.Index == index and not entry.Element:Contains(selectedElement) then
			entry.Element:Add(selectedElement)
		-- If the selected element is already in the entry, remove it.
		elseif entry.Element:Contains(selectedElement) then
			entry.Element:Remove(selectedElement)
		end
	end
end

-- Callback function that is triggered when an entry is clicked.
local function OnEntryClicked(choiceEntry: ChoiceEntry)
	SelectedIndex(choiceEntry.Index) -- Update the selected index based on the clicked entry.
	-- Preview the clothing choice based on the selected entry.
	_parent.PreviewClothingChoice(_nodeData, choiceEntry.Index)
end

-- Function to create a new choice entry for a clothing item.
function CreateEntry(index: number, clothingItem: CharacterClothing): ChoiceEntry
	if not clothingItem then
		return nil -- Return nil if the clothing item is not provided.
	end

	-- Create a container for the entry.
	local container = VisualElement.new()
	container:AddToClassList("image-container") -- Add class for styling.
	container:AddToClassList("notselected") -- Add class to indicate it's not selected.

	-- Create an image element for the clothing item.
	local image = UIImage.new()
	image:AddToClassList("image") -- Add class for styling.
	print("loading clothing choice " .. clothingItem.id .. " with color " .. clothingItem.color)
	-- Load the clothing item preview.
	image:LoadItemPreview("avatar_item", clothingItem.id, clothingItem.color)

	-- Create a frame for the image.
	local frame = VisualElement.new()
	frame:AddToClassList("frame") -- Add class for styling.

	-- Add the frame and image to the container.
	container:Add(frame)
	frame:Add(image)

	-- Create a new choice entry with the index and container element.
	local entry = {
		Index = index,
		Element = container,
	}

	-- Register the click callback for the entry.
	container:RegisterPressCallback(function()
		OnEntryClicked(entry)
	end)

	return entry -- Return the created entry.
end
