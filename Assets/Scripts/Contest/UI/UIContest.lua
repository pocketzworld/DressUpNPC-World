--!Type(UI)

-- Importing necessary modules for game management, UI utilities, contest management, quest management, types, and save management.
local GM: GameManager = require("GameManager")
local UIUtils: UIUtils = require("UIUtils")
local ContestManager: ContestManager = require("ContestManager")
local QuestManager: QuestManager = require("QuestManager")
local Types: Types = require("Types")
local SaveManager: SaveManager = require("SaveManager")

-- Enum-like table to define different tab types for the UI.
local TabType = {
	Contest = 1,
	Results = 2,
	Voting = 3,
}

-- UI elements bound to the visual elements in the UI.
-- These elements will be manipulated throughout the code.
--!Bind
local _closeOverlay: VisualElement = nil
--!Bind
local _content: VisualElement = nil
--!Bind
local _displayContent: VisualElement = nil
--!Bind
local _title: Label = nil
--!Bind
local _endTimeLabel: Label = nil
--!Bind
local _voteButton: UIButton = nil
--!Bind
local _enterButton: UIButton = nil
--!Bind
local _submitButton: UIButton = nil
--!Bind
local _editButton: UIButton = nil
--!Bind
local _submitContent: VisualElement = nil
--!Bind
local _submitCurrencyName: Label = nil
--!Bind
local _enterCurrencyName: Label = nil
--!Bind
local _ticketLabel: Label = nil
--!Bind
local _styleLabel: Label = nil
--!Bind
local _styleVotingLabel: Label = nil
--!Bind
local _contestContent: VisualElement = nil
--!Bind
local _loadSpinnerParent: VisualElement = nil
--!Bind
local _tabContest: VisualElement = nil
--!Bind
local _tabResults: VisualElement = nil
--!Bind
local _tabVoting: VisualElement = nil
--!Bind
local _contestTabContent: VisualElement = nil
--!Bind
local _resultsTabContent: VisualElement = nil
--!Bind
local _votingTabContent: VisualElement = nil
--!Bind
local _enteredContestLabel: Label = nil
--!Bind
local _contestListContent: VisualElement = nil
--!Bind
local _resultsNotification: VisualElement = nil

--!SerializeField
local _dressUpNPC: Character = nil -- Character used for dress-up functionality.
--!SerializeField
local _collectionForOldCloset: ClothingCollection = nil -- Collection of clothing for the old closet UI.
--!SerializeField
local _cameraTarget: Transform = nil -- Target for the camera during cutscenes.

-- Local variables for managing loading spinner, contest data, and timers.
local _loadingSpinner: VisualElement = nil
local _contestSaveData: ContestManager.ContestSaveData = nil
local _countdownTimer: Timer = nil
local _savedCharacterOutfit: CharacterOutfit = nil
local _savedOutfit: ContestManager.OutfitSaveData = nil
local _contestContentInMainScreen: boolean = true -- Flag to check if contest content is in the main screen.
local _dressUpClosetUI: UIDressUpCloset = nil -- UI for the dress-up closet.

-- Function to get the root visual element of the UI.
function GetRoot(): VisualElement
	return _content
end

-- Function to close the UI and optionally trigger quest display action.
local function CloseUI(closingAll: boolean)
	GM.UIManager.CloseUI(GM.UIManager.UINames.Contest)
	if closingAll then
		QuestManager.QuestDisplayActionEvent:Fire() -- Notify quests if closing all.
	end
end

-------------------------------------------------
-- Results UI
-------------------------------------------------

-- Function to handle the completion of opening rewards after a contest.
local function OnFinishedOpeningRewards(outfits: { ContestManager.ContestOutfitSaveData }, rank: number)
	local contestUI = GM.UIManager.OpenContestResultsUI() -- Open the contest results UI.
	contestUI.Init(outfits, rank) -- Initialize the results UI with outfits and rank.
	CloseUI(false) -- Close the current UI.
end

-- Function to handle the response after requesting placement for a contest.
local function OnPlacementReceivedForContest(
	code: number,
	outfits: { ContestManager.ContestOutfitSaveData },
	rank: number,
	rewardsSaveDataList: { SaveManager.RewardSaveData }
)
	if code ~= 0 then
		print("Failed to get placement for contest: " .. code) -- Log error if placement request failed.
		return
	end

	local rewards = GM.ConvertRewardSaveDataToGameItemAmount(rewardsSaveDataList) -- Convert rewards data.

	if rewards == nil or #rewards == 0 then
		OnFinishedOpeningRewards(outfits, rank) -- If no rewards, directly open results.
	else
		local ui = GM.UIManager.OpenRewardUI() -- Open rewards UI.
		ui.Init(rewards, function()
			OnFinishedOpeningRewards(outfits, rank) -- Initialize rewards UI and handle completion.
		end)
	end
