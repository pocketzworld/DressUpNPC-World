--!Type(Client)

-- Define a type for clothing data, which includes an ID and a color.
export type ClothingData = {
	id: string,
	color: number,
}

-- Import necessary modules and types for managing game state, dialogs, quests, player characters, contests, and saving/loading data.
local GM: GameManager = require("GameManager")
local DialogManager: DialogManager = require("DialogManager")
local QuestManager: QuestManager = require("QuestManager")
local PlayerCharacterController: PlayerCharacterController = require("PlayerCharacterController")
local ContestManager: ContestManager = require("ContestManager")
local SaveManager: SaveManager = require("SaveManager")
local Types: Types = require("Types")
local UIManager: UIManager = require("UIManager")

-- Define a type for the dress-up state, which includes various properties related to the dress-up task.
export type DressUpState = {
	Active: boolean,
	Task: DressUpTask,
	OriginalOutfit: CharacterOutfit,
	AddedClothing: { ClothingData },
	Choices: { number },
}

-------------------------------------------------------------------------------
-- Properties
-------------------------------------------------------------------------------

-- Serialized fields for storing various game data related to dress-up tasks, quests, outfits, and UI elements.
--!SerializeField
local _dressUpTasks: { DressUpTask } = nil
--!SerializeField
local _questTemplates: { QuestTemplate } = nil
--!SerializeField
local _outfits: { CharacterOutfit } = nil
--!SerializeField
local _nodeAnchors: { Transform } = nil
--!SerializeField
local _questObject: GameObject = nil
--!SerializeField
local _hideObjectsInCutscene: { GameObject } = nil
--!SerializeField
local _resetDataNPC: boolean = false
--!SerializeField
local _autoCompleteForTesting: boolean = false

-- Local variables to hold the current NPC character, dress-up state, UI, and index for the dress-up task.
local _npcCharacter: Character = nil
local _dressUpState: DressUpState = nil
local _dressUpClosetUI: UIDressUpCloset = nil
local _dressUpIndex: number = 1

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

------- Private -------

-- Create an empty dress-up state with default values.
local function CreateEmptyDressUpState(): DressUpState
	return {
		Active = false,
		Task = nil,
		OriginalOutfit = nil,
		AddedClothing = {},
		Choices = {},
	}
end

-- Retrieve the current outfit based on the dress-up index.
local function GetOutfit(): CharacterOutfit
	return _outfits[_dressUpIndex]
end

-- Get the current quest template based on the dress-up index.
local function GetCurrentQuestTemplate(): QuestTemplate
	-- Go through the quests and see which ones are completed
	return _questTemplates[_dressUpIndex]
end

-- Update the dress-up index based on the player's completed quests.
local function UpdateDressUpIndex()
	local playerData: SaveManager.PlayerData = SaveManager.GetClientPlayerData()
	for i = 1, #_questTemplates do
		local questTemplate = _questTemplates[i]
		local val = GM.Utils.FindInTable(playerData.QuestList, function(questContainer)
			return questContainer.Id == questTemplate.Id
		end)
		if not val then
			_dressUpIndex = i
			return
		end
	end
	_dressUpIndex = #_dressUpTasks
end

-- Get the current dress-up task based on the dress-up index.
local function GetCurrentDressUpTask(): DressUpTask
	return _dressUpTasks[_dressUpIndex]
end

-- Reset the dress-up state to its initial values.
local function ResetDressUpState()
	_dressUpState.Active = false
	table.clear(_dressUpState.AddedClothing)
	table.clear(_dressUpState.Choices)
	local outfitCount = GetCurrentDressUpTask().OutfitCount
	for i = 1, outfitCount do
		table.insert(_dressUpState.AddedClothing, i, { id = "", color = -1 })
		table.insert(_dressUpState.Choices, i, -1)
	end
end

-- Apply the specified outfit to the NPC character.
local function ApplyOutfitToNPC(outfit: CharacterOutfit)
	_npcCharacter:SetOutfit(outfit)
end

-- Initialize the dress-up data by creating a new state and resetting it.
local function InitDressUpData()
	_dressUpState = CreateEmptyDressUpState()
	UpdateDressUpIndex()
	ResetDressUpState()
	_dressUpState.Task = GetCurrentDressUpTask()
	_dressUpState.OriginalOutfit = GetOutfit()

	if _npcCharacter.outfits[1] ~= _dressUpState.OriginalOutfit then
		ApplyOutfitToNPC(_dressUpState.OriginalOutfit)
	end

	CheckToEnableQuestObject()
