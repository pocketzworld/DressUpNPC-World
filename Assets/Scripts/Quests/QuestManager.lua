--!Type(Module)

-- Import necessary modules
local GM = require("GameManager") -- GameManager module for game-related functionalities
local Types: Types = require("Types") -- Types module for type definitions
local SaveManager = require("SaveManager") -- SaveManager module for handling save data

-- Define a type for completed quest data
type CompletedQuestData = {
	QuestInstance: Types.QuestInstance, -- Instance of the quest that was completed
	Rewards: { Types.GameItemAmount }, -- Rewards received for completing the quest
}

--!SerializeField
local _dressUpTasks: { NPCDressUpTaskController } = nil -- Table to hold dress-up task controllers

-- Define events for quest-related actions
QuestsLoadedEvent = Event.new("QuestsLoadedEvent") -- Event triggered when quests are loaded
QuestCompletedEvent = Event.new("QuestCompletedEvent") -- Event triggered when a quest is completed
QuestDisplayActionEvent = Event.new("QuestDisplayActionEvent") -- Event for displaying quest actions

-- Tables to hold active quests and quests ready for display
local _activeQuests: { Types.QuestInstance } = {} -- Active quests currently in progress
local _readyForDisplayQuests: { CompletedQuestData } = {} -- Quests that are completed and ready to show rewards

-- Function to get the dress-up task controllers
function GetDressUpTaskControllers(): { NPCDressUpTaskController }
	return _dressUpTasks -- Return the dress-up task controllers
end

-- Function to add a quest instance to the active quests
local function AddQuestInstance(quest: QuestTemplate, questLine: QuestLineTemplate): Types.QuestInstance
	print("Adding quest instance for " .. quest.Id) -- Log the addition of the quest instance
	local questInstance = Types.NewQuestInstance(quest, questLine, 0) :: Types.QuestInstance -- Create a new quest instance
	table.insert(_activeQuests, questInstance) -- Add the quest instance to the active quests
	return questInstance -- Return the created quest instance
end

-- Function to get the quest line associated with a specific quest
local function GetQuestLineForQuest(quest: QuestTemplate): QuestLineTemplate
	local settings = GM.GetGameSettings() -- Get game settings
	local questLines = settings.GetAllQuestLines() -- Retrieve all quest lines
	for _, questLine in ipairs(questLines) do -- Iterate through each quest line
		local quests = questLine.GetQuests() -- Get quests in the current quest line
		for _, q in ipairs(quests) do -- Iterate through each quest
			if q.Id == quest.Id then -- Check if the quest ID matches
				return questLine -- Return the matching quest line
			end
		end
	end
	return nil -- Return nil if no matching quest line is found
end

-- Function to get the next quest in a quest line
local function GetNextQuestInQuestLine(quest: QuestTemplate, questLine: QuestLineTemplate): QuestTemplate
	local quests = questLine.GetQuests() -- Get quests in the quest line
	for i, q in ipairs(quests) do -- Iterate through each quest
		if q.Id == quest.Id then -- Check if the quest ID matches
			if i < #quests then -- If there is a next quest
				return quests[i + 1] -- Return the next quest
			end
			break -- Exit the loop if no next quest exists
		end
	end
	return nil -- Return nil if no next quest is found
end

-- Function to check if a quest is complete
function IsQuestComplete(questId: string): boolean
	local questSaveData = GM.SaveManager.GetQuestData(questId) -- Retrieve saved data for the quest
	if not questSaveData then -- If no save data exists
		return false -- Quest is not complete
	end

	local questTemplate = GM.GetGameSettings().GetQuestTemplate(questId) -- Get the quest template
	if not questTemplate then -- If no quest template exists
		return false -- Quest is not complete
	end
	return questSaveData.Progress >= questTemplate.Target -- Return true if progress meets or exceeds target
end

-- Function to get all active quests
function GetActiveQuests(): { Types.QuestInstance }
	return _activeQuests -- Return the list of active quests
end

-- Function to load quest instances from saved data
function LoadQuestInstances()
	table.clear(_activeQuests) -- Clear the active quests table
	table.clear(_readyForDisplayQuests) -- Clear the ready for display quests table

	-- Create quest instances only for the current quests in each quest line
	local settings = GM.GetGameSettings() -- Get game settings
	local questLines = settings.GetAllQuestLines() -- Retrieve all quest lines
	for _, questline in ipairs(questLines) do -- Iterate through each quest line
		local quests = questline.GetQuests() -- Get quests in the current quest line
		for _, quest in ipairs(quests) do -- Iterate through each quest
			local questSaveData = GM.SaveManager.GetQuestData(quest.Id) -- Get saved data for the quest
			if not questSaveData or questSaveData.Progress < quest.Target then -- If no save data or progress is less than target
				AddQuestInstance(quest, questline) -- Add the quest instance
				break -- Exit the loop after adding the quest
			end
		end
	end

	QuestsLoadedEvent:Fire() -- Fire the event indicating quests have been loaded

	local uiManager: UIManager = GM.UIManager -- Get the UI manager
	if not uiManager.IsUIOpen(uiManager.UINames.QuestHud) then -- Check if the quest HUD is not open
		uiManager.OpenQuestHudUI(uiManager.UINames.QuestHud) -- Open the quest HUD UI
	end
end

