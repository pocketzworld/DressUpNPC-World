--!Type(Client)

-- Importing necessary modules for managing game functionalities
local GM: GameManager = require("GameManager") -- GameManager handles overall game state and utilities
local DialogManager: DialogManager = require("DialogManager") -- DialogManager manages dialog interactions
local ContestManager: ContestManager = require("ContestManager") -- ContestManager handles contest-related logic
local QuestManager: QuestManager = require("QuestManager") -- QuestManager manages quest-related functionalities

--!SerializeField
-- A dialog template that is shown when contests are not unlocked
local _notUnlockedDialog: DialogTemplate = nil

--!SerializeField
-- The NPC character associated with the dialog
local _npcCharacter: Character = nil

--!SerializeField
-- The game object that will be notified about contest unlock status
local _notifyObject: GameObject = nil

-- Function to update the visibility of the notify object based on contest unlock status
local function UpdateNotifyObject()
	-- Set the active state of the notify object based on whether contests are unlocked
	GM.Utils.SetGameObjectActive(_notifyObject, GM.AreContestsUnlocked())
end

-- Function called when the client is initialized
function self.ClientAwake()
	-- Initially hide the notify object
	GM.Utils.SetGameObjectActive(_notifyObject, false)

	-- Get the TapHandler component from the game object
	local tapHandler = self.gameObject:GetComponent(TapHandler)

	-- Connect the Tapped event to a function that handles contest interaction
	tapHandler.Tapped:Connect(function()
		-- Check if contests are unlocked
		if GM.AreContestsUnlocked() then
			-- If contests are unlocked, open the contest UI
			GM.UIManager.OpenContestUI()
			return
		else
			-- If contests are not unlocked, start the dialog with the NPC
			DialogManager.StartDialog(_notUnlockedDialog, _npcCharacter, nil)
		end
	end)

	-- Connect the SaveDataLoadedEvent to update the notify object when data is loaded
	GM.SaveDataLoadedEvent:Connect(UpdateNotifyObject)

	-- Connect the QuestCompletedEvent to update the notify object when a quest is completed
	QuestManager.QuestCompletedEvent:Connect(UpdateNotifyObject)
end
