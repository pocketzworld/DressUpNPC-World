--!Type(UI)

-- Import necessary modules for contest management, game management, UI utilities, and tweening effects
local ContestManager = require("ContestManager")
local GM: GameManager = require("GameManager")
local UIUtils: UIUtils = require("UIUtils")
local TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

-- UI elements bound to the visual elements in the scene
--!Bind
local _leftPanel: VisualElement = nil
--!Bind
local _rightPanel: VisualElement = nil
--!Bind
local _leftStarContainer: VisualElement = nil
--!Bind
local _rightStarContainer: VisualElement = nil
--!Bind
local _voteTicketRecord: Label = nil
--!Bind
local _styleLabel: Label = nil
--!Bind
local _skipButton: Label = nil
--!Bind
local _loadSpinnerParent: VisualElement = nil
--!Bind
local _backButton: Label = nil
--!Bind
local _ticketRewardDisplay: VisualElement = nil

-- Serialized fields for various game objects and parameters
--!SerializeField
local _cameraTarget: Transform = nil
--!SerializeField
local _fxToPlayPrefab: GameObject = nil
--!SerializeField
local _leftNPCCharacter: Character = nil
--!SerializeField
local _leftFXAnchor: Transform = nil
--!SerializeField
local _starSprite: Sprite = nil
--!SerializeField
local _rightNPCCharacter: Character = nil
--!SerializeField
local _rightFXAnchor: Transform = nil
--!SerializeField
local _starSequenceDuration: number = 2
--!SerializeField
local _cameraZoomWaitTime: number = 0.5
--!SerializeField
local _delayAfterSmokeToChange: number = 0.25
--!SerializeField
local _floatTicketHeight: number = 10
--!SerializeField
local _floatTicketTime: number = 2
--!SerializeField
local _smokeSound: AudioShader = nil
--!SerializeField
local _votedSound: AudioShader = nil

-- Variables to hold contest data and voting information
local _contestSaveData: ContestManager.ContestSaveData = nil
local _votingBlock: { ContestManager.ContestOutfitSaveData } = nil
local _leftOutfitData: ContestManager.ContestOutfitSaveData = nil
local _rightOutfitData: ContestManager.ContestOutfitSaveData = nil
local _player1Id: string = nil
local _player2Id: string = nil
local _playersVotedFor: { string } = {}
local _playersVotedAgainst: { string } = {}
local _index: number = 1
local _canPress: boolean = true
local _currentVotes: number = 0
local _loadingSpinner: VisualElement = nil
local _smokeTimer: Timer = nil
local _waitTimer: Timer = nil
local _newContestTimer: Timer = nil

-- Function to create and play special effects at a given position
local function CreateSetupFX(position: Vector3)
	local fx = Object.Instantiate(_fxToPlayPrefab, position, Quaternion.identity)

	if _smokeSound then
		Audio:PlaySoundGlobal(_smokeSound, 1, 1, false)
	end
end

-- Function to show or hide the loading spinner
local function ShowLoadSpinner(show)
	_loadSpinnerParent:SetDisplay(show)
	if not _loadingSpinner then
		_loadingSpinner = UIUtils.NewLoadingSpinner(_loadSpinnerParent, { "loading-spinner" })
	end
	_loadingSpinner:SetDisplay(show)
end

-- Function to show smoke effects at the left and right FX anchors
local function ShowSmokeFX()
	CreateSetupFX(_leftFXAnchor.transform.position)
	CreateSetupFX(_rightFXAnchor.transform.position)
end

-- Function to create a star visual element based on a percentage and parent container
local function CreateStar(percent: number, parent: VisualElement)
	local starElement = UIUtils.NewVisualElement(parent, { "star" }, true)
	local starMask = UIUtils.NewVisualElement(starElement, { "star-masked" }, true)
	starMask.style.width = StyleLength.new(Length.Percent(percent * 100))
	local starOverlay = UIUtils.NewImage(starMask, { "star-overlay" }, true)
	starOverlay.image = _starSprite.texture
end

