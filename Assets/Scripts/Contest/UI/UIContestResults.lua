--!Type(UI)

-- Importing required modules for game management, utility functions, UI utilities, contest management, and type definitions.
local GM = require("GameManager")
local Utils = require("Utils")
local UIUtils = require("UIUtils")
local ContestManager = require("ContestManager")
local Types = require("Types")

--!Bind
-- Visual element that holds the list of player results.
local _playerListContent: VisualElement = nil
--!Bind
-- Overlay element for closing the UI.
local _closeOverlay: VisualElement = nil

--!SerializeField
-- Character model for the dress-up NPC.
local _dressUpNPC: Character = nil
--!SerializeField
-- Transform target for the camera.
local _cameraTarget: Transform = nil
--!SerializeField
-- Sprite used for star representation.
local _starSprite: Sprite = nil

-- Variable to hold contest save data.
local _contestSaveData: ContestManager.ContestSaveData = nil
-- Variable to track the currently selected entry.
local _selectedEntry: VisualElement = nil

-- Function to close the current UI and open the contest UI.
local function CloseUI()
	GM.UIManager.CloseUI(GM.UIManager.UINames.ContestResults) -- Close the contest results UI.
	GM.UIManager.OpenContestUI() -- Open the contest UI.
end

-- Function to create a star visual element based on a percentage and parent element.
local function CreateStar(percent: number, parent: VisualElement)
	-- Create a new visual element for the star.
	local starElement = UIUtils.NewVisualElement(parent, { "star" }, true)
	-- Create a masked element for the star.
	local starMask = UIUtils.NewVisualElement(starElement, { "star-masked" }, true)
	-- Set the width of the mask based on the percentage.
	starMask.style.width = StyleLength.new(Length.Percent(percent * 100))
	-- Create an overlay image for the star.
	local starOverlay = UIUtils.NewImage(starMask, { "star-overlay" }, true)
	starOverlay.image = _starSprite.texture -- Set the star image.
end

-- Function to create stars for a given panel based on outfit data.
local function CreateStarsForPanel(panel: VisualElement, outfitData: ContestManager.ContestOutfitSaveData)
	local totalStarsPossible = ContestManager.TotalStarsPossible -- Get the total possible stars.
	local starAmt = totalStarsPossible * 0.5 -- Default star amount is half of total stars.

	-- Calculate star amount based on votes and score.
	if outfitData.TotalVotes > 0 then
		starAmt = outfitData.Score / outfitData.TotalVotes
	end
	starAmt = starAmt * totalStarsPossible -- Scale to total stars.

	local score = math.max(0.5, starAmt) -- Ensure score is at least 0.5.
	for i = 1, totalStarsPossible do
		-- Create a star based on the current score.
		if score >= 1 then
			CreateStar(1, panel) -- Full star.
		else
			CreateStar(math.max(0, score), panel) -- Partial star.
		end
		score = score - 1 -- Decrease score for the next star.
	end
end

-- Function to select a specific entry and highlight it.
local function SelectEntry(entry: VisualElement)
	if _selectedEntry then
		UIUtils.RemoveClass(_selectedEntry, "selected") -- Remove selection from previously selected entry.
	end
	_selectedEntry = entry -- Update the selected entry.
	UIUtils.AddClass(_selectedEntry, "selected") -- Highlight the newly selected entry.
end

-- Callback function for when a result entry is clicked.
local function OnResultEntryClicked(element: VisualElement, outfitData: ContestManager.ContestOutfitSaveData)
	SelectEntry(element) -- Select the clicked entry.
	-- Set the outfit of the dress-up NPC based on the clicked entry's outfit data.
	_dressUpNPC:SetOutfit(GM.OutfitUtils.DeserializeOutfitSaveDataToOutfit(outfitData.OutfitData))
	GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, true) -- Make the NPC visible.
end

-- Function to create a result entry for a specific outfit data and rank.
local function CreateResultEntry(outfitData: ContestManager.ContestOutfitSaveData, rank: number): VisualElement
	-- Create a new visual element for the result entry.
	local entry = UIUtils.NewVisualElement(_playerListContent, { "result-entry", "horizontal-layout" }, false)
	local player = GM.GetPlayer(outfitData.PlayerId) -- Get player information based on PlayerId.
	local playerName = outfitData.PlayerId -- Default to PlayerId for name.

	if player then
		playerName = player.name -- Use player's name if available.
	end

	-- Create user thumbnail and rank label.
	local userImage = UIUtils.NewUserThumbnail(entry, { "user-thumbnail" }, outfitData.PlayerId)
	local rankLabel = UIUtils.NewLabel(entry, { "rank-label", "topleft-anchor" }, tostring(rank))

	-- Create layout for displaying player name and score.
	local displayRightVertLayout = UIUtils.NewVisualElement(entry, { "vertical-layout" })
	UIUtils.NewLabel(displayRightVertLayout, { "small-label", "color-white" }, playerName) -- Display player name.

	-- Get the score for the outfit and create a layout for score and stars.
	local score = ContestManager.GetOutfitScore(outfitData, _contestSaveData)
	local displayRightRankLayout = UIUtils.NewVisualElement(displayRightVertLayout, { "horizontal-layout centered" })
	UIUtils.NewLabel(displayRightRankLayout, { "small-label", "color-white" }, tostring(score)) -- Display score.

	-- Create stars for the panel based on outfit data.
	CreateStarsForPanel(displayRightRankLayout, outfitData)

	-- Register a callback for when the entry is clicked.
	entry:RegisterPressCallback(function()
		OnResultEntryClicked(entry, outfitData)
	end)
	return entry -- Return the created entry.
end

-- Function to create result entries for a list of outfits and the player's rank.
local function CreateResultEntries(outfits: { ContestManager.ContestOutfitSaveData }, playerRank: number)
	-- Setup the top outfits of the contest.
	print("outfit count " .. #outfits) -- Print the number of outfits.
	for i = 1, #outfits do
		local rank = i -- Default rank is the index.
		local isPlayer = outfits[i].PlayerId == client.localPlayer.user.id -- Check if the outfit belongs to the local player.
		if isPlayer then
			rank = playerRank -- Use the player's rank if it's their outfit.
		end
		local entry = CreateResultEntry(outfits[i], rank) -- Create the result entry.
		if isPlayer then
			SelectEntry(entry) -- Select the entry if it's the player's.
		end
	end
	-- Enter cutscene display mode with the camera targeting the specified position and direction.
	GM.EnterCutsceneDisplay(true, _cameraTarget.position, _cameraTarget.forward)
	GM.Utils.SetGameObjectActive(_dressUpNPC.gameObject, true) -- Make the dress-up NPC visible.
	_dressUpNPC:SetOutfit(GM.OutfitUtils.DeserializeOutfitSaveDataToOutfit(outfits[#outfits].OutfitData)) -- Set the NPC's outfit to the last outfit in the list.
end

-- Initialization function to set up the UI with the provided outfits and player rank.
function Init(outfits: { ContestManager.ContestOutfitSaveData }, playerRank: number)
	CreateResultEntries(outfits, playerRank) -- Create result entries for the outfits.

	-- Register a callback for the close overlay to close the UI when pressed.
	_closeOverlay:RegisterPressCallback(function()
		CloseUI()
	end)
end
