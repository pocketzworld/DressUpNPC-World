--!Type(UI)

-- Define constants for nameplate classes
local NameplateLeftClass = "nameplate-left"
local NameplateRightClass = "nameplate-right"

-- Import required modules
local GM: GameManager = require("GameManager")
local TweenModule: TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

-- Bind UI elements
--!Bind
local _root: VisualElement = nil
--!Bind
local _content: VisualElement = nil
--!Bind
local _dialogText: Label = nil
--!Bind
local _nameplateContainer: VisualElement = nil
--!Bind
local _nameText: Label = nil
--!Bind
local _nextArrow: VisualElement = nil

-- Header for dialog settings
--!Header("Dialog Settings")
-- Serialize fields for dialog settings
-- Speed of text animation
--!SerializeField
local _animateTextSpeed: number = 0.1
-- Amount to rotate the nameplate
--!SerializeField
local _nameplateRotateAmount: number = 10
-- Duration of the nameplate rotation animation
--!SerializeField
local _nameplateRotateDuration: number = 2
-- Delay before the nameplate rotation starts again
--!SerializeField
local _nameplateRotateDelay: number = 0.75
-- Delay before speech audio loops
--!SerializeField
local _speechAudioDelay: number = 0.4
-- Number of characters from the end to stop audio
--!SerializeField
local _charactersFromEndToStopAudio: number = 10

-- Header for arrow animation settings
--!Header("Arrow Animation Settings")
-- Duration of the arrow movement animation
--!SerializeField
local _arrowMoveDuration: number = 1
-- Distance the arrow moves
--!SerializeField
local _arrowMoveDistance: number = 10
-- Starting position of the arrow
--!SerializeField
local _arrowBotStart: number = 10

-- Declare variables for dialog management
local _dialogTemplate: DialogTemplate = nil
local _dialogStep: DialogStep = nil
local _dialogTextString: string = ""
local _overrideSpeechAudio: AudioShader = nil
local _overrideDisplayData: DisplayDataTemplate = nil
local _onDialogStepComplete: () -> () = nil
local _animatedIndex = 1
local _animateTimer: number = 0
local _animating: boolean = false
local _speechAudioTimer: Timer = nil
local _arrowTween = nil

-- Function to get the root visual element
function GetRoot(): VisualElement
	return _root
end

-- Function to get the size of the dialog content
function GetSize(): Vector2
	local size = Vector2.zero
	size.x = _content.layout.width
	size.y = _content.layout.height + _nameplateContainer.layout.height
	return size
end

-- Function to stop the speech audio
local function StopSpeechAudio()
	if _speechAudioTimer then
		_speechAudioTimer:Stop() -- Stop the timer if it exists
		_speechAudioTimer = nil -- Reset the timer
	end
end

-- Function to loop the speech audio
local function LoopSpeechAudio()
	local audio = _dialogTemplate.GetSpeechAudio() -- Get the speech audio from the dialog template
	if not audio then
		return -- Exit if no audio is found
	end
	if _overrideSpeechAudio and not _dialogStep.PlayerSpeaking then
		audio = _overrideSpeechAudio -- Use overridden audio if applicable
	end

	StopSpeechAudio() -- Stop any existing audio
	Audio:PlaySoundGlobal(audio, 1, 1, false) -- Play the audio globally
	_speechAudioTimer = Timer.Every(_speechAudioDelay, function()
		if _animating then
			Audio:PlaySoundGlobal(audio, 1, 1, false) -- Loop the audio if animating
		end
	end)
end

-- Function to initialize the dialog system
function Init(onDialogStepComplete: () -> ())
	_onDialogStepComplete = onDialogStepComplete -- Set the callback for dialog step completion

	_content:RegisterPressCallback(OnClicked) -- Register click callback for content

	PlayNameplateRotateAnim(-1, 1) -- Start the nameplate rotation animation
end

-- Function to set overridden speech audio and display data
function SetOverrideSpeech(audio: AudioShader, displayData: DisplayDataTemplate)
	_overrideSpeechAudio = audio -- Set the overridden audio
	_overrideDisplayData = displayData -- Set the overridden display data
end

-- Function to update the position of the nameplate based on who is speaking
local function UpdateNameplatePosition(playerSpeaking: boolean)
	if playerSpeaking then
		_nameplateContainer:AddToClassList(NameplateRightClass) -- Add right class if player is speaking
		_nameplateContainer:RemoveFromClassList(NameplateLeftClass) -- Remove left class
	else
		_nameplateContainer:AddToClassList(NameplateLeftClass) -- Add left class if NPC is speaking
		_nameplateContainer:RemoveFromClassList(NameplateRightClass) -- Remove right class
	end
end