end

-- Function to handle contest entry click events.
local function OnContestEntryClicked(contestSaveData: ContestManager.ContestSaveData)
	_contestSaveData = contestSaveData -- Store the clicked contest data.
	ContestManager.RequestPlacementForContest(contestSaveData.Id, OnPlacementReceivedForContest) -- Request placement for the contest.
end

-- Function to create a visual entry for a contest in the UI.
local function CreateContestEntry(contestSaveData: ContestManager.ContestSaveData): VisualElement
	local entryContainer = UIUtils.NewVisualElement(_contestListContent, { "contest-entry-frame" }, false) -- Create a new entry container.
	local entry = UIUtils.NewVisualElement(entryContainer, { "contest-entry" }) -- Create the entry visual element.
	local topLayout = UIUtils.NewVisualElement(entry, { "horizontal-layout" }) -- Create a horizontal layout for the entry.
	UIUtils.NewLabel(topLayout, { "contestentry-label" }, "Contest Results") -- Add label for contest results.
	UIUtils.NewLabel(topLayout, { "contestentry-label", "color-style" }, contestSaveData.Style) -- Add label for contest style.
	UIUtils.NewLabel(entry, { "contestentry-label" }, GM.Utils.GetTimeEndedAgo(contestSaveData.EndTime)) -- Add label for time ended.

	local playerContainerData = ContestManager.ClientGetPlayerContainerData() -- Get player contest data.
	local playerContestSaveData = ContestManager.GetPlayerContestData(playerContainerData, contestSaveData.Id) -- Get specific contest data for the player.
	local receivedReward = ContestManager.HasPlayerReceivedReward(playerContestSaveData) -- Check if the player has received rewards.
	local buttonText = receivedReward and "View Results" or "Collect Rewards" -- Set button text based on reward status.
	local buttonColor = receivedReward and "green" or "purple" -- Set button color based on reward status.
	local rewardsButton = UIUtils.NewButton(entry, { buttonColor, "right-anchor" }) -- Create rewards button.
	rewardsButton.style.width = StyleLength.new(100) -- Set button width.
	rewardsButton.style.height = StyleLength.new(50) -- Set button height.
	local buttonLabel = UIUtils.NewLabel(rewardsButton, { "font14", "color-white", "wrap" }, buttonText) -- Add label to button.
	UIUtils.ZeroMargin(buttonLabel) -- Remove margins from button label.
	UIUtils.ZeroPadding(buttonLabel) -- Remove padding from button label.

	entryContainer:RegisterPressCallback(function()
		OnContestEntryClicked(contestSaveData) -- Register click callback for the entry.
	end)
	return entry -- Return the created entry.
end

-- Function to sort contests by their end time.
local function SortContestByEndTime(
	playerContainerData: ContestManager.PlayerContestContainerSaveData,
	allContests: { ContestManager.ContestSaveData }
)
	table.sort(playerContainerData.ContestList, function(a, b)
		local contestSaveDataLeft = GM.Utils.FindInTable(allContests, function(data)
			return data.Id == a.ContestId and not ContestManager.IsContestInProgress(data) -- Find contest data for left entry.
		end)
		if contestSaveDataLeft == nil then
			return false -- If not found, do not change order.
		end
		local contestSaveDataRight = GM.Utils.FindInTable(allContests, function(data)
			return data.Id == b.ContestId and not ContestManager.IsContestInProgress(data) -- Find contest data for right entry.
		end)
		if contestSaveDataRight == nil then
			return true -- If not found, keep left entry before right.
		end
		return contestSaveDataLeft.EndTime > contestSaveDataRight.EndTime -- Sort by end time.
	end)
end

