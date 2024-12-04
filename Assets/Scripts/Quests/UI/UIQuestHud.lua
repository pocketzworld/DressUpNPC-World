--!Type(UI)

-- Importing necessary modules and types
local GM: GameManager = require("GameManager") -- GameManager for managing game state
local UIUtils: UIUtils = require("UIUtils") -- Utility functions for UI operations
local Types: Types = require("Types") -- Type definitions for various game elements
local QuestManager: QuestManager = require("QuestManager") -- Manages quests in the game
local TweenModule = require("TweenModule") -- Module for tween animations
local Tween = TweenModule.Tween -- Tween class for animations
local Easing = TweenModule.Easing -- Easing functions for animations

-- Type definition for a quest entry
type QuestEntry = {
	QuestInstance: Types.QuestInstance, -- The instance of the quest
	Entry: VisualElement, -- The visual element representing the quest
	Text: Label, -- The label displaying the quest text
	QuestImage: Image, -- The image associated with the quest
}

-- Type definition for completed quest display data
type CompleteQuestDisplayData = {
	QuestInstance: Types.QuestInstance, -- The completed quest instance
	NextQuestInstance: Types.QuestInstance, -- The next quest instance to display
}

-- UI elements bound to the script
--!Bind
local _content: VisualElement = nil -- The main content area for quests
--!Bind
local _backgroundImage: VisualElement = nil -- Background image for the quest UI
--!Bind
local _questText: Label = nil -- Label for displaying quest text

-- Serialized fields for configuration
--!SerializeField
local _delayToShowQuests: number = 1 -- Delay before showing quests
--!SerializeField
local _questCompleteSound: AudioShader = nil -- Sound played when a quest is completed
--!SerializeField
local _newQuestSound: AudioShader = nil -- Sound played when a new quest is available
--!SerializeField
local _delayAfterSlideOutToShowNew: number = 0.5 -- Delay after sliding out before showing new quests
--!SerializeField
local _questCompleteDelay: number = 2 -- Delay before processing the next quest after completion
--!SerializeField
local _slideAnimDuration: number = 0.25 -- Duration of slide animations
--!SerializeField
local _extraSlidePadding: number = 10 -- Extra padding for slide animations

-- Tables to hold quest entries and completed quests
local _questEntries: { [string]: QuestEntry } = {} -- Dictionary of current quest entries
local _completedQuestsQueue: { CompleteQuestDisplayData } = {} -- Queue for completed quests

-- Updates the visual representation of a quest entry based on its completion status
local function UpdateQuestEntryForCompletion(complete: boolean, entry: QuestEntry)
	local addedClass = complete and "entry-complete" or "entry-incomplete" -- Class to add based on completion
	local removedClass = complete and "entry-incomplete" or "entry-complete" -- Class to remove based on completion
	if complete then
		entry.Text.text = "Dress Up Complete!" -- Update text for completed quest
	end

	entry.QuestImage:SetDisplay(not complete) -- Hide the quest image if completed
	UIUtils.RemoveClass(entry.Entry, removedClass) -- Remove the old class
	UIUtils.AddClass(entry.Entry, addedClass) -- Add the new class
end

-- Handles the click event on a quest entry
local function OnQuestClicked(questEntry: QuestEntry)
	if questEntry.QuestInstance.QuestTemplate.GetRequirement().IsDressUpRequirement() then
		-- If the quest requires a dress-up task, pan the camera to the character
		local tasks: { NPCDressUpTaskController } = QuestManager.GetDressUpTaskControllers()
		for _, taskController in ipairs(tasks) do
			if taskController.GetQuestTemplate().Id == questEntry.QuestInstance.QuestTemplate.Id then
				GM.GetCameraLogic().PanToCharacter(taskController.GetCharacter()) -- Pan to the character
				break
			end
		end
	else
		-- For other quests, pan to the contest NPC
		GM.GetCameraLogic().PanToCharacter(GM.GetContestNPC())
	end
end

-- Creates a visual entry for a quest and returns the visual element
local function CreateQuestEntry(questInstance: Types.QuestInstance): VisualElement
	local entry = UIUtils.NewVisualElement(_content, { "quest-entry" }, false) -- Create a new visual element for the quest
	entry.pickingMode = PickingMode.Position -- Set picking mode for interaction
	local text = UIUtils.NewLabel(entry, { "quest-text" }, questInstance.QuestTemplate.QuestText) -- Create a label for quest text
	local questImage: Image = UIUtils.NewImage(entry, { "quest-image" }) -- Create an image for the quest

	-- Store the quest entry data
	local data: QuestEntry = { QuestInstance = questInstance, Entry = entry, Text = text, QuestImage = questImage }
	print(
		"Creating quest entry for "
			.. questInstance.QuestLineTemplate.Id
			.. " with text "
			.. questInstance.QuestTemplate.QuestText
	)
	_questEntries[questInstance.QuestLineTemplate.Id] = data -- Add the entry to the quest entries table

	-- Register a callback for when the quest entry is clicked
	entry:RegisterPressCallback(function()
		OnQuestClicked(data)
	end)
	return entry -- Return the created entry
end

-- Shows or hides the quest entries based on the boolean parameter
local function ShowEntries(show: boolean)
	local opacity = show and 1 or 0 -- Set opacity based on visibility
	_content.style.opacity = StyleFloat.new(opacity) -- Update the opacity of the content
	_content.pickingMode = show and PickingMode.Position or PickingMode.Ignore -- Set picking mode based on visibility
end

