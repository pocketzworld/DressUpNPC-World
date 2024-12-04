--!Type(Module)

-------------------------------------------------------------------------------
-- Importing Required Modules
-------------------------------------------------------------------------------
OutfitUtils = require("OutfitUtils") -- Utility functions for outfits
UIManager = require("UIManager") -- Manages UI elements
SaveManager = require("SaveManager") -- Handles saving and loading game data
LootManager = require("LootManager") -- Manages loot and rewards
PlayerCharacterController = require("PlayerCharacterController") -- Controls player character actions
Utils = require("Utils") -- General utility functions
PetController = require("PetCharacterController") -- Manages pet-related functionalities
Types = require("Types") -- Contains various type definitions

-------------------------------------------------------------------------------
-- Serialized Fields
-------------------------------------------------------------------------------
--!SerializeField
local _gameSettings: GameSettings = nil -- Game settings configuration
--!SerializeField
local _chatDispatcher: ClientChatDispatcher = nil -- Manages chat messages
--!SerializeField
local _mainUI: UIMain = nil -- Main user interface
--!SerializeField
local _contestManager: ContestManager = nil -- Manages contest-related functionalities
--!SerializeField
local _contestNPC: Character = nil -- Non-player character for contests
--!SerializeField
local _unlockContestsAfterQuest: QuestTemplate = nil -- Quest that unlocks contests
--!SerializeField
local _contestQuest: QuestTemplate = nil -- Quest related to contests
--!SerializeField
local _finalQuest: QuestTemplate = nil -- Final quest in the game
--!SerializeField
local _mainMusic: AudioShader = nil -- Main background music
--!SerializeField
local _additionalIncludedFiles: { Object } = nil -- Additional files included in the module

--!Header("Camera Settings")
--!SerializeField
local _dressUpCameraSettings: CameraCutsceneSettings = nil -- Camera settings for dress-up cutscenes
--!SerializeField
local _defaultCameraSettings: CameraCutsceneSettings = nil -- Default camera settings
--!SerializeField
local _mainCamera: Camera = nil -- Main camera used in the game

--!SerializeField
local _closetDevMode: boolean = false -- Developer mode for the closet feature
--!SerializeField
local _useOldCloset: boolean = false -- Flag to use the old closet system
--!SerializeField
local _testSendQuestsOutfitsToContest: boolean = false -- Test flag for sending outfits to contests
--!SerializeField
local _testAddDebugPlayersForContest: boolean = false -- Test flag for adding debug players

local _cameraLogic: DressUpCamera = nil -- Logic for controlling the dress-up camera
local _inCutscene: boolean = false -- Flag indicating if a cutscene is active
local _allPlayers: { CharacterModel } = {} -- List of all player character models

DebugQuests = false -- Debug flag for quests

-- Event declarations for various game events
OnDressUpEvent = Event.new("OnDressUpEvent")
OnDressUpEventComplete = Event.new("OnDressUpEventComplete")
ChatMessageEvent = Event.new("ChatMessageEvent")
SaveDataLoadedEvent = Event.new("SaveDataLoadedEvent")

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

-- Returns the main camera
function GetCamera(): Camera
	return _mainCamera
end
MainCamera = GetCamera() -- Assigns the main camera to a global variable

-- Returns the camera logic
function GetCameraLogic(): DressUpCamera
	return _cameraLogic
end

-- Returns the main UI
function GetMainUI(): UIMain
	return _mainUI
end
MainUI = GetMainUI() -- Assigns the main UI to a global variable

-- Returns the game settings
function GetGameSettings(): GameSettings
	return _gameSettings
end
Settings = GetGameSettings() -- Assigns game settings to a global variable

-- Returns the contest NPC
function GetContestNPC(): Character
	return _contestNPC
end

-- Checks if contests are unlocked based on quest progress
function AreContestsUnlocked(): boolean
	if DebugQuests then
		return true -- If in debug mode, contests are always unlocked
	end

	local contestQuestSaveData: SaveManager.QuestSaveData = SaveManager.GetQuestData(_contestQuest.Id)
	if contestQuestSaveData and contestQuestSaveData.Progress >= _contestQuest.Target then
		return true -- Contest quest is completed
	end

	local questSaveData: SaveManager.QuestSaveData = SaveManager.GetQuestData(_unlockContestsAfterQuest.Id)
	return questSaveData ~= nil and questSaveData.Progress >= _unlockContestsAfterQuest.Target -- Check if the unlocking quest is completed
end

-- Checks if all quests have been completed
function HasCompletedAllQuests(): boolean
	local questSaveData: SaveManager.QuestSaveData = SaveManager.GetQuestData(_finalQuest.Id)
	return questSaveData ~= nil and questSaveData.Progress >= _unlockContestsAfterQuest.Target -- Check if the final quest is completed
end

-- Resets all quests
local function ResetQuests()
	SaveManager.RequestRestartQuests() -- Requests a restart of quests
end

