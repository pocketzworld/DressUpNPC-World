--!Type(UI)

-- Importing required modules
local GM: GameManager = require("GameManager") -- GameManager handles game state and logic
local UIUtils: UIUtils = require("UIUtils") -- UIUtils provides utility functions for UI operations

--!Bind
local _root: VisualElement = nil -- The root visual element for the UI
--!Bind
local _baseContainer: VisualElement = nil -- The base container for UI elements
--!Bind
local _submitButton: Button = nil -- The button for submitting the dress-up choices
--!Bind
local _modifiedLabel: UILabel = nil -- Label to display the modified state
--!Bind
local _goalText: Label = nil -- Label to display the goal text

local _parent: NPCDressUpTaskController = nil -- Reference to the parent controller managing the dress-up task
local _uiNodes: { UIDressUpNode } = {} -- Table to hold the dress-up UI nodes
local _timerList: { Timer } = {} -- Table to hold timers for animations

-- Function to get the root visual element
function GetRoot(): VisualElement
	return _root
end

-- Function to get the size of the base container
function GetSize(): Vector2
	local size = Vector2.zero
	size.x = _baseContainer.layout.width -- Get width from the layout
	size.y = _baseContainer.layout.height -- Get height from the layout
	return size
end

-- Function to destroy all UI nodes and stop timers
local function DestroyNodes()
	for _, timer in ipairs(_timerList) do -- Iterate through the timer list
		if timer and timer ~= nil then
			timer:Stop() -- Stop the timer if it exists
		end
	end
	table.clear(_timerList) -- Clear the timer list

	for i, node in ipairs(_uiNodes) do -- Iterate through the UI nodes
		Object.Destroy(node) -- Destroy each node
	end
	table.clear(_uiNodes) -- Clear the UI nodes list
end

-- Callback function for when the submit button is clicked
local function OnSubmitClicked()
	DestroyNodes() -- Destroy nodes before submitting
	_parent.SubmitDressUp() -- Call the submit function on the parent controller
end

-- Function to refresh the state of the UI nodes based on the current dress-up state
local function RefreshNodes(dressUpState: DressUpState)
	for i, node in ipairs(_uiNodes) do -- Iterate through the UI nodes
		node.SetChosen(dressUpState.Choices[i] ~= -1) -- Update each node's chosen state
	end
end

-- Function to refresh the UI based on the current dress-up state
function Refresh(dressUpState: DressUpState)
	local state = _parent.GetDressUpState() -- Get the current dress-up state
	_modifiedLabel:SetPrelocalizedText(
		"Modified: " .. _parent.GetFilledInChoicesCount() .. "/" .. state.Task.OutfitCount
	) -- Update the modified label
	RefreshNodes(dressUpState) -- Refresh the nodes with the new state
end

-- Function to show or hide the UI nodes based on the boolean parameter
local function ShowNodes(show: boolean)
	for i, node in ipairs(_uiNodes) do -- Iterate through the UI nodes
		UIUtils.ShowElementByOpacity(node.GetRoot(), show) -- Show or hide each node
	end
end

-- Function to show or hide the root element and its nodes
function Show(show: boolean)
	GM.Utils.ShowElement(_root, show) -- Show or hide the root element
	ShowNodes(show) -- Show or hide the child nodes
end

-- Function to scale up the nodes with a timed animation
local function ScaleUpNodes()
	local time = 0.25 -- Initial time for the animation
	for i, node in ipairs(_uiNodes) do -- Iterate through the UI nodes
		local timer = Timer.After(time, function() -- Create a timer for the scale-up animation
			if not node or node.gameObject == nil then
				return -- Return if the node is invalid
			end
			node.PlayScaleUpAnim() -- Play the scale-up animation
		end)
		time = time + 0.25 -- Increment the time for the next node
		table.insert(_timerList, timer) -- Add the timer to the list
	end
end

-- Function to initialize the UI with the parent controller
function Init(parent: NPCDressUpTaskController)
	_parent = parent -- Set the parent controller
	_submitButton:RegisterPressCallback(OnSubmitClicked) -- Register the submit button callback

	local uiManager: UIManager = GM.UIManager -- Get the UI manager
	local dressUpTask: DressUpTask = _parent.GetDressUpTask() -- Get the current dress-up task
	-- Create nodes for each outfit
	for i = 1, dressUpTask.OutfitCount do
		local node: UIDressUpNode = uiManager.OpenNodeUI() -- Open a new node UI
		node.Init(_parent, dressUpTask.GetDressUpData(i), _parent.GetNodeAnchors()[i]) -- Initialize the node
		node.HideNodeForScaleUp() -- Hide the node initially for scaling up
		table.insert(_uiNodes, node) -- Add the node to the UI nodes list
	end
	_goalText.text = parent.GetQuestTemplate().GoalDescription -- Set the goal text
	ScaleUpNodes() -- Start the scale-up animation for nodes
end