end

-- Find the index of a clothing ID in a list of clothing data.
local function FindClothingIdInList(clothingId: string, clothingList: { ClothingData }): number
	for i, clothing in ipairs(clothingList) do
		if clothing.id == clothingId then
			return i
		end
	end
	return -1
end

-- Show or hide the quest object based on the provided boolean value.
local function ShowQuestObject(show: boolean)
	if _questObject then
		_questObject:SetActive(show)
	end
end

-- Refresh the dress-up UI to reflect the current state.
local function RefreshDressUpUI()
	local uiManager: UIManager = GM.UIManager
	local dressupUI = uiManager.GetUI(uiManager.UINames.DressUpUI)
	dressupUI.Refresh(_dressUpState)
end

-- Show or hide the dress-up UI based on the provided boolean value.
local function ShowDressUpUI(show: boolean)
	local uiManager: UIManager = GM.UIManager
	local dressupUI = uiManager.GetUI(uiManager.UINames.DressUpUI)
	dressupUI.Show(show)
end

-- Create a new outfit based on the current choices and any extra clothing provided.
local function CreateOutfitFromChoices(extraClothing: { ClothingData }): CharacterOutfit
	local clothingData = GM.OutfitUtils.SerializeOutfitToData(_dressUpState.OriginalOutfit)

	-- If added clothing exists, remove clothing from the same index
	for i, clothing in ipairs(_dressUpState.AddedClothing) do
		if not GM.Utils.IsStringNullOrEmpty(clothing.id) then
			local foundIndex = 1
			local removedClothingList = GetCurrentDressUpTask().GetDressUpData(i).RemovedClothing
			for i, removedClothing in ipairs(removedClothingList) do
				if not GM.Utils.IsStringNullOrEmpty(removedClothing) then
					local index = FindClothingIdInList(removedClothing, clothingData)
					if index ~= -1 then
						table.remove(clothingData, index)

						if foundIndex == 1 then
							foundIndex = i
						end
					else
						print("Could not find clothing to remove: " .. removedClothing)
					end
				end
			end
			table.insert(clothingData, foundIndex, clothing)
		end
	end

	-- Add any extra clothing to the outfit data
	for _, clothing in ipairs(extraClothing) do
		table.insert(clothingData, clothing)
	end

	local newOutfit = GM.OutfitUtils.DeserializeClothingDataToOutfit(clothingData)
	return newOutfit
end

-- Handle the completion of the closet outfit selection.
function OnClosetOutfitComplete(outfit: CharacterOutfit)
	GM.UIManager.CloseUI(GM.UIManager.UINames.DressUpCloset)
	ApplyOutfitToNPC(outfit)
	SubmitDressUp()
end

-- Handle the cancellation of the closet selection.
local function OnClosetCanceled()
	GM.UIManager.CloseUI(GM.UIManager.UINames.DressUpCloset)
	GM.EnterCutsceneDisplay(false)
	ApplyOutfitToNPC(_dressUpState.OriginalOutfit)
	InitDressUpData()
end

-- Handle the completion of the start dialog for the dress-up task.
local function OnStartDialogComplete()
	local uiManager: UIManager = GM.UIManager
	_dressUpState.Active = true

	if _autoCompleteForTesting then
		SubmitDressUp()
	end

	local dressUpTask = GetCurrentDressUpTask()
	if dressUpTask.IsClosetTask then
		local types = dressUpTask.TypeTargets
		local acquiredClothing: { CharacterClothing } = {}
		-- Add collection clothes to acquired clothing
		local collection: ClothingCollection = dressUpTask.ClosetClothingCollection
		if collection then
			for _, clothing in pairs(collection.clothing) do
				table.insert(acquiredClothing, clothing)
			end
		end

		_dressUpClosetUI = uiManager.OpenDressUpClosetUI()
		_dressUpClosetUI.Init(OnClosetCanceled)
		local questString = GetCurrentQuestTemplate().GoalDescription
		if GM.UseOldCloset() then
			GM.OpenClosetOld(questString, OnClosetOutfitComplete, collection, false, _npcCharacter.outfits[1])
		else
			GM.OpenCloset(questString, OnClosetOutfitComplete, acquiredClothing, false, _npcCharacter.outfits[1])
		end
	else
		local ui = uiManager.OpenDressUpUI(uiManager.UINames.DressUpUI)
		ui.Init(self)

		RefreshDressUpUI()
	end