-- Callback function when player data is loaded
local function OnPlayerDataLoaded(playerData: PlayerData)
	Utils.PrintTable(playerData) -- Print player data for debugging

	SaveDataLoadedEvent:Fire() -- Fire the save data loaded event

	if not playerData.SeenIntro then -- Check if the player has seen the intro
		Timer.After(0.5, function() -- Delay opening the welcome popup
			UIManager.OpenWelcomePopupUI() -- Open the welcome popup UI
			SaveManager.ClientSeenIntro() -- Mark intro as seen
		end)
	else
		local completedQuests = HasCompletedAllQuests() -- Check if all quests are completed
		if playerData.RepeatCount == 0 then -- If this is the first time playing
			if completedQuests then
				print("resetting quests request") -- Log quest reset
				ResetQuests() -- Reset quests
			else
				SaveManager.MarkNoReset() -- Mark that quests should not be reset
			end
		end
	end
end

-- Rewards the player with loot from a loot container
function RewardLoot(
	lootContainer: LootContainerTemplate, -- The loot container template
	save: boolean, -- Whether to save the rewards
	showRewardUI: boolean, -- Whether to show the reward UI
	uiCloseCallback: () -> () -- Callback function when the UI is closed
)
	local rewards = LootManager.Roll(lootContainer) -- Roll for rewards from the loot container
	SaveManager.ClientAddRewardsFromLootContainer(rewards, save) -- Add rewards to the player's data

	if showRewardUI then -- If the reward UI should be shown
		local ui = UIManager.OpenRewardUI() -- Open the reward UI
		ui.Init(rewards, uiCloseCallback) -- Initialize the UI with rewards and callback
	end
end

-- Retrieves a list of clothing items from saved data
function GetClothingListFromSaveData(): { CharacterClothing }
	local clothingList = {} -- Initialize an empty clothing list
	if _useOldCloset then
		return clothingList -- Return empty list if using old closet
	end

	local clientPlayerData = SaveManager.GetClientPlayerData() -- Get the player's saved data
	if clientPlayerData then
		for _, reward in ipairs(clientPlayerData.RewardList) do -- Iterate through rewards
			local clothingTemplate: ClothingCollectionRewardTemplate? =
				_gameSettings.GetClothingCollectionRewardTemplate(reward.Id) -- Get clothing template by ID

			if clothingTemplate then -- If the clothing template exists
				local clothingCollection: ClothingCollection = clothingTemplate.Collection -- Get the clothing collection
				for _, c in ipairs(clothingCollection.clothing) do -- Iterate through clothing items
					table.insert(clothingList, c) -- Add clothing item to the list
				end
			end
		end
	end
	return clothingList -- Return the list of clothing items
end

-- Enables or disables showing chat messages
function EnableShowingChats(enable: boolean)
	if _chatDispatcher then
		_chatDispatcher.EnableShowingMessages(enable) -- Enable or disable chat messages
	end
end

-- Fades a character in or out over a specified duration
function FadeCharacter(model: CharacterModel, fade: boolean, duration: number)
	model.CharacterFade.StartFade(model.GetCharacter(), fade, duration) -- Start fading the character
	local petInfo = PetController.GetPetForPlayer(model.GetPlayer()) -- Get the pet associated with the player
	if petInfo and petInfo.character then
		Utils.SetGameObjectActive(petInfo.character.gameObject, not fade) -- Show or hide the pet based on fade state
	end
end

-- Fades all characters in or out
function FadeCharacters(fade: boolean, duration: number)
	-- Fade all players
	for _, model in ipairs(_allPlayers) do
		FadeCharacter(model, fade, duration) -- Fade each character
	end
end

-- Enters or exits cutscene display mode
function EnterCutsceneDisplay(enter: boolean, position: Vector3?, forward: Vector3?)
	if _inCutscene == enter then
		return -- If already in the desired state, do nothing
	end
	print("EnterCutsceneDisplay", tostring(enter)) -- Log the cutscene state change
	_inCutscene = enter -- Update the cutscene state
	if enter then
		_cameraLogic.StartCenteringOnPosition(
			_dressUpCameraSettings, -- Start centering the camera on the specified position
			position or Vector3.zero, -- Use provided position or default to zero
			forward or Vector3.forward -- Use provided forward direction or default to forward
		)
	else
		_cameraLogic.ZoomOutToCharacter(_defaultCameraSettings) -- Zoom out to the character when exiting cutscene
	end
	_cameraLogic.SetInputEnabled(not enter) -- Enable or disable input based on cutscene state

	PlayerCharacterController.options.enabled = not enter -- Enable or disable player character controls
	FadeCharacters(enter, 0.25) -- Fade characters in or out
	EnableShowingChats(not enter) -- Enable or disable chat messages based on cutscene state
end

-- Removes a character model from the list of all players
function RemoveModelFromList(model: CharacterModel)
	Utils.RemoveInTable(_allPlayers, model) -- Remove the model from the player list
end

-- Adds a character model to the list of all players
function AddModelToList(model: CharacterModel)
	table.insert(_allPlayers, model) -- Add the model to the player list

	if _inCutscene then
		FadeCharacter(model, true, 0) -- Fade the character if in cutscene
	end
