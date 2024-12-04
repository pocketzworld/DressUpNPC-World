--!Type(UI)

-- Importing required modules
local GM: GameManager = require("GameManager") -- GameManager module for managing game state and items
local UIUtils: UIUtils = require("UIUtils") -- UIUtils module for utility functions related to UI
local TweenModule = require("TweenModule") -- TweenModule for animations and transitions
local Tween = TweenModule.Tween -- Tween class for creating tweens
local Easing = TweenModule.Easing -- Easing class for easing functions in animations

--!Bind
local _content: VisualElement = nil -- UI element that will contain the rewards
--!Bind
local _collectButton: VisualElement = nil -- Button for collecting rewards

--!SerializeField
local _rewardsOpenedSound: AudioShader = nil -- Sound to play when rewards are opened

-- Function to get the root visual element of the UI
function GetRoot(): VisualElement
	return _content -- Returns the content element
end

-- Function to create a visual entry for a reward
-- @param reward: GM.GameItemAmount - The reward item to be displayed
local function CreateRewardEntry(reward: GM.GameItemAmount)
	local rewardEntry = VisualElement.new() -- Create a new visual element for the reward entry
	rewardEntry:AddToClassList("rewardentry") -- Add CSS class for styling

	local rewardIcon = UIImage.new() -- Create a new image element for the reward icon
	rewardIcon:AddToClassList("rewardicon") -- Add CSS class for styling
	-- Check if the reward has a display image, otherwise load a default preview
	if reward.Template.DisplayData and reward.Template.DisplayData.ImageSprite then
		rewardIcon.image = reward.Template.DisplayData.ImageSprite.texture -- Set the icon image
	else
		rewardIcon:LoadItemPreview("avatar_item", reward.Template.ItemId) -- Load a default item preview
	end
	rewardEntry:Add(rewardIcon) -- Add the icon to the reward entry

	local amountLabel = Label.new() -- Create a label for the amount of the reward
	amountLabel:AddToClassList("amountLabel") -- Add CSS class for styling
	amountLabel.text = "x" .. reward.Amount -- Set the text to show the amount
	rewardEntry:Add(amountLabel) -- Add the amount label to the reward entry

	-- Create a name label using UIUtils and add it to the reward entry
	local nameLabel = UIUtils.NewLabel(rewardEntry, { "reward-name" }, reward.Template.DisplayData.Name)

	_content:Add(rewardEntry) -- Add the completed reward entry to the content
end

-- Function to initialize the reward UI with a list of rewards
-- @param rewards: {GM.GameItemAmount} - List of rewards to display
-- @param onCompleteCallback: function - Callback function to call when rewards are collected
function Init(rewards: { GM.GameItemAmount }, onCompleteCallback)
	-- Iterate through each reward and create its entry
	for _, reward: GM.GameItemAmount in ipairs(rewards) do
		CreateRewardEntry(reward) -- Create a visual entry for each reward
	end

	-- Register a callback for when the collect button is pressed
	_collectButton:RegisterPressCallback(function()
		if onCompleteCallback then
			onCompleteCallback() -- Call the provided callback if it exists
		end
		GM.UIManager.CloseUI(GM.UIManager.UINames.RewardUI) -- Close the reward UI
	end)

	-- Play the rewards opened sound if it is set
	if _rewardsOpenedSound then
		Audio:PlaySoundGlobal(_rewardsOpenedSound, 1, 1, false) -- Play the sound globally
	end
end