-- Function to play an emote for a character
local function PlayEmote(character: Character)
	local emote = _dialogStep.Emote -- Get the emote from the dialog step
	if emote and emote ~= "" then
		character:PlayEmote(emote) -- Play the emote if it exists
	end
end

-- Function to sanitize text by replacing special characters
local function SanitizeText(text: string): string
	-- Substitute ’ with '
	return text:gsub("’", "'")
end

-- Function to proceed to the next dialog step
function NextDialogStep(dialogTemplate: DialogTemplate, index: number, npcCharacter: Character)
	_dialogTemplate = dialogTemplate -- Set the dialog template
	_dialogStep = _dialogTemplate.GetDialogStep(index) -- Get the current dialog step
	_animatedIndex = 1 -- Reset the animated index
	_animating = true -- Set animating flag
	_animateTimer = 0 -- Reset the animation timer
	_dialogTextString = SanitizeText(_dialogStep.Dialog) -- Sanitize and store the dialog text

	_nameText.text = _dialogStep.DisplayData.Name -- Set the name text
	if _overrideDisplayData and not _dialogStep.PlayerSpeaking then
		_nameText.text = _overrideDisplayData.Name -- Use overridden display data if applicable
	end
	UpdateNameplatePosition(_dialogStep.PlayerSpeaking) -- Update nameplate position based on speaker
	_nextArrow:SetDisplay(false) -- Hide the next arrow
	PlayEmote(npcCharacter) -- Play the emote for the NPC character

	if not _dialogStep.PlayerSpeaking then
		LoopSpeechAudio() -- Start looping speech audio if NPC is speaking
	else
		StopSpeechAudio() -- Stop audio if player is speaking
	end
end

-- Function to handle click events
function OnClicked()
	StopSpeechAudio() -- Stop any ongoing speech audio
	_onDialogStepComplete() -- Call the completion callback
end

-- Function to handle the completion of a dialog step
local function DialogComplete()
	_animating = false -- Set animating flag to false
	StopSpeechAudio() -- Stop any ongoing speech audio
	_nextArrow:SetDisplay(true) -- Show the next arrow
	PlayDialogArrowAnim(-1, 1) -- Start the arrow animation
end

-- Function to animate the next character in the dialog
function AnimateNextCharacter()
	if _animatedIndex <= #_dialogTextString then
		_dialogText.text = _dialogTextString:sub(1, _animatedIndex) -- Update the dialog text
		_animatedIndex = _animatedIndex + 1 -- Increment the animated index

		if _animatedIndex >= #_dialogStep.Dialog - _charactersFromEndToStopAudio then
			StopSpeechAudio() -- Stop audio if near the end of the dialog
		end
	else
		DialogComplete() -- Complete the dialog if finished
	end
end

-- Function to update the client each frame
function self.ClientUpdate()
	_animateTimer = _animateTimer + Time.deltaTime -- Increment the animation timer
	if _animating and _animateTimer >= _animateTextSpeed then
		_animateTimer = _animateTimer - _animateTextSpeed -- Reset the timer
		AnimateNextCharacter() -- Animate the next character
	end
end

-- Function to play the nameplate rotation animation
function PlayNameplateRotateAnim(start: number, finish: number)
	local myTween = Tween
		:new(function(value)
			_nameplateContainer.style.rotate = StyleRotate.new(Rotate.new(Angle.new((value * _nameplateRotateAmount)))) -- Update rotation based on tween value
		end)
		:FromTo(start, finish) -- Set tween start and finish values
		:Easing(Easing.easeInOutSin) -- Set easing function
		:Duration(_nameplateRotateDuration) -- Set duration of the animation
		:OnComplete(function()
			Timer.After(_nameplateRotateDelay, function()
				PlayNameplateRotateAnim(finish, -finish) -- Loop the rotation animation
			end)
		end)

	myTween:start() -- Start the tween animation
end

-- Function to play the dialog arrow animation
function PlayDialogArrowAnim(start: number, finish: number)
	if _arrowTween then
		_arrowTween:stop() -- Stop any existing arrow tween
	end
	_arrowTween = Tween
		:new(function(value) -- onUpdate callback
			_nextArrow.style.bottom = StyleLength.new(Length.new(_arrowBotStart + value * _arrowMoveDistance)) -- Update arrow position based on tween value
		end)
		:FromTo(start, finish) -- Set tween start and finish values
		:Easing(Easing.easeInOutSin) -- Set easing function
		:Duration(_arrowMoveDuration) -- Set duration of the animation
		:OnComplete(function()
			_nextArrow.style.bottom = StyleLength.new(Length.new(_arrowBotStart + finish * _arrowMoveDistance)) -- Set final position of the arrow
			PlayDialogArrowAnim(finish, -finish) -- Loop the arrow animation
		end)

	_arrowTween:start() -- Start the tween animation
end