-- Function to set up notifications for results tab.
local function SetupResultsTabNotif()
	local playerContainerData: ContestManager.PlayerContestContainerSaveData =
		ContestManager.ClientGetPlayerContainerData() -- Get player contest data.
	local allContests: { ContestManager.ContestSaveData } = ContestManager.ClientGetAllContests() -- Get all contests.

	local count = 0
	-- Sort contests by end time.
	SortContestByEndTime(playerContainerData, allContests)

	-- Find all expired contests that the player was a part of.
	local showNotif = false
	for i = 1, #playerContainerData.ContestList do
		local playerContestData: ContestManager.PlayerContestSaveData = playerContainerData.ContestList[i]
		if not playerContestData.Submitted then
			continue -- Skip if the player did not submit.
		end

		local contestSaveData = GM.Utils.FindInTable(allContests, function(data)
			return data.Id == playerContestData.ContestId -- Find contest data for player.
		end)
		if contestSaveData == nil or ContestManager.IsContestInProgress(contestSaveData) then
			continue -- Skip if contest is not found or in progress.
		end
		local receivedReward = ContestManager.HasPlayerReceivedReward(playerContestData) -- Check if player received reward.
		if not receivedReward then
			showNotif = true -- Set notification flag if reward not received.
			break
		end
	end

	_resultsNotification:SetDisplay(showNotif) -- Display notification based on flag.
end