end

-- Setup the environment for the dress-up process, including cutscene display and object visibility.
local function SetupForDressUp(dressUp: boolean)
	GM.EnterCutsceneDisplay(dressUp, _npcCharacter.transform.position, -_npcCharacter.transform.forward)

	for i, obj in ipairs(_hideObjectsInCutscene) do
		GM.Utils.SetGameObjectActive(obj, not dressUp)
	end
end

-- Play the dialog for a quest that has already been completed.
local function PlayQuestAlreadyCompletedDialog()
	DialogManager.StartDialogWithOverride(
		GM.GetGameSettings().QuestCompleteDialog,
		GetCurrentDressUpTask().StartDialog,
		_npcCharacter,
		nil
	)
end

-- Play the dialog for a quest that is not unlocked yet.
local function PlayQuestNotUnlockedDialog()
	DialogManager.StartDialogWithOverride(
		GM.Settings.GetQuestNotUnlockedDialog(),
		GetCurrentDressUpTask().StartDialog,
		_npcCharacter,
		nil
	)
end

-- Handle the completion of the reset dialog.
local function OnResetDialogComplete()
	UIManager.OpenGenericPopupPurchaseUI("Reset your progress?", "Reset", function()
		GM.SaveManager.ResetDressUpData(function()
			QuestManager.LoadQuestInstances()
		end)
	end)
end

-- Handle the event when the NPC is tapped.
local function OnNPCTapped()
	if _dressUpState.Active then
		return
	end

	if _resetDataNPC and GM.HasCompletedAllQuests() then
		DialogManager.StartDialog(GM.Settings.GetResetDialog(), _npcCharacter, OnResetDialogComplete)
		return
	end

	if not QuestManager.IsQuestActive(GetCurrentQuestTemplate().Id) and not GM.DebugQuests then
		PlayQuestNotUnlockedDialog()
		return
	end

	ShowQuestObject(false)
	_dressUpState.Active = true
	SetupForDressUp(true)

	DialogManager.StartDialog(GetCurrentDressUpTask().StartDialog, _npcCharacter, OnStartDialogComplete)

	GM.OnDressUpEvent:Fire()
end

-- Get extra clothing items for nodes that have been filled in.
local function GetExtraClothingForFilledInNodes(): { ClothingData }
	local extraClothing = {}
	for i, clothing in ipairs(_dressUpState.AddedClothing) do
		if not GM.Utils.IsStringNullOrEmpty(clothing.id) then
			local extraClothingList = GetCurrentDressUpTask().GetDressUpData(i).ExtraClothing
			if #extraClothingList == 0 then
				continue
			end

			local choice = _dressUpState.Choices[i]
			if choice == -1 then
				continue
			end
			local clothingId = extraClothingList[choice]
			print("inserting extra " .. clothingId)
			table.insert(extraClothing, { id = clothingId, color = clothing.color })
		end
	end
	return extraClothing
end

-- Check if the quest object should be enabled based on the current quest state.
function CheckToEnableQuestObject()
	ShowQuestObject(
		QuestManager.IsQuestTemplateActive(GetCurrentQuestTemplate()) or (_resetDataNPC and GM.HasCompletedAllQuests())
	)
end

-- Handle the event when a quest is completed.
local function OnQuestCompleted(completedQuest: Types.QuestInstance, nextQuest: Types.QuestInstance)
	CheckToEnableQuestObject()
	if nextQuest == nil then
		return
	end
	for i = 1, #_questTemplates do
		if _questTemplates[i].Id == nextQuest.QuestTemplate.Id then
			print("Setting up for quest: " .. nextQuest.QuestTemplate.Id)
			UpdateDressUpIndex()
			InitDressUpData()
			break
		end
	end
end

-- Register events related to quest completion.
local function RegisterQuestEvents()
	QuestManager.QuestCompletedEvent:Connect(OnQuestCompleted)
end

-- Initialize the client when it is awakened.
function self:ClientAwake()
	local tapHandler = self.gameObject:GetComponentInChildren(TapHandler, true)
	tapHandler.Tapped:Connect(OnNPCTapped)

	_npcCharacter = self.gameObject:GetComponentInChildren(Character, true)
	ShowQuestObject(false)

	RegisterQuestEvents()

	GM.SaveDataLoadedEvent:Connect(InitDressUpData)

	SaveManager.ResetQuestsEvent:Connect(function()
		InitDressUpData()
	end)
