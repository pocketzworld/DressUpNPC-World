--!Type(Module)

-- Importing the GameManager module to manage game-related functionalities
local GM: GameManager = require("GameManager")

-- Declaring private variables for dialog management
local _dialogTemplate: DialogTemplate = nil -- The current dialog template being used
local _currentDialogStep: number = 1 -- The current step in the dialog
local _onFinished: () -> () = nil -- Callback function to be called when the dialog ends
local _dialogUI: DialogUI = nil -- Reference to the dialog UI
local _npcCharacter: Character = nil -- Reference to the NPC character involved in the dialog

-- Function to display the current step of the dialog
local function ShowDialogStep()
	_dialogUI.NextDialogStep(_dialogTemplate, _currentDialogStep, _npcCharacter)
end

-- Callback function to handle the completion of a dialog step
local function OnDialogStepComplete()
	_currentDialogStep = _currentDialogStep + 1 -- Move to the next dialog step
	if _currentDialogStep > _dialogTemplate.GetStepCount() then
		EndDialog() -- If there are no more steps, end the dialog
	else
		ShowDialogStep() -- Otherwise, show the next step
	end
end

-- Function to create and initialize the dialog UI
function CreateDialogUI()
	if _dialogUI then
		return -- If the dialog UI already exists, do nothing
	end
	local uiManager: UIManager = GM.UIManager -- Get the UI manager from the GameManager
	_dialogUI = uiManager.OpenDialogUI(uiManager.UINames.DialogUI) -- Open the dialog UI
	_dialogUI.Init(OnDialogStepComplete) -- Initialize the UI with the completion callback
end

-- Function to start a dialog with an override for the speech
function StartDialogWithOverride(
	dialog: DialogTemplate,
	dialogOverride: DialogTemplate,
	npcCharacter: Character,
	onFinished: () -> ()
)
	CreateDialogUI() -- Ensure the dialog UI is created
	_dialogUI.SetOverrideSpeech(dialogOverride.GetSpeechAudio(), dialogOverride.GetDisplayData()) -- Set the override speech
	StartDialog(dialog, npcCharacter, onFinished) -- Start the dialog with the provided parameters
end

-- Function to start a dialog with the specified dialog template and NPC character
function StartDialog(dialog: DialogTemplate, npcCharacter: Character, onFinished: () -> ())
	if not dialog then
		onFinished() -- If no dialog is provided, immediately call the finished callback
		return
	end
	_dialogTemplate = dialog -- Set the current dialog template
	_currentDialogStep = 1 -- Reset the current dialog step to 1
	_onFinished = onFinished -- Store the finished callback
	_npcCharacter = npcCharacter -- Store the NPC character reference

	CreateDialogUI() -- Create the dialog UI
	ShowDialogStep() -- Show the first step of the dialog
end

-- Function to end the current dialog
function EndDialog()
	GM.UIManager.CloseUI(GM.UIManager.UINames.DialogUI) -- Close the dialog UI
	_dialogTemplate = nil -- Clear the dialog template
	_currentDialogStep = 1 -- Reset the current dialog step
	_dialogUI = nil -- Clear the dialog UI reference
	if _onFinished then
		_onFinished() -- Call the finished callback if it exists
	end
end