-- Function to set up the results content in the UI.
local function SetupResultsContent()
	_contestListContent:Clear() -- Clear existing contest list content.
	local playerContainerData: ContestManager.PlayerContestContainerSaveData =
		ContestManager.ClientGetPlayerContainerData() -- Get player contest data.
	local allContests: { ContestManager.ContestSaveData } = ContestManager.ClientGetAllContests() -- Get all contests.
	print("found " .. #allContests .. " contests " .. #playerContainerData.ContestList .. " player contests") -- Log found contests.
	local count = 0
	-- Sort contests by end time.
	SortContestByEndTime(playerContainerData, allContests)

	-- Find all expired contests that the player was a part of.
	for i = 1, #playerContainerData.ContestList do
		local playerContestData = playerContainerData.ContestList[i]
		if not playerContestData.Submitted then
			print("Player did not submit for contest: " .. playerContestData.ContestId) -- Log if player did not submit.
			continue
		end

		print("searching for contest: " .. playerContestData.ContestId) -- Log contest search.
		local contestSaveData = GM.Utils.FindInTable(allContests, function(data)
			return data.Id == playerContestData.ContestId and not ContestManager.IsContestInProgress(data) -- Find contest data.
		end)
		if contestSaveData then
			print("Contest found: " .. contestSaveData.Id) -- Log found contest.
			CreateContestEntry(contestSaveData) -- Create entry for the found contest.
			count = count + 1 -- Increment count of entries.
		end
	end

	if count == 0 then
		UIUtils.NewLabel(_contestListContent, { "small-label" }, "No contests to display") -- Display message if no contests found.
	end
end

-------------------------------------------------
-- End Results UI
-------------------------------------------------

-- Function to get a specific tab based on the tab type.
local function GetTab(tabType: TabType): VisualElement | nil
	if tabType == TabType.Contest then
		return _tabContest -- Return contest tab.
	elseif tabType == TabType.Results then
		return _tabResults -- Return results tab.
	elseif tabType == TabType.Voting then
		return _tabVoting -- Return voting tab.
	end
	return nil -- Return nil if no matching tab found.
end

-- Function to set the display of the selected tab.
local function SetTabDisplay(tabType: TabType)
	UIUtils.RemoveClass(_tabContest, "tab-selected") -- Remove selected class from contest tab.
	UIUtils.RemoveClass(_tabResults, "tab-selected") -- Remove selected class from results tab.
	UIUtils.RemoveClass(_tabVoting, "tab-selected") -- Remove selected class from voting tab.

	local tab = GetTab(tabType) -- Get the tab to display.
	if tab then
		UIUtils.AddClass(tab, "tab-selected") -- Add selected class to the current tab.
	end
end

-- Function to handle tab selection events.
local function OnTabSelected(tabType: TabType)
	SetTabDisplay(tabType) -- Set the display for the selected tab.
	_contestTabContent:SetDisplay(tabType == TabType.Contest) -- Show contest tab content.
	_resultsTabContent:SetDisplay(tabType == TabType.Results) -- Show results tab content.
	_votingTabContent:SetDisplay(tabType == TabType.Voting) -- Show voting tab content.

	if tabType == TabType.Results then
		SetupResultsContent() -- Set up results content if results tab is selected.
		_resultsNotification:SetDisplay(false) -- Hide results notification.
	else
		SetupResultsTabNotif() -- Set up results tab notification for other tabs.
	end
end

-- Function to handle close button events.
local function OnCloseButton()
	GM.EnterCutsceneDisplay(false) -- Exit cutscene mode.
	CloseUI(true) -- Close the UI and notify quests.
end

-- Function to move contest details between main screen and submission content.
local function MoveContestDetails(normalContent: boolean)
	if not _contestContentInMainScreen and normalContent then
		_contestContentInMainScreen = true -- Update flag to indicate contest content is in main screen.
		_contestContent:RemoveFromHierarchy() -- Remove contest content from current hierarchy.
		_contestTabContent:Insert(0, _contestContent) -- Insert contest content into the main screen.
	elseif _contestContentInMainScreen and not normalContent then
		_contestContentInMainScreen = false -- Update flag to indicate contest content is not in main screen.
		_contestContent:RemoveFromHierarchy() -- Remove contest content from current hierarchy.
		_submitContent:Insert(0, _contestContent) -- Insert contest content into submission content.
	end
end

-- Function to show or hide the loading spinner.
local function ShowLoadSpinner(show, normalContent)
	_loadSpinnerParent:SetDisplay(show) -- Set display for loading spinner parent.
	if not _loadingSpinner then
		_loadingSpinner = UIUtils.NewLoadingSpinner(_loadSpinnerParent, { "loading-spinner" }) -- Create loading spinner if it doesn't exist.
	end
	_loadingSpinner:SetDisplay(show) -- Show or hide the loading spinner.
	_displayContent:SetDisplay(not show and normalContent) -- Show display content based on loading state.
	_submitContent:SetDisplay(not show and not normalContent) -- Show submit content based on loading state.
	MoveContestDetails(normalContent) -- Move contest details based on loading state.
end

-- Function to handle vote button press events.
local function OnVoteButtonPressed()
	local playerContainerData = ContestManager.ClientGetPlayerContainerData() -- Get player contest data.
	if not _contestSaveData.CanVote then
		GM.UIManager.OpenGenericPopupUI("Check back later for more outfits to vote on", function() end) -- Notify player they cannot vote.
		return
	end
	local canVote = ContestManager.CanPlayerVote(playerContainerData, _contestSaveData.Id) -- Check if player can vote.
	if not canVote then
		GM.UIManager.OpenGenericPopupUI("You've reached the daily maximum vote limit", function() end) -- Notify player they reached vote limit.
		return
	end

	_voteButton:SetDisplay(false) -- Hide vote button while processing.
	ContestManager.RequestVotingBlock(_contestSaveData, function(votingBlock)
		_voteButton:SetDisplay(true) -- Show vote button again after processing.
		if votingBlock == nil or #votingBlock <= 1 then
			GM.UIManager.OpenGenericPopupUI("Check back later for more outfits to vote on", function() end) -- Notify player if no outfits to vote on.
			return
		end

		local contestUI = GM.UIManager.OpenContestVotingUI() -- Open contest voting UI.
		contestUI.Init(_contestSaveData, votingBlock) -- Initialize voting UI with contest data and voting block.
		CloseUI(false) -- Close current UI.
	end)
end

-- Function to handle submit button press events.
local function OnSubmitButtonPressed()
	ShowLoadSpinner(true, false) -- Show loading spinner while submitting.
	ContestManager.SubmitOutfitForContest(_contestSaveData.Id, _savedOutfit, nil, function(code)
		ShowLoadSpinner(false, true) -- Hide loading spinner after submission.
		if code ~= 0 then
			print("Failed to submit outfit for contest " .. tostring(code)) -- Log error if submission failed.
			return
		end
		-- Remove tickets and refresh UI.
		Refresh()
		GM.EnterCutsceneDisplay(false) -- Exit cutscene mode.
		GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, false) -- Hide dress-up NPC.
		QuestManager.NotifyEventForQuests({ EnteredContest = true }, true, true) -- Notify quests about contest entry.
	end)
end

-- Function to handle closet cancellation events.
local function OnClosetCanceled()
	GM.UIManager.CloseUI(GM.UIManager.UINames.DressUpCloset) -- Close dress-up closet UI.
	GM.EnterCutsceneDisplay(false) -- Exit cutscene mode.
	GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, false) -- Hide dress-up NPC.
end