end

------- Public -------

-- Get the current dress-up state.
function GetDressUpState(): DressUpState
	return _dressUpState
end

-- Get the current dress-up task.
function GetDressUpTask(): DressUpTask
	return GetCurrentDressUpTask()
end

-- Get the current quest template.
function GetQuestTemplate(): QuestTemplate
	return GetCurrentQuestTemplate()
end

-- Get the NPC character.
function GetCharacter(): Character
	return _npcCharacter
end

-- Get the node anchors for the dress-up task.
function GetNodeAnchors(): { Transform }
	return _nodeAnchors
end

-- Count the number of filled-in choices in the dress-up state.
function GetFilledInChoicesCount(): number
	local count = 0
	for i, choice in ipairs(_dressUpState.Choices) do
		if choice ~= -1 then
			count = count + 1
		end
	end
	return count
end

-- Handle the event when a node is clicked.
function OnNodeClicked(nodeData: DressUpNode)
	local uiManager: UIManager = GM.UIManager
	if uiManager.IsUIOpen(uiManager.UINames.ClothingChoicePopup) then
		return nil
	end
	-- Open the clothing choice popup UI.
	local popup: UIOutfitChoicePopup = uiManager.OpenClothingChoicePopupUI(uiManager.UINames.ClothingChoicePopup)
	popup.Init(self, nodeData)

	ShowDressUpUI(false)
end

-- Handle the confirmation of clothing choice.
function OnClothingChoiceConfirmed()
	ShowDressUpUI(true)
	RefreshDressUpUI()
end

-- Preview the clothing choice based on the selected node data and index.
function PreviewClothingChoice(nodeData: DressUpNode, index: number)
	local dressUpTask = GetCurrentDressUpTask()
	local nodeIndex = dressUpTask.GetIndexOfData(nodeData)
	if _dressUpState.Choices[nodeIndex] == index then
		_dressUpState.Choices[nodeIndex] = -1
		_dressUpState.AddedClothing[nodeIndex] = { id = "", color = -1 }
	else
		local characterClothing = dressUpTask.GetDressUpData(nodeIndex).ClothingChoices.clothing[index]
		_dressUpState.AddedClothing[nodeIndex] = { id = characterClothing.id, color = characterClothing.color }
		_dressUpState.Choices[nodeIndex] = index
	end

	local extraClothing = GetExtraClothingForFilledInNodes()
	ApplyOutfitToNPC(CreateOutfitFromChoices(extraClothing))
end

-- Cleanup the dress-up state and notify quest manager.
local function Cleanup()
	ResetDressUpState()
	QuestManager.QuestDisplayActionEvent:Fire()
end

-- Handle the completion of the end dialog.
local function OnEndDialogComplete(success: boolean)
	SetupForDressUp(false)

	if success then
		local dressUpTask = GetCurrentDressUpTask()
		GM.SaveManager.CompleteDressUpRequest(dressUpTask.Id, function(response: SaveManager.CompleteDressUpResponse)
			QuestManager.NotifyEventForQuests({ Id = dressUpTask.Id }, true, true)

			if response.Rewards then
				local ui = GM.UIManager.OpenRewardUI()
				local rewards = GM.ConvertRewardSaveDataToGameItemAmount(response.Rewards)
				ui.Init(rewards, Cleanup)
			end
		end)
	else
		ApplyOutfitToNPC(_dressUpState.OriginalOutfit)
		CheckToEnableQuestObject()
		Cleanup()
	end
end

-- Submit the dress-up choices and handle the dialog flow.
function SubmitDressUp()
	-- Close the dress-up UI
	local uiManager: UIManager = GM.UIManager
	uiManager.CloseUI(uiManager.UINames.DressUpUI)

	local dressUpTask = GetCurrentDressUpTask()
	local percentCorrect = dressUpTask.GetPercentOfBestChoicesCorrect(_dressUpState.Choices)
	local success = percentCorrect >= GM.Settings.GetPercentChoicesCorrectToSucceed()
	local dialog = dressUpTask.EndSuccessDialog
	if not success then
		dialog = dressUpTask.EndFailDialog
	else
		Audio:PlaySoundGlobal(GM.Settings.GetDressUpSuccessSound(), 1, 1, false)
	end

	DialogManager.StartDialogWithOverride(dialog, dressUpTask.StartDialog, _npcCharacter, function()
		OnEndDialogComplete(success)
	end)
end