-- Function to create stars for a given panel based on outfit data
local function CreateStarsForPanel(panel: VisualElement, outfitData: ContestManager.ContestOutfitSaveData)
	local totalStarsPossible = ContestManager.TotalStarsPossible
	local starAmt = 0.5
	if outfitData.TotalVotes > 0 then
		starAmt = outfitData.Score / outfitData.TotalVotes
	end
	starAmt = starAmt * totalStarsPossible

	local score = math.max(0.5, starAmt)
	for i = 1, totalStarsPossible do
		if score >= 1 then
			CreateStar(1, panel)
		else
			CreateStar(math.max(0, score), panel)
		end
		score = score - 1
	end
end

-- Function to end the star sequence and prepare for the next vote
local function EndStarSequence()
	_leftStarContainer:SetDisplay(false)
	_rightStarContainer:SetDisplay(false)

	_leftStarContainer:Clear()
	_rightStarContainer:Clear()

	ShowSmokeFX()
	_smokeTimer = Timer.After(_delayAfterSmokeToChange, SetupForVote)
end

-- Function to show the star sequence based on the vote
local function ShowStarSequence(votedLeft: boolean)
	_leftStarContainer:SetDisplay(true)
	_rightStarContainer:SetDisplay(true)

	if votedLeft then
		_leftOutfitData.Score = _leftOutfitData.Score + 1
		_leftOutfitData.TotalVotes = _leftOutfitData.TotalVotes + 1
	else
		_rightOutfitData.Score = _rightOutfitData.Score + 1
		_rightOutfitData.TotalVotes = _rightOutfitData.TotalVotes + 1
	end

	CreateStarsForPanel(_leftStarContainer, _leftOutfitData)
	CreateStarsForPanel(_rightStarContainer, _rightOutfitData)

	_waitTimer = Timer.After(_starSequenceDuration, EndStarSequence)

	if _votedSound then
		Audio:PlaySoundGlobal(_votedSound, 1, 1, false)
	end
end

-- Function to handle the skip button action
local function OnSkipButton()
	EndStarSequence()
end

-- Function to inform the server about the votes cast
local function TellServerAboutVotes()
	if #_playersVotedFor == 0 then
		return
	end
	ContestManager.CastVote(_contestSaveData, _playersVotedFor, _playersVotedAgainst)
	table.clear(_playersVotedFor)
	table.clear(_playersVotedAgainst)
end

-- Function to cast a vote for either the left or right outfit
local function CastVote(votedLeft: boolean)
	if _contestSaveData == nil then
		return
	end

	_canPress = false

	local leftPlayer = votedLeft and _player1Id or _player2Id
	local rightPlayer = votedLeft and _player2Id or _player1Id

	table.insert(_playersVotedFor, leftPlayer)
	table.insert(_playersVotedAgainst, rightPlayer)

	ShowStarSequence(votedLeft)

	_currentVotes = (_currentVotes + 1) % ContestManager.GetVotesPerTicket()
	_voteTicketRecord.text = _currentVotes .. "/5"
	if _currentVotes == 0 then
		TellServerAboutVotes()
		_ticketRewardDisplay:SetDisplay(true)
		FloatUpTween()
		Timer.After(_floatTicketTime, function()
			_ticketRewardDisplay:SetDisplay(false)
		end)
	end
end

-- Function to handle the left panel being pressed
local function OnLeftPanelPressed()
	if not _canPress then
		return
	end
	CastVote(true)
end

-- Function to handle the right panel being pressed
local function OnRightPanelPressed()
	if not _canPress then
		return
	end
	CastVote(false)
end

-- Function to check if there are more votes to cast
local function HasMoreToVote()
	return _index + 1 <= #_votingBlock
end

-- Function to close the UI and return to the previous screen
local function CloseUI()
	GM.EnterCutsceneDisplay(false, nil, nil)
	GM.UIManager.CloseUI(GM.UIManager.UINames.ContestVoting)
	GM.UIManager.OpenContestUI()
end

-- Function to handle the back button action
local function OnBackButton()
	if _smokeTimer then
		_smokeTimer:Stop()
	end
	if _waitTimer then
		_waitTimer:Stop()
	end

	if _newContestTimer then
		_newContestTimer:Stop()
	end
	TellServerAboutVotes()
	CloseUI()
end