-- Function to handle outfit completion events.
local function OnOutfitComplete(outfit: CharacterOutfit, style: string)
	GM.UIManager.CloseUI(GM.UIManager.UINames.DressUpCloset) -- Close dress-up closet UI.
	if style ~= _contestSaveData.Style then
		GM.UIManager.OpenGenericPopupUI(
			"A new contest has started with the style category: " .. _contestSaveData.Style,
			function() end
		) -- Notify player about new contest style.
	end

	_dressUpNPC:SetOutfit(outfit) -- Set the outfit for the dress-up NPC.

	_savedCharacterOutfit = outfit -- Save the completed outfit.
	_savedOutfit = GM.OutfitUtils.SerializeOutfitToOutfitSaveData(outfit) -- Serialize outfit for submission.
	_submitContent:SetDisplay(true) -- Show submit content.
	_displayContent:SetDisplay(false) -- Hide display content.
	MoveContestDetails(false) -- Move contest details to submission content.
	Refresh() -- Refresh the UI.
end

-- Function to handle enter contest button press events.
local function OnEnterContestButton()
	local playerSaveData = GM.SaveManager.GetClientPlayerData() -- Get player save data.
	local ticketAmount = GM.SaveManager.GetCurrencyAmount(playerSaveData, "ticket") -- Get ticket amount.
	local contestTemplate = ContestManager.GetContestTemplate(_contestSaveData.TemplateId) -- Get contest template.
	local hasTickets = ticketAmount >= contestTemplate.TicketCost -- Check if player has enough tickets.
	if not hasTickets then
		GM.UIManager.OpenGenericPopupUI("Not Enough Tickets to Enter", function() end) -- Notify player about insufficient tickets.
		return
	end

	GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, true) -- Show dress-up NPC.
	GM.EnterCutsceneDisplay(true, _cameraTarget.position, _cameraTarget.forward) -- Enter cutscene mode.
	local acquiredClothing: { CharacterClothing } = GM.GetClothingListFromSaveData() -- Get clothing list from save data.
	-- Also add all clothing player is currently wearing.
	local playerOutfit = client.localPlayer.character.outfits[1]
	for i = 1, #playerOutfit.clothing do
		table.insert(acquiredClothing, playerOutfit.clothing[i]) -- Add currently worn clothing to acquired clothing.
	end

	_dressUpClosetUI = GM.UIManager.OpenDressUpClosetUI() -- Open dress-up closet UI.
	_dressUpClosetUI.Init(OnClosetCanceled) -- Initialize dress-up closet UI with cancellation callback.

	-- Open the appropriate closet based on the version being used.
	if GM.UseOldCloset() then
		GM.OpenClosetOld(_contestSaveData.Style, function(outfit: CharacterOutfit)
			OnOutfitComplete(outfit, _contestSaveData.Style) -- Handle outfit completion.
		end, nil, true, _savedCharacterOutfit)
	else
		GM.OpenCloset(_contestSaveData.Style, function(outfit: CharacterOutfit)
			OnOutfitComplete(outfit, _contestSaveData.Style) -- Handle outfit completion.
		end, acquiredClothing, false, _savedCharacterOutfit)
	end
end

-- Function to handle edit look button press events.
local function OnEditLookButton()
	OnEnterContestButton() -- Call enter contest button function.
end

-- Function to refresh the UI with current contest and player data.
function Refresh()
	local playerContainerData = ContestManager.ClientGetPlayerContainerData() -- Get player contest data.
	local canVote = _contestSaveData.CanVote and ContestManager.CanPlayerVote(playerContainerData, _contestSaveData.Id) -- Check if player can vote.
	local playerContestData = ContestManager.GetPlayerContestData(playerContainerData, _contestSaveData.Id) -- Get specific contest data for the player.
	local numberOfVotes = playerContestData == nil and 0 or #playerContestData.PlayersVotedFor -- Get number of votes.

	local playerSaveData = GM.SaveManager.GetClientPlayerData() -- Get player save data.
	local ticketAmount = GM.SaveManager.GetCurrencyAmount(playerSaveData, "ticket") -- Get ticket amount.

	local hasEnteredContest = ContestManager.IsPlayerInContest(playerContainerData, _contestSaveData.Id) -- Check if player has entered the contest.
	local contestTemplate = ContestManager.GetContestTemplate(_contestSaveData.TemplateId) -- Get contest template.
	print(
		"Can vote: "
			.. tostring(canVote)
			.. " Contest allowed voting: "
			.. tostring(_contestSaveData.CanVote)
			.. " number of votes: "
			.. numberOfVotes
			.. " tickets "
			.. tostring(ticketAmount .. " has entered " .. tostring(hasEnteredContest))
	) -- Log current state.
	_enterButton:SetDisplay(not hasEnteredContest) -- Show or hide enter button based on contest entry status.
	_enteredContestLabel:SetDisplay(hasEnteredContest) -- Show or hide entered contest label.

	_ticketLabel.text = "Tickets: " .. tostring(ticketAmount) -- Update ticket label.
	_submitButton:SetEnabled(_savedOutfit ~= nil) -- Enable submit button if an outfit is saved.
	_title.text = contestTemplate.DisplayData.Name -- Update title with contest name.
	_styleLabel.text = "Style: " .. _contestSaveData.Style -- Update style label.
	_styleVotingLabel.text = _contestSaveData.Style -- Update style voting label.

	_submitCurrencyName.text = tostring(contestTemplate.TicketCost) -- Update submit currency name.
	_enterCurrencyName.text = tostring(contestTemplate.TicketCost) -- Update enter currency name.