-- Displays the quest entries on the UI
local function ShowQuests()
	print("showing quests with entry count " .. #_questEntries) -- Log the number of quest entries
	ShowEntries(true) -- Show the entries

	if #_questEntries > 0 then
		Audio:PlaySoundGlobal(_newQuestSound, 1, 1, false) -- Play sound for new quests
	end

	-- Play slide-in animation for each quest entry
	for _, entry in pairs(_questEntries) do
		PlaySlideInAnim(entry.Entry)
	end
end

-- Sets up the UI to show quests by clearing previous entries and creating new ones
function SetupToShowQuests()
	table.clear(_questEntries) -- Clear existing quest entries
	local activeQuests = QuestManager.GetActiveQuests() -- Get the list of active quests
	for _, quest in ipairs(activeQuests) do
		if quest then
			CreateQuestEntry(quest) -- Create a visual entry for each active quest
		end
	end

	ShowEntries(false) -- Initially hide the entries
	Timer.After(_delayToShowQuests, ShowQuests) -- Show quests after a delay
end

-- Called when the client is initialized
function self.ClientAwake()
	SetupToShowQuests() -- Set up quests for display

	-- Connect events for UI opening and closing
	GM.UIManager.UIOpenedEvent:Connect(function(uiName: string)
		if uiName ~= GM.UIManager.UINames.QuestHud then
			ShowEntries(false) -- Hide entries if the Quest HUD is not opened
		end
	end)

	GM.UIManager.UIClosedEvent:Connect(function(uiName: string)
		local openCount = GM.UIManager.GetOpenUICount(GM.UIManager.UINames.QuestHud) -- Count open UI elements
		ShowEntries(openCount == 0) -- Show or hide entries based on open count
	end)

	-- Connect event for when a quest is completed
	QuestManager.QuestCompletedEvent:Connect(
		function(questInstance: Types.QuestInstance, nextQuestInstance: Types.QuestInstance)
			table.insert(
				_completedQuestsQueue,
				{ QuestInstance = questInstance, NextQuestInstance = nextQuestInstance } -- Queue completed quest data
			)
		end
	)

	-- Connect event for displaying completed quests
	QuestManager.QuestDisplayActionEvent:Connect(QueueCompletedQuestDisplay)
end

-- Queues the display of completed quests
function QueueCompletedQuestDisplay()
	ShowEntries(true) -- Show entries for completed quests
	--TODO: make a loop in case multiple quests complete at the same time
	local completeQuestData = table.remove(_completedQuestsQueue, 1) -- Get the first completed quest data
	if not completeQuestData then
		return -- Exit if there are no completed quests to display
	end
	local entry = _questEntries[completeQuestData.QuestInstance.QuestLineTemplate.Id] -- Get the corresponding quest entry
	if not entry then
		return -- Exit if the entry does not exist
	end

	Audio:PlaySoundGlobal(_questCompleteSound, 1, 1, false) -- Play sound for quest completion

	UpdateQuestEntryForCompletion(true, entry) -- Update the entry to show completion
	PlaySlideInAnim(entry.Entry, function() -- Play slide-in animation
		Timer.After(_questCompleteDelay, function() -- Delay before sliding out
			PlaySlideOutAnim(entry.Entry, function() -- Play slide-out animation
				Timer.After(_delayAfterSlideOutToShowNew, function() -- Delay before showing new quest
					UpdateQuestEntryForCompletion(false, entry) -- Reset the entry for the next quest
					if not completeQuestData.NextQuestInstance then
						return -- Exit if there is no next quest
					end
					entry.QuestInstance = completeQuestData.NextQuestInstance -- Update the quest instance
					entry.Text.text = completeQuestData.NextQuestInstance.QuestTemplate.QuestText -- Update the text for the new quest
					Audio:PlaySoundGlobal(_newQuestSound, 1, 1, false) -- Play sound for new quest
					PlaySlideInAnim(entry.Entry) -- Play slide-in animation for the new quest
				end)
			end)
		end)
	end)
end

-- Plays a slide-out animation for a given visual element
function PlaySlideOutAnim(content: VisualElement, onComplete: () -> () | nil)
	local startRight = _extraSlidePadding -- Starting position for the slide-out
	content.style.right = StyleLength.new(Length.new(startRight)) -- Set the initial position
	local myTween = Tween
		:new(function(value) -- onUpdate callback for the tween
			local right = GM.Utils.LerpNoClamp(startRight, -content.layout.width, value) -- Calculate the new position
			content.style.right = StyleLength.new(Length.new(right)) -- Update the position
		end)
		:FromTo(0, 1) -- Tween from 0 to 1
		:Easing(Easing.easeInBack) -- Use easing function for smooth animation
		:Duration(_slideAnimDuration) -- Set the duration of the animation
		:OnComplete(onComplete) -- Set the completion callback

	myTween:start() -- Start the tween animation
end

-- Plays a slide-in animation for a given visual element
function PlaySlideInAnim(content: VisualElement, onComplete: () -> () | nil)
	local startRight = -content.layout.width + _extraSlidePadding -- Starting position for the slide-in
	content.style.right = StyleLength.new(Length.new(startRight)) -- Set the initial position
	local myTween = Tween
		:new(function(value) -- onUpdate callback for the tween
			local right = GM.Utils.LerpNoClamp(startRight, _extraSlidePadding, value) -- Calculate the new position
			content.style.right = StyleLength.new(Length.new(right)) -- Update the position
		end)
		:FromTo(0, 1) -- Tween from 0 to 1
		:Easing(Easing.easeOutBack) -- Use easing function for smooth animation
		:Duration(_slideAnimDuration) -- Set the duration of the animation
		:OnComplete(onComplete) -- Set the completion callback

	myTween:start() -- Start the tween animation
end