-- Function called when the client awakens
function self.ClientAwake()
	GM.SaveDataLoadedEvent:Connect(function() -- Connect to the event when save data is loaded
		LoadQuestInstances() -- Load quest instances
	end)

	SaveManager.ResetQuestsEvent:Connect(function() -- Connect to the event when quests are reset
		LoadQuestInstances() -- Reload quest instances
		local questHUD = GM.UIManager.GetUI(GM.UIManager.UINames.QuestHud) -- Get the quest HUD
		questHUD.SetupToShowQuests() -- Setup the HUD to show quests
	end)
end

-- Function to grant rewards for completing a quest
local function GrantQuestRewards(questInstance: Types.QuestInstance): { Types.GameItemAmount }
	local loot = questInstance.QuestTemplate.LootContainer -- Get the loot container from the quest template
	if not loot then -- If no loot exists
		return {} -- Return an empty table
	end
	GM.RewardLoot(loot, true, false, nil) -- Reward the loot
	return rewards -- Return the rewards
end

-- Function to check if a quest template is active
function IsQuestTemplateActive(questTemplate: QuestTemplate): boolean
	if not questTemplate then -- If no quest template is provided
		return false -- Return false
	end
	return IsQuestActive(questTemplate.Id) -- Check if the quest is active
end

-- Function to check if a specific quest is active
function IsQuestActive(questId: string): boolean
	for _, quest in ipairs(_activeQuests) do -- Iterate through active quests
		if quest.QuestTemplate.Id == questId then -- Check if the quest ID matches
			return true -- Return true if the quest is active
		end
	end
	return false -- Return false if the quest is not active
end

-- Function to find the next active quest in a quest line
local function FindNextActiveQuestInQuestline(questInstance: Types.QuestInstance): Types.QuestInstance
	local nextQuest = GetNextQuestInQuestLine(questInstance.QuestTemplate, questInstance.QuestLineTemplate) -- Get the next quest
	if nextQuest then -- If a next quest exists
		return AddQuestInstance(nextQuest, questInstance.QuestLineTemplate) -- Add and return the next quest instance
	else
		print("No more quests in the quest line for " .. questInstance.QuestTemplate.Id) -- Log if no more quests exist
	end
	return nil -- Return nil if no next quest is found
end

-- Function to notify events related to quests
function NotifyEventForQuests(data: any, displayRewards: boolean, savePlayerData: boolean)
	-- Add progress to active quests and check if they are completed
	for _, questInstance in ipairs(_activeQuests) do -- Iterate through active quests
		local quest = questInstance.QuestTemplate -- Get the quest template
		local success, progress = quest.MeetsReqs(data) -- Check if the quest requirements are met
		if success then -- If requirements are met
			print("Quest " .. quest.Id .. " has been progressed by " .. progress) -- Log the progress
			questInstance.Progress = questInstance.Progress + progress -- Update the quest progress
			GM.SaveManager.ProgressOnQuest(quest.Id, questInstance.Progress) -- Save the progress
			if questInstance:IsCompleted() then -- If the quest is completed
				local rewards = GrantQuestRewards(questInstance) -- Grant rewards for the completed quest
				table.insert(_readyForDisplayQuests, { QuestInstance = questInstance, Rewards = rewards }) -- Add to display list
			end
		end
	end

	-- Remove completed quests from the active quest list and add the next quest in the quest line
	for _, questInstanceData in ipairs(_readyForDisplayQuests) do -- Iterate through completed quests
		for i, quest in ipairs(_activeQuests) do -- Iterate through active quests
			if quest.QuestTemplate.Id == questInstanceData.QuestInstance.QuestTemplate.Id then -- Check for matching quest
				-- Find next quest in the quest line
				table.remove(_activeQuests, i) -- Remove the completed quest from active quests
				local nextQuestInstance = FindNextActiveQuestInQuestline(questInstanceData.QuestInstance) -- Find the next quest
				QuestCompletedEvent:Fire(questInstanceData.QuestInstance, nextQuestInstance) -- Fire the quest completed event
				break -- Exit the loop after processing the quest
			end
		end
	end

	if displayRewards then -- If rewards should be displayed
		DisplayRewardsForCompletedQuests(nil) -- Display rewards for completed quests
	end

	if savePlayerData then -- If player data should be saved
		GM.SaveManager.SavePlayerData() -- Save player data
	end
end

-- Function to display rewards for completed quests
function DisplayRewardsForCompletedQuests(onCompleteCallback)
	local uiManager: UIManager = GM.UIManager -- Get the UI manager

	if #_readyForDisplayQuests == 0 then -- If there are no completed quests to display
		if onCompleteCallback then -- If a callback is provided
			onCompleteCallback() -- Call the callback
		end
		return -- Exit the function
	end

	local completedQuestData = _readyForDisplayQuests[1] -- Get the first completed quest data
	table.remove(_readyForDisplayQuests, 1) -- Remove it from the list
	if #completedQuestData.Rewards == 0 then -- If there are no rewards
		DisplayRewardsForCompletedQuests(onCompleteCallback) -- Recursively call to check for more quests
		return -- Exit the function
	end

	local ui = uiManager.OpenRewardUI() -- Open the reward UI
	ui.Init(completedQuestData.Rewards, function() -- Initialize the UI with rewards
		if #_readyForDisplayQuests > 0 then -- If there are more completed quests
			DisplayRewardsForCompletedQuests(onCompleteCallback) -- Recursively call to display more rewards
		else
			if onCompleteCallback then -- If a callback is provided
				onCompleteCallback() -- Call the callback
			end
		end
	end)
end