end

-- Function to update the timer for the contest.
local function OnUpdateTimer()
	local timeRemaining = _contestSaveData.EndTime - os.time() -- Calculate time remaining for the contest.
	_endTimeLabel.text = "Ends In: " .. GM.Utils.GetTimerText(math.max(0, timeRemaining)) -- Update end time label.
	if timeRemaining <= -1 then
		_countdownTimer:Stop() -- Stop the countdown timer if contest has ended.
		print("Contest ended, requesting new list") -- Log contest end.
		ContestManager.RequestContestList(function(contests)
			local activeContests = ContestManager.GetActiveContests() -- Get active contests.
			local firstContest = activeContests[1] -- Get the first active contest.
			if firstContest and firstContest.Id ~= _contestSaveData.Id then
				print("Contest ended, switching to new contest") -- Log contest switch.
				_contestSaveData = firstContest -- Update contest save data.
				Refresh() -- Refresh the UI with new contest data.
				_countdownTimer = Timer.Every(1, OnUpdateTimer) -- Restart the countdown timer.
			end
		end)
	end
end

-- Function to initialize the UI with active contests.
local function Init(activeContests)
	_contestSaveData = activeContests[1] -- Set the current contest save data.
	Refresh() -- Refresh the UI with contest data.

	_closeOverlay:RegisterPressCallback(OnCloseButton) -- Register close button callback.

	-- Register button callbacks for various actions.
	_voteButton:RegisterPressCallback(OnVoteButtonPressed)
	_enterButton:RegisterPressCallback(OnEnterContestButton)
	_submitButton:RegisterPressCallback(OnSubmitButtonPressed)
	_editButton:RegisterPressCallback(OnEditLookButton)

	-- Register tab selection callbacks.
	_tabContest:RegisterCallback(PointerDownEvent, function()
		OnTabSelected(TabType.Contest)
	end)

	_tabResults:RegisterCallback(PointerDownEvent, function()
		OnTabSelected(TabType.Results)
	end)

	_tabVoting:RegisterCallback(PointerDownEvent, function()
		OnTabSelected(TabType.Voting)
	end)

	OnTabSelected(TabType.Contest) -- Select the contest tab by default.

	if _countdownTimer then
		_countdownTimer:Stop() -- Stop any existing countdown timer.
	end
	_endTimeLabel.text = "Ends In: " .. GM.Utils.GetTimerText(_contestSaveData.EndTime - os.time()) -- Update end time label.
	_countdownTimer = Timer.Every(1, OnUpdateTimer) -- Start a new countdown timer.
end

-- Function to handle cleanup when the client is destroyed.
function self.ClientOnDestroy()
	if _countdownTimer then
		_countdownTimer:Stop() -- Stop the countdown timer.
	end
end

-- Function to handle initialization when the client awakes.
function self.ClientAwake()
	ShowLoadSpinner(true, true) -- Show loading spinner while initializing.
	GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, false) -- Hide dress-up NPC.
	_dressUpNPC:SetOutfit(client.localPlayer.character.outfits[1]) -- Set the outfit for the dress-up NPC.
	-- Request new data before initializing the UI.
	ContestManager.RequestContestList(function(contestList)
		ShowLoadSpinner(false, true) -- Hide loading spinner after data is received.
		activeContests = ContestManager.GetActiveContests() -- Get active contests.
		if activeContests == nil or #activeContests == 0 then
			GM.UIManager.CloseUI(GM.UIManager.UINames.Contest) -- Close UI if no active contests.
			return
		end
		_displayContent:SetDisplay(true) -- Show display content.
		Init(activeContests) -- Initialize the UI with active contests.
	end)
end