-- Function to show or hide NPC characters
local function ShowNPCs(show: boolean)
	GM.Utils.SetGameObjectActive(_leftNPCCharacter.gameObject, show)
	GM.Utils.SetGameObjectActive(_rightNPCCharacter.gameObject, show)
end

-- Function to set up the voting process
function SetupForVote()
	if _votingBlock == nil then
		return
	end

	if not HasMoreToVote() then
		ShowNPCs(false)
		ShowLoadSpinner(true)
		ContestManager.RequestVotingBlock(_contestSaveData, function(votingBlock)
			ShowLoadSpinner(false)
			ShowNPCs(true)
			if votingBlock == nil or #votingBlock <= 1 then
				TellServerAboutVotes()
				CloseUI()
				return
			end

			_index = 1
			_votingBlock = votingBlock
			SetupForVote()
		end)
		return
	end

	_leftOutfitData = _votingBlock[_index]
	_rightOutfitData = _votingBlock[_index + 1]

	_leftNPCCharacter:SetOutfit(GM.OutfitUtils.DeserializeOutfitSaveDataToOutfit(_leftOutfitData.OutfitData))
	_rightNPCCharacter:SetOutfit(GM.OutfitUtils.DeserializeOutfitSaveDataToOutfit(_rightOutfitData.OutfitData))
	_player1Id = _leftOutfitData.PlayerId
	_player2Id = _rightOutfitData.PlayerId

	_index = _index + 2
	_canPress = true
end

-- Function to handle the event of a new contest starting
local function OnNewContestStarted()
	OnBackButton()
	GM.UIManager.OpenGenericPopupUI("A new contest has started", function() end)
end

-- Function to initialize the contest voting UI
function Init(contestSaveData: ContestManager.ContestSaveData, votingBlock: { ContestManager.ContestOutfitSaveData })
	_contestSaveData = contestSaveData
	_votingBlock = votingBlock
	_leftPanel:RegisterCallback(PointerDownEvent, OnLeftPanelPressed)
	_rightPanel:RegisterCallback(PointerDownEvent, OnRightPanelPressed)
	_skipButton:RegisterPressCallback(OnSkipButton)
	_backButton:RegisterCallback(PointerDownEvent, OnBackButton)
	_styleLabel.text = contestSaveData.Style

	local playerContestContainer: ContestManager.PlayerContestContainerSaveData =
		ContestManager.ClientGetPlayerContainerData()
	local playerContestData: ContestManager.PlayerContestSaveData =
		ContestManager.GetPlayerContestData(playerContestContainer, contestSaveData.Id)
	local currentCount = #playerContestData.PlayersVotedFor % ContestManager.GetVotesPerTicket()
	_voteTicketRecord.text = currentCount .. "/5"
	_currentVotes = currentCount

	GM.EnterCutsceneDisplay(true, _cameraTarget.position, _cameraTarget.forward)
	GM.Utils.SetGameObjectActive(_leftNPCCharacter.gameObject, false)
	GM.Utils.SetGameObjectActive(_rightNPCCharacter.gameObject, false)

	SetupForVote()
	_canPress = false
	_waitTimer = Timer.After(_cameraZoomWaitTime, function()
		ShowSmokeFX()
		_smokeTimer = Timer.After(_delayAfterSmokeToChange, function()
			GM.Utils.SetGameObjectActive(_leftNPCCharacter.gameObject, true)
			GM.Utils.SetGameObjectActive(_rightNPCCharacter.gameObject, true)
			_canPress = true
		end)
	end)

	_ticketRewardDisplay:SetDisplay(false)

	local timeRemaining = _contestSaveData.EndTime - os.time()
	_newContestTimer = Timer.After(timeRemaining, OnNewContestStarted)
end

-- Function to create a floating animation for the ticket reward display
function FloatUpTween()
	local startBot = 30
	_pulsingTween = Tween:new(function(value)
		local newBot = startBot + (value * _floatTicketHeight)
		_ticketRewardDisplay.style.bottom = StyleLength.new(Length.new(newBot))
	end)
		:FromTo(0, 1)
		:Easing(Easing.linear)
		:Duration(_floatTicketTime)
	_pulsingTween:start()
end