end

-- Retrieves a player by their ID
function GetPlayer(playerId: string): Player | nil
	for _, player in ipairs(_allPlayers) do
		if player.GetPlayer().user.id == playerId then
			return player.GetPlayer() -- Return the player if found
		end
	end
	return nil -- Return nil if player not found
end

-- Opens the old closet UI for selecting outfits
function OpenClosetOld(
	title: string, -- Title of the closet UI
	callback: (outfit: CharacterOutfit) -> (), -- Callback function when an outfit is selected
	collection: ClothingCollection, -- Collection of clothing items
	usePlayerInventory: boolean, -- Whether to use the player's inventory
	defaultOutfit: CharacterOutfit -- Default outfit to display
)
	if _closetDevMode then
		callback(client.localPlayer.character.outfits[1]) -- If in dev mode, immediately call the callback with the first outfit
		return
	end
	UI:OpenCloset(client.localPlayer, callback, title, collection, usePlayerInventory, defaultOutfit) -- Open the closet UI
end

-- Opens the closet UI for selecting outfits
function OpenCloset(
	title: string, -- Title of the closet UI
	callback: (outfit: CharacterOutfit) -> (), -- Callback function when an outfit is selected
	acquiredClothing: { CharacterClothing }, -- List of clothing items acquired
	usePlayerInventory: boolean, -- Whether to use the player's inventory
	defaultOutfit: CharacterOutfit -- Default outfit to display
)
	if _closetDevMode then
		callback(client.localPlayer.character.outfits[1]) -- If in dev mode, immediately call the callback with the first outfit
		return
	end
	UI:OpenCloset(client.localPlayer, title, callback, acquiredClothing, usePlayerInventory, defaultOutfit) -- Open the closet UI
end

-- Starts playing the main background music
function StartMusic()
	if _mainMusic then
		Audio:PlayMusic(_mainMusic, 1, true, true) -- Play the main music
	end
end

-- Converts reward save data to game item amounts
function ConvertRewardSaveDataToGameItemAmount(rewardSaveData: { SaveManager.RewardSaveData }): { Types.GameItemAmount }
	local rewards: { Types.GameItemAmount } = {} -- Initialize an empty rewards list
	for _, reward in ipairs(rewardSaveData) do
		local template = _gameSettings.GetTemplateForId(reward.Id) -- Get the template for the reward ID
		if template then
			table.insert(rewards, { Template = template, Amount = reward.Amount }) -- Add the template and amount to the rewards list
		end
	end
	return rewards -- Return the list of game item amounts
end

-- Called when the client awakens
function self:ClientAwake()
	_cameraLogic = _mainCamera.gameObject:GetComponent(DressUpCamera) -- Get the camera logic component

	_gameSettings.Validate() -- Validate game settings
	StartMusic() -- Start playing the main music

	SaveManager.LoadPlayerData(OnPlayerDataLoaded) -- Load player data and set the callback
end

-------------------------------------------------------------------------------
-- Cheat Commands
-------------------------------------------------------------------------------

-- Clears all saved data
function ClearData()
	SaveManager.ClearData() -- Clear saved data
	_contestManager.ClearPlayerDataRequest() -- Clear player data requests in contest manager
end

-- Adds a reward cheat by parsing arguments
function AddRewardCheat(arguments: { string })
	-- Parse the arguments for ID and amount
	local id = arguments[1] -- Reward ID
	local amount = tonumber(arguments[2]) -- Reward amount
	SaveManager.AddCurrency(id, amount) -- Add currency to the player
	SaveManager.SavePlayerData() -- Save player data
end

-- Enables debug quests
function DebugQuestsCheat()
	DebugQuests = true -- Set debug quests flag to true
end

-- Unlocks contests by progressing on the unlocking quest
function UnlockContestCheat()
	SaveManager.ProgressOnQuest(_unlockContestsAfterQuest.Id, _unlockContestsAfterQuest.Target) -- Progress on the unlocking quest
	SaveManager.SavePlayerData() -- Save player data
end

-- Completes quests by index
function CompleteQuestsCheat(arguments: { string })
	local index = tonumber(arguments[1]) -- Get the quest index
	SaveManager.CompleteQuestCheat(index) -- Complete the specified quest
end

-------------------------------------------------------------------------------
-- Test Functions
-------------------------------------------------------------------------------

-- Returns whether sending quest outfits to contests is enabled for testing
function GetTestSendQuestsOutfitsToContest(): boolean
	return _testSendQuestsOutfitsToContest -- Return the test flag
end

-- Returns whether adding debug players for contests is enabled for testing
function GetTestAddDebugPlayersForContest(): boolean
	return _testAddDebugPlayersForContest -- Return the test flag
end

-- Returns whether closet developer mode is enabled
function GetClosetDevMode(): boolean
	return _closetDevMode -- Return the developer mode flag
end

-- Returns whether to use the old closet system
function UseOldCloset(): boolean
	return _useOldCloset -- Return the flag for using the old closet
end
