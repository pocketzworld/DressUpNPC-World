--!Type(Module)

-- Import necessary modules
local Types: Types = require("Types") -- Importing type definitions
local SaveManager: SaveManager = require("SaveManager") -- Importing save management functionalities
local GM: GameManager = require("GameManager") -- Importing game management functionalities

-- Define error codes for contest operations
ErrorCode = {
	None = 0,
	ContestNotFound = 1,
	ContestNotInProgress = 2,
	ContestOutfitAlreadySubmitted = 3,
	ContestOutfitNotFound = 4,
	ContestOutfitVoteError = 5,
	ContestVoteAlreadyVoted = 6,
	ContestNotEnoughTickets = 7,
	ContestPlayerAlreadyVoted = 8,
	NotSubmitted = 9,
}

-- Define data types for saving contest data
export type ContestContainerSaveData = {
	Contests: { ContestSaveData }, -- List of contests
	ContestNumber: number, -- Current contest number
	Version: number, -- Version of the contest data
}

export type ContestSaveData = {
	TemplateId: string, -- ID of the contest template
	Style: string, -- Style of the contest
	Id: string, -- Unique ID of the contest
	EndTime: number, -- End time of the contest
	CanVote: boolean, -- Flag indicating if voting is allowed
	ContestOutfits: { ContestOutfitSaveData }, -- List of outfits submitted for the contest
}

export type ContestOutfitSaveData = {
	PlayerId: string, -- ID of the player who submitted the outfit
	OutfitData: OutfitSaveData, -- Data of the outfit
	Score: number, -- Score of the outfit
	TotalVotes: number, -- Total votes received by the outfit
}

export type OutfitSaveData = {
	Ids: { string }, -- List of IDs for the outfit components
	Colors: { number }, -- List of colors for the outfit components
}

export type PlayerContestContainerSaveData = {
	ContestList: { PlayerContestSaveData }, -- List of contests the player has participated in
}

export type PlayerContestSaveData = {
	ContestId: string, -- ID of the contest
	Submitted: boolean, -- Flag indicating if the player has submitted an outfit
	ReceivedReward: boolean, -- Flag indicating if the player has received a reward
	PlayersVotedFor: { string }, -- List of players the user has voted for
}

-- Local type for storing outfit votes
type LocalOutfitVotes = {
	ContestId: string, -- ID of the contest
	PlayerId: string, -- ID of the player
	Score: number, -- Score given by the player
	TotalVotes: number, -- Total votes given by the player
}

-- Define keys and prefixes for saving data
local SavePrefix: string = "Contest_"
local PlayerContestKey: string = "PlayerContest"
local ContestContainerKey: string = "ContestContainer"

-- Define events for contest operations
ContestStartedEvent = Event.new("ContestStartedEvent")
ContestEndedEvent = Event.new("ContestEndedEvent")
ContestOutfitAddRequestEvent = Event.new("ContestOutfitAddRequestEvent")
ContestOutfitAddResponseEvent = Event.new("ContestOutfitAddResponseEvent")
ContestOutfitVoteRequestEvent = Event.new("ContestOutfitVoteRequestEvent")
ContestOutfitVoteResponseEvent = Event.new("ContestOutfitVoteResponseEvent")
ContestListRequestEvent = Event.new("ContestListRequestEvent")
ContestListResponseEvent = Event.new("ContestListResponseEvent")
ContestVotingBlockRequestEvent = Event.new("ContestVotingBlockRequestEvent")
ContestVotingBlockResponseEvent = Event.new("ContestVotingBlockResponseEvent")
PlacementRequestEvent = Event.new("PlacementRequestEvent")
PlacementResponseEvent = Event.new("PlacementResponseEvent")

-- Cheat events for testing
TestAddPlayersEvent = Event.new("TestAddPlayersEvent")
ClearAllContestsRequestEvent = Event.new("ClearAllContestsRequestEvent")
AddTicketsEventCheatEvent = Event.new("AddTicketsEventCheatEvent")
ClearPlayerDataRequestEvent = Event.new("ClearPlayerDataRequestEvent")
SetVotesCheatRequestEvent = Event.new("SetVotesCheatRequestEvent")

--!SerializeField
local _cheatsEnabled: boolean = true -- Flag to enable or disable cheats
--!SerializeField
local _startDateTemplate: DateTemplate = nil -- Template for contest start dates
--!SerializeField
local _contestTemplates: { ContestTemplate } = nil -- List of contest templates
--!SerializeField
local _voteOutfitsSentPerRequest: number = 5 -- Number of outfits sent per vote request
--!SerializeField
local _maxVotesPerContest: number = 10 -- Maximum votes allowed per contest
--!SerializeField
local _minOutfitsForVoting: number = 20 -- Minimum outfits required for voting to start
--!SerializeField
local _votesPerTicket: number = 5 -- Number of votes a player gets per ticket
--!SerializeField
local _previousContestsToStore: number = 7 -- Number of previous contests to store
--!SerializeField
local _saveInterval: number = 3600 -- Interval for saving data (in seconds)
--!SerializeField
local _totalStarsPossible: number = 5 -- Total stars possible for scoring
--!SerializeField
local _testCharacterOutfits: { CharacterOutfit } = nil -- List of test character outfits

-- Server Variables
local _serverContestContainerSaveData: ContestContainerSaveData = nil -- Data for contests on the server
local _serverContestNoOutfitDataList: { ContestSaveData } = {} -- List of contests without outfits
local _playerContainerSaveList: { [string]: PlayerContestContainerSaveData } = {} -- Data for each player's contest participation
local _contestOutfitLocalVotes: { [string]: { LocalOutfitVotes } } = {} -- Local votes for contest outfits
local _serverDataDirty: boolean = false -- Flag indicating if server data has changed

-- Client Variables
local _clientContestDataList: { ContestSaveData } = {} -- List of contest data for the client
local _clientPlayerContestContainerData: PlayerContestContainerSaveData = nil -- Player's contest data for the client
local _voteBlockResponseCallback: ({ ContestOutfitSaveData }) -> () | nil = nil -- Callback for vote block responses
local _requestContestListCallback: ({ ContestSaveData }) -> () | nil = nil -- Callback for contest list requests
local _addOutfitResponseCallback: (number) -> () | nil = nil -- Callback for outfit add responses
local _placementResponseCallback: (number, { ContestOutfitSaveData }, number, { SaveManager.RewardSaveData }) -> () | nil =
	nil -- Callback for placement responses

-------------------------------------------------------------------------------
-- Shared Functions
-------------------------------------------------------------------------------

-- Function to get the number of votes per ticket
function GetVotesPerTicket(): number
	return _votesPerTicket
end

-- Local function to get the total stars possible for scoring
local function GetTotalStarsPossible(): number
	return _totalStarsPossible
end
TotalStarsPossible = GetTotalStarsPossible() -- Store the total stars possible in a global variable

-- Local function to create player contest data
local function CreatePlayerContestData(contestId: string): PlayerContestSaveData
	local playerContestData = {
		Submitted = false, -- Flag indicating if the player has submitted an outfit
		ContestId = contestId, -- ID of the contest
		ReceivedReward = false, -- Flag indicating if the player has received a reward
		PlayersVotedFor = {}, -- List of players the user has voted for
	}
	return playerContestData -- Return the created player contest data
end

-- Local function to create player contest container data
local function CreatePlayerContestContainerData(): PlayerContestContainerSaveData
	local playerContestData = {
		ContestList = {}, -- List of contests the player has participated in
	}
	return playerContestData -- Return the created player contest container data
end

-- Function to calculate the score of an outfit based on votes
function GetOutfitScore(outfitData: ContestOutfitSaveData, contestSaveData: ContestSaveData): number
	if outfitData.TotalVotes == 0 then
		return 0 -- Return 0 if there are no votes
	end

	-- Calculate score based on total votes and stars possible
	local score = (outfitData.Score / outfitData.TotalVotes) * GetTotalStarsPossible()
	-- Truncate to 2 decimal places
	return math.floor(score * 100) / 100
end

-- Function to check if a contest is currently in progress
function IsContestInProgress(contest: ContestSaveData): boolean
	return os.time() < contest.EndTime -- Return true if the current time is less than the contest end time
end

-- Local function to print contest data for debugging
local function PrintContestData(contest: ContestSaveData)
	local contestString = "Contest: " .. contest.Id .. " End Time: " .. GM.Utils.GetDateString(contest.EndTime)
	if contest.ContestOutfits == nil then
		print("outfits nil") -- Print if there are no outfits
		return
	end
	for i, contestOutfit in ipairs(contest.ContestOutfits) do
		contestString = contestString
			.. " Player: "
			.. contestOutfit.PlayerId
			.. " Score: "
			.. contestOutfit.Score
			.. " Total Votes: "
			.. contestOutfit.TotalVotes
	end
	print(contestString) -- Print the contest data
end

-- Function to get a contest template by its ID
function GetContestTemplate(contestId: string): ContestTemplate | nil
	for i, contestTemplate in ipairs(_contestTemplates) do
		if contestTemplate.Id == contestId then
			return contestTemplate -- Return the contest template if found
		end
	end
	return nil -- Return nil if not found
end

-- Local function to check if a contest is valid (exists and is in progress)
local function IsContestValid(contestSaveData: ContestSaveData): boolean
	if not contestSaveData then
		print("Contest not found") -- Print error if contest is not found
		return false
	end

	if not IsContestInProgress(contestSaveData) then
		print("Contest is not in progress: " .. contestSaveData.Id) -- Print error if contest is not in progress
		return false
	end
	return true -- Return true if contest is valid
end

-- Function to check if a player can vote in a contest
function CanPlayerVote(playerContestContainerSaveData: PlayerContestContainerSaveData, contestId: string): boolean
	for i, contestData in ipairs(playerContestContainerSaveData.ContestList) do
		if contestData.ContestId == contestId then
			return #contestData.PlayersVotedFor < _maxVotesPerContest -- Return true if the player has not exceeded max votes
		end
	end
	return true -- Return true if the player has not voted in the contest
end

-- Function to get or create player contest data for a specific contest
function GetPlayerContestData(
	playerContestContainerSaveData: PlayerContestContainerSaveData,
	contestId: string
): PlayerContestSaveData
	for i, contestData in ipairs(playerContestContainerSaveData.ContestList) do
		if contestData.ContestId == contestId then
			return contestData -- Return existing contest data if found
		end
	end
	local newData
	newData = CreatePlayerContestData(contestId) -- Create new contest data if not found
	table.insert(playerContestContainerSaveData.ContestList, newData) -- Add new data to the list
	return newData -- Return the new contest data
end

-- Function to check if a player has submitted an outfit for a contest
function IsPlayerInContest(playerContestContainerSaveData: PlayerContestContainerSaveData, contestId: string): boolean
	for i, contestData in ipairs(playerContestContainerSaveData.ContestList) do
		if contestData.ContestId == contestId then
			return contestData.Submitted -- Return whether the player has submitted an outfit
		end
	end
	return false -- Return false if the player is not in the contest
end

-- Function to check if a player has enough tickets for a specific target
function PlayerHasTickets(playerData: SaveManager.PlayerData, ticketTarget: number): boolean
	return SaveManager.HasEnoughCurrency(playerData, "ticket", ticketTarget) -- Check if the player has enough tickets
end

-- Function to check if a player has received a reward for a contest
function HasPlayerReceivedReward(playerContestSaveData: PlayerContestSaveData): boolean
	return playerContestSaveData.ReceivedReward -- Return whether the player has received a reward
end

-------------------------------------------------------------------------------
-- Server Functions
-------------------------------------------------------------------------------

-- Local function to get or create player contest container data
local function GetPlayerContestContainerSaveData(playerId: string): PlayerContestContainerSaveData
	local data = _playerContainerSaveList[playerId] -- Get existing data for the player
	if data == nil then
		data = CreatePlayerContestContainerData() -- Create new data if not found
		_playerContainerSaveList[playerId] = data -- Store the new data
	end
	return data -- Return the player contest container data
end

-- Local function to get player contest container data using the player object
local function GetPlayerContestContainerSaveDataPlayer(player: Player): PlayerContestContainerSaveData
	return GetPlayerContestContainerSaveData(player.user.id) -- Return data for the player
end

-- Local function to get contest data for a specific player
local function GetContestDataForPlayer_Server(playerId: string, contestId: string): PlayerContestSaveData
	local playerContestData: PlayerContestContainerSaveData = GetPlayerContestContainerSaveData(playerId) -- Get player contest data
	if playerContestData == nil then
		playerContestData = CreatePlayerContestContainerData() -- Create new data if not found
		_playerContainerSaveList[playerId] = playerContestData -- Store the new data
	end

	return GetPlayerContestData(playerContestData, contestId) -- Return the contest data for the player
end

-- Local function to check if a contest can be purged (deleted)
local function CanContestBePurged(contestSaveData: ContestSaveData): boolean
	if IsContestInProgress(contestSaveData) then
		return false -- Cannot purge if the contest is still in progress
	end

	local contestTemplate = GetContestTemplate(contestSaveData.TemplateId) -- Get the contest template
	local currentEventEndTime = _startDateTemplate.FindPreviousTimeToStart(contestTemplate.Duration)
		+ contestTemplate.Duration -- Calculate the end time of the current event
	if currentEventEndTime - contestTemplate.Duration * _previousContestsToStore < contestSaveData.EndTime then
		return false -- Cannot purge if the contest end time is within the range of previous contests
	end
	return true -- Return true if the contest can be purged
end

-- Local function to get contest save data by contest ID
local function GetContestSaveData(contestContainer: ContestContainerSaveData, contestId: string): ContestSaveData | nil
	for i, contestSaveData in ipairs(contestContainer.Contests) do
		if contestSaveData.Id == contestId then
			return contestSaveData -- Return the contest save data if found
		end
	end
	return nil -- Return nil if not found
end

-- Local function to get the outfit data for a specific player in a contest
local function GetContestOutfitForPlayer(
	playerId: string,
	contestSaveData: ContestSaveData
): ContestOutfitSaveData | nil
	for i, contestOutfitSaveData in ipairs(contestSaveData.ContestOutfits) do
		if contestOutfitSaveData.PlayerId == playerId then
			return contestOutfitSaveData -- Return the outfit data if found
		end
	end
	return nil -- Return nil if not found
end

-- Local function to fill the list of contests without outfits
local function FillNoOutfitDataList()
	_serverContestNoOutfitDataList = {} -- Clear the existing list
	for _, contestSaveData in _serverContestContainerSaveData.Contests do
		local contestData = {
			TemplateId = contestSaveData.TemplateId, -- Store the template ID
			Style = contestSaveData.Style, -- Store the style
			Id = contestSaveData.Id, -- Store the contest ID
			EndTime = contestSaveData.EndTime, -- Store the end time
			CanVote = contestSaveData.CanVote, -- Store the voting status
			ContestOutfits = {}, -- Initialize an empty list for outfits
		}
		table.insert(_serverContestNoOutfitDataList, contestData) -- Add the contest data to the list
	end
end

-- Local function to check for new contests based on templates
local function CheckForNewContests()
	for i, contestTemplate in ipairs(_contestTemplates) do
		local found = false
		for j, contestSaveData in ipairs(_serverContestContainerSaveData.Contests) do
			if contestSaveData.TemplateId == contestTemplate.Id and IsContestInProgress(contestSaveData) then
				found = true -- Mark as found if contest is in progress
				break
			end
		end
		if not found then
			StartContest(contestTemplate) -- Start a new contest if not found
		end
	end
end

-- Local function to purge completed contests
local function PurgeCompletedContests(): boolean
	local purged = false
	for i = #_serverContestContainerSaveData.Contests, 1, -1 do
		local contestData = _serverContestContainerSaveData.Contests[i]
		if CanContestBePurged(contestData) then
			table.remove(_serverContestContainerSaveData.Contests, i) -- Remove the contest from the list
			print("Contest purged: " .. contestData.Id) -- Print the purged contest ID
			purged = true
			_serverDataDirty = true -- Mark server data as dirty
		end
	end
	return purged -- Return whether any contests were purged
end

-- Local function to purge player data for contests that no longer exist
local function PurgePlayerDataContests(playerContestContainerData: PlayerContestContainerSaveData)
	for i = #playerContestContainerData.ContestList, 1, -1 do
		local contestData = playerContestContainerData.ContestList[i]
		local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestData.ContestId)
		if contestSaveData == nil then
			print("purging player contest data for contest: " .. contestData.ContestId) -- Print the contest ID being purged
			table.remove(playerContestContainerData.ContestList, i) -- Remove the contest data from the player's list
		end
	end
end

-- Local function to save player contest data
local function SavePlayerContestData(player: Player)
	local playerContainerData = GetPlayerContestContainerSaveData(player.user.id) -- Get player contest data
	PurgePlayerDataContests(playerContainerData) -- Purge any invalid contest data
	SaveManager.SaveDataForPlayer(player, PlayerContestKey, playerContainerData) -- Save the player contest data
end

-- Local function to update contests (purge completed contests and check for new ones)
local function UpdateContests()
	PurgeCompletedContests() -- Purge completed contests
	CheckForNewContests() -- Check for new contests
end

-- Local function to create a new contest container
local function CreateNewContestContainer(): ContestContainerSaveData
	return {
		Contests = {}, -- Initialize an empty list of contests
		ContestNumber = 0, -- Start with contest number 0
		Version = 1, -- Set initial version to 1
	}
end

-- Local function to get the next contest number
local function GetNextContestNumber(): number
	if _serverContestContainerSaveData.ContestNumber == nil then
		_serverContestContainerSaveData.ContestNumber = 1 -- Initialize contest number if nil
	end
	_serverContestContainerSaveData.ContestNumber = _serverContestContainerSaveData.ContestNumber + 1 -- Increment contest number
	return _serverContestContainerSaveData.ContestNumber -- Return the next contest number
end

-- Local function to get local vote data for a specific contest and player
local function GetLocalVoteData(contestId: string, playerId: string): LocalOutfitVotes
	local localVotesList = _contestOutfitLocalVotes[playerId] -- Get local votes for the player
	if localVotesList == nil then
		localVotesList = {} -- Initialize if nil
		_contestOutfitLocalVotes[playerId] = localVotesList -- Store the local votes
	end
	-- Find votes based on contest Id
	local contestVotes = nil
	for i, votes in ipairs(localVotesList) do
		if votes.ContestId == contestId then
			contestVotes = votes -- Set contest votes if found
			break
		end
	end
	if contestVotes == nil then
		contestVotes = {
			ContestId = contestId, -- Set contest ID
			PlayerId = playerId, -- Set player ID
			Score = 0, -- Initialize score
			TotalVotes = 0, -- Initialize total votes
		}
		table.insert(localVotesList, contestVotes) -- Add to local votes list
	end
	return contestVotes -- Return the local vote data
end

-- Local function to merge votes from local data into the contest outfit data
local function MergeVotes(
	contestId: string,
	contestOutfit: ContestOutfitSaveData,
	newContestOutfit: ContestOutfitSaveData
)
	local localVotes = GetLocalVoteData(contestId, newContestOutfit.PlayerId) -- Get local votes for the new outfit
	contestOutfit.TotalVotes = newContestOutfit.TotalVotes + localVotes.TotalVotes -- Update total votes
	contestOutfit.Score = newContestOutfit.Score + localVotes.Score -- Update score

	print(
		"Merging votes for player: "
			.. newContestOutfit.PlayerId
			.. " score: "
			.. contestOutfit.Score
			.. " total votes: "
			.. contestOutfit.TotalVotes
			.. " added local score: "
			.. localVotes.Score
			.. " added local votes: "
			.. localVotes.TotalVotes
	)
end

-- Local function to merge outfit save data from new and old contest containers
local function MergeContestOutfitsSaveData(
	newContestContainer: ContestContainerSaveData,
	oldContainer: ContestContainerSaveData,
	contestId: string
)
	local newContest = GetContestSaveData(newContestContainer, contestId) -- Get new contest data
	local contest = GetContestSaveData(oldContainer, contestId) -- Get old contest data
	for i, newContestOutfit in ipairs(newContest.ContestOutfits) do
		local found = false
		for j, contestOutfit in ipairs(contest.ContestOutfits) do
			if contestOutfit.PlayerId == newContestOutfit.PlayerId then
				found = true -- Mark as found if player ID matches
				-- Merge the scores
				MergeVotes(contestId, contestOutfit, newContestOutfit)
				break
			end
		end
		if not found then
			print("Merging: Adding new contest outfit for player: " .. newContestOutfit.PlayerId)
			table.insert(contest.ContestOutfits, newContestOutfit) -- Add new outfit if not found
		end
	end
	return nil
end

-- Local function to merge changes from a new contest container into an old one
local function MergeChanges(
	newContestContainer: ContestContainerSaveData,
	oldContainer: ContestContainerSaveData
): ContestContainerSaveData
	print(
		"Merging contest container changes for version: "
			.. tostring(newContestContainer.Version + 1)
			.. " from version: "
			.. oldContainer.Version
	)
	oldContainer.Version = oldContainer.Version + 1 -- Increment the version of the old container

	-- Merge contests
	for i, newContestSaveData in ipairs(newContestContainer.Contests) do
		local found = false
		for j, contestSaveData in ipairs(oldContainer.Contests) do
			if contestSaveData.Id == newContestSaveData.Id then
				found = true -- Mark as found if contest ID matches
				MergeContestOutfitsSaveData(newContestContainer, oldContainer, contestSaveData.Id) -- Merge outfit data
				break
			end
		end
		if not found then
			print("Merging: Adding new contest: " .. newContestSaveData.Id)
			table.insert(oldContainer.Contests, newContestSaveData) -- Add new contest if not found
		end
	end
	return oldContainer -- Return the updated old container
end

-- Local function to send updated contest data to clients
local function SendClientsUpdatedContestData(player: Player)
	FillNoOutfitDataList() -- Fill the list of contests without outfits
	ContestListResponseEvent:FireClient(
		player,
		_serverContestNoOutfitDataList,
		GetPlayerContestContainerSaveData(player.user.id)
	) -- Send data to the client
end

-- Local function to save the contest container data
local function SaveContestContainer()
	print("Saving contest container version: " .. _serverContestContainerSaveData.Version)
	SaveManager.UpdateGlobalData(ContestContainerKey, function(newContestContainer)
		if newContestContainer == nil then
			print("new contest container is nil")
			return _serverContestContainerSaveData -- Return existing data if new data is nil
		end

		-- Check if the version is the same, if so increment the version and save
		if newContestContainer.Version == _serverContestContainerSaveData.Version then
			_serverContestContainerSaveData.Version = _serverContestContainerSaveData.Version + 1 -- Increment version
			print("Versions are the same, incrementing version")
			return _serverContestContainerSaveData -- Return existing data
		end
		-- If the version is different, merge the changes
		return MergeChanges(newContestContainer, _serverContestContainerSaveData)
	end, function()
		table.clear(_contestOutfitLocalVotes) -- Clear local votes after saving
		_serverDataDirty = false -- Mark server data as clean
	end)
end

-- Function to start a new contest based on a contest template
function StartContest(contestTemplate: ContestTemplate)
	local endTime = _startDateTemplate.FindPreviousTimeToStart(contestTemplate.Duration) + contestTemplate.Duration -- Calculate end time
	local style = contestTemplate.GetRandomStyle(endTime) -- Get a random style for the contest
	local contestSaveData = {
		TemplateId = contestTemplate.Id, -- Set template ID
		Style = style, -- Set style
		Id = contestTemplate.Id .. "_" .. GetNextContestNumber(), -- Generate unique contest ID
		CanVote = false, -- Set initial voting status
		EndTime = endTime, -- Set end time
		ContestOutfits = {}, -- Initialize empty list for outfits
	}

	print("Contest started: " .. contestSaveData.Id .. " end time: " .. GM.Utils.GetDateString(contestSaveData.EndTime))

	-- Add to save data and list
	table.insert(_serverContestContainerSaveData.Contests, contestSaveData) -- Add contest to the server data
	_serverDataDirty = true -- Mark server data as dirty

	ContestStartedEvent:FireAllClients(contestSaveData) -- Notify all clients that a contest has started
end

-- Local function to handle contest data loading
local function OnContestDataLoaded(data)
	_serverContestContainerSaveData = data -- Load contest data

	if _serverContestContainerSaveData == nil then
		_serverContestContainerSaveData = CreateNewContestContainer() -- Create new contest container if nil
		print("created new contest container")
		SaveManager.SaveGlobalData(ContestContainerKey, _serverContestContainerSaveData) -- Save the new container
	end

	-- GM.Utils.PrintTable(_serverContestContainerSaveData)

	local activeContests = 0
	for i, contestSaveData in ipairs(_serverContestContainerSaveData.Contests) do
		local contestTemplate = GetContestTemplate(contestSaveData.TemplateId) -- Get the contest template
		if contestTemplate then
			if IsContestInProgress(contestSaveData) then
				activeContests = activeContests + 1 -- Count active contests
			end
			print(
				"Loaded contest: "
					.. contestSaveData.Id
					.. " end time: "
					.. GM.Utils.GetDateString(contestSaveData.EndTime)
			) -- Print loaded contest data
		end
	end

	UpdateContests() -- Update contests after loading
end

-- Local function to load contest container save data
local function LoadContestContainerSaveData()
	SaveManager.LoadGlobalData(ContestContainerKey, OnContestDataLoaded) -- Load global contest data
end

-- Local function to clear all contests (for testing purposes)
local function ClearAllContests()
	if not _cheatsEnabled then
		return -- Do nothing if cheats are not enabled
	end
	_serverContestContainerSaveData = CreateNewContestContainer() -- Create a new contest container
	SaveManager.SaveGlobalData(ContestContainerKey, _serverContestContainerSaveData) -- Save the new container
	table.clear(_contestOutfitLocalVotes) -- Clear local votes
	_serverDataDirty = false -- Mark server data as clean
end

-- Local function to handle post outfit addition logic
local function PostAddOutfit(contestSaveData: ContestSaveData)
	print("Post add outfit " .. #contestSaveData.ContestOutfits .. " outfits")
	if #contestSaveData.ContestOutfits >= _minOutfitsForVoting then
		contestSaveData.CanVote = true -- Allow voting if minimum outfits are submitted
	end
end

-- Local function to handle outfit add requests from players
local function OnOutfitAddRequest(player: Player, contestId: string, outfitData: OutfitSaveData, fakePlayerId: string)
	local playerContainerData: PlayerContestContainerSaveData = GetPlayerContestContainerSaveData(player.user.id) -- Get player contest data
	local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestId) -- Get contest data
	if not IsContestValid(contestSaveData) then
		ContestOutfitAddResponseEvent:FireClient(player, ErrorCode.ContestNotInProgress, playerContainerData) -- Notify client if contest is not valid
		return
	end

	local playerId = player.user.id -- Get player ID
	if fakePlayerId then
		playerId = fakePlayerId -- Use fake player ID if provided
	end

	if outfitData == nil or #outfitData.Colors ~= #outfitData.Ids or #outfitData.Ids > 100 then
		print("Invalid outfit data") -- Print error if outfit data is invalid
		ContestOutfitAddResponseEvent:FireClient(player, ErrorCode.ContestOutfitNotFound, playerContainerData) -- Notify client of error
		return
	end

	local contestOutfitSaveData = GetContestOutfitForPlayer(playerId, contestSaveData) -- Get existing outfit data for the player
	if contestOutfitSaveData then
		print("Outfit already submitted for player: " .. playerId) -- Print error if outfit already submitted
		ContestOutfitAddResponseEvent:FireClient(player, ErrorCode.ContestOutfitAlreadySubmitted, playerContainerData) -- Notify client of error
		return
	end

	local playerContestData: PlayerContestSaveData = GetPlayerContestData(playerContainerData, contestId) -- Get player contest data
	local contestTemplate = GetContestTemplate(contestSaveData.TemplateId) -- Get contest template
	local playerSaveData = SaveManager.ServerGetPlayerData(playerId) -- Get player save data
	if not PlayerHasTickets(playerSaveData, contestTemplate.TicketCost) then
		print("Player does not have enough tickets") -- Print error if player does not have enough tickets
		ContestOutfitAddResponseEvent:FireClient(player, ErrorCode.ContestNotEnoughTickets, playerContainerData) -- Notify client of error
		return
	end

	contestOutfitSaveData = {
		PlayerId = playerId, -- Set player ID
		OutfitData = outfitData, -- Set outfit data
		Score = 0, -- Initialize score
		TotalVotes = 0, -- Initialize total votes
	}
	print("Outfit added for player: " .. playerId) -- Print confirmation of outfit addition
	table.insert(contestSaveData.ContestOutfits, contestOutfitSaveData) -- Add outfit to contest data
	PostAddOutfit(contestSaveData) -- Handle post outfit addition logic

	playerContestData.Submitted = true -- Mark the contest as submitted
	SavePlayerContestData(player) -- Save player contest data

	local playerSaveData = SaveManager.ServerGetPlayerData(playerId) -- Get player save data again
	SaveManager.SpendCurrency(playerSaveData, "ticket", contestTemplate.TicketCost) -- Deduct ticket cost
	SaveManager.ServerSavePlayerData(player, playerSaveData, function()
		ContestOutfitAddResponseEvent:FireClient(player, ErrorCode.None, playerContainerData) -- Notify client of successful addition
	end, true)

	_serverDataDirty = true -- Mark server data as dirty
end

-- Local function to print vote records for debugging
local function PrintVoteRecord(contestOutfit1: ContestOutfitSaveData, contestOutfit2: ContestOutfitSaveData)
	local voteString = "Outfit 1: "
		.. contestOutfit1.PlayerId
		.. " Score: "
		.. contestOutfit1.Score
		.. " Total votes: "
		.. contestOutfit1.TotalVotes
		.. "Outfit 2: "
		.. contestOutfit2.PlayerId
		.. " Score: "
		.. contestOutfit2.Score
		.. " Total votes: "
		.. contestOutfit2.TotalVotes
	print(voteString) -- Print the vote record
end

-- Local function to update local vote data for outfits
local function UpdateLocalVoteData(
	contestId: string,
	contestOutfit1: ContestOutfitSaveData,
	contestOutfit2: ContestOutfitSaveData
)
	local localVotes = GetLocalVoteData(contestId, contestOutfit1.PlayerId) -- Get local votes for the first outfit
	localVotes.Score = localVotes.Score + 1 -- Increment score for the first outfit
	localVotes.TotalVotes = localVotes.TotalVotes + 1 -- Increment total votes for the first outfit

	localVotes = GetLocalVoteData(contestId, contestOutfit2.PlayerId) -- Get local votes for the second outfit
	localVotes.TotalVotes = localVotes.TotalVotes + 1 -- Increment total votes for the second outfit
end

-- Local function to record a vote for a contest outfit
local function ServerRecordVote(player: Player, contestId: string, player1Id: string, player2Id: string): boolean
	local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestId) -- Get contest data
	local contestOutfit1: ContestOutfitSaveData = nil -- Initialize first outfit data
	local contestOutfit2: ContestOutfitSaveData = nil -- Initialize second outfit data
	for i, contestOutfitSaveData in ipairs(contestSaveData.ContestOutfits) do
		if contestOutfitSaveData.PlayerId == player1Id then
			contestOutfit1 = contestOutfitSaveData -- Set first outfit data if found
		elseif contestOutfitSaveData.PlayerId == player2Id then
			contestOutfit2 = contestOutfitSaveData -- Set second outfit data if found
		end
	end

	if contestOutfit1 == nil or contestOutfit2 == nil then
		print("Contest outfit not found") -- Print error if outfits are not found
		return false -- Return false if outfits are not found
	end

	if contestOutfit1.PlayerId == player.user.id or contestOutfit2.PlayerId == player.user.id then
		print("Player cannot vote for their own outfit") -- Print error if player tries to vote for their own outfit
		return false -- Return false if player tries to vote for their own outfit
	end

	-- Check if player has already voted for one of these players
	local playerContestData = GetContestDataForPlayer_Server(player.user.id, contestId) -- Get player contest data
	if
		GM.Utils.IsInTable(playerContestData.PlayersVotedFor, player1Id)
		or GM.Utils.IsInTable(playerContestData.PlayersVotedFor, player2Id)
	then
		print("Player has already voted for one of these players") -- Print error if player has already voted
		return false -- Return false if player has already voted
	end

	print("Vote recorded for player: " .. player.user.id .. " for players " .. player1Id .. " and " .. player2Id) -- Print confirmation of vote recording
	-- Increment the score for the outfit voted for
	contestOutfit1.Score = contestOutfit1.Score + 1 -- Increment score for the first outfit
	contestOutfit1.TotalVotes = contestOutfit1.TotalVotes + 1 -- Increment total votes for the first outfit
	contestOutfit2.TotalVotes = contestOutfit2.TotalVotes + 1 -- Increment total votes for the second outfit

	table.insert(playerContestData.PlayersVotedFor, player1Id) -- Add the voted player to the list

	-- Check if the player earned a ticket
	if #playerContestData.PlayersVotedFor % _votesPerTicket == 0 then
		local playerSaveData = SaveManager.ServerGetPlayerData(player.user.id) -- Get player save data
		SaveManager.AddCurrency(playerSaveData, "ticket", 1) -- Add a ticket to the player
		SaveManager.ServerSavePlayerData(player, playerSaveData, nil, true) -- Save player data
	end

	UpdateLocalVoteData(contestId, contestOutfit1, contestOutfit2) -- Update local vote data
	return true -- Return true to indicate success
end

-- Local function to handle outfit vote requests from players
local function OnOutfitVoteRequest(player: Player, contestId: string, player1Ids: { string }, player2Ids: { string })
	local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestId) -- Get contest data
	if not IsContestValid(contestSaveData) then
		return -- Do nothing if contest is not valid
	end

	if #player1Ids ~= #player2Ids then
		print("Invalid vote request") -- Print error if vote request is invalid
		return -- Do nothing if vote request is invalid
	end

	local savePlayerData = false -- Flag to indicate if player data needs to be saved
	for i, player1Id in ipairs(player1Ids) do
		local player2Id = player2Ids[i] -- Get corresponding player ID
		local success = ServerRecordVote(player, contestId, player1Id, player2Id) -- Record the vote
		if success then
			savePlayerData = true -- Mark to save player data if vote was successful
		end
	end

	if savePlayerData then
		_serverDataDirty = true -- Mark server data as dirty
		SavePlayerContestData(player) -- Save player contest data
	end
end

-- Local function to handle requests for voting blocks
local function OnRequestVotingBlock(player: Player, contestId: string)
	local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestId) -- Get contest data
	if not IsContestValid(contestSaveData) then
		return -- Do nothing if contest is not valid
	end

	-- Find the outfits with the smallest number of votes
	local playerContainerData = GetPlayerContestContainerSaveData(player.user.id) -- Get player contest data
	local playerContestData = GetContestDataForPlayer_Server(player.user.id, contestId) -- Get player contest data
	local contestOutfits = {}
	for i, contestOutfitSaveData in ipairs(contestSaveData.ContestOutfits) do
		if contestOutfitSaveData.PlayerId == player.user.id then
			continue -- Skip if the outfit belongs to the player
		end

		if GM.Utils.IsInTable(playerContestData.PlayersVotedFor, contestOutfitSaveData.PlayerId) then
			continue -- Skip if the player has already voted for this outfit
		end

		table.insert(contestOutfits, contestOutfitSaveData) -- Add outfit to the list
	end

	-- Sort outfits by total votes and score
	table.sort(contestOutfits, function(a, b)
		if a.TotalVotes == b.TotalVotes then
			return a.Score < b.Score -- Sort by score if total votes are equal
		end
		return a.TotalVotes < b.TotalVotes -- Sort by total votes
	end)

	-- Remove the outfits except the first few
	while #contestOutfits > _voteOutfitsSentPerRequest * 2 do
		table.remove(contestOutfits) -- Remove excess outfits
	end

	ContestVotingBlockResponseEvent:FireClient(player, contestOutfits, playerContainerData) -- Send the voting block response to the client
end

-- Local function to handle placement requests from players
local function OnPlacementRequest(player: Player, contestId: string)
	local playerContainerData = GetPlayerContestContainerSaveData(player.user.id) -- Get player contest data
	local contestSaveData = GetContestSaveData(_serverContestContainerSaveData, contestId) -- Get contest data
	if not contestSaveData then
		print("Contest not valid " .. contestId) -- Print error if contest is not valid
		PlacementResponseEvent:FireClient(player, ErrorCode.ContestNotInProgress, nil, 0, nil, playerContainerData) -- Notify client of error
		return
	end

	local playerContestData = GetContestDataForPlayer_Server(player.user.id, contestId) -- Get player contest data
	if not playerContestData.Submitted then
		print("Player has not submitted an outfit") -- Print error if player has not submitted
		PlacementResponseEvent:FireClient(player, ErrorCode.NotSubmitted, nil, 0, nil, playerContainerData) -- Notify client of error
		return
	end

	local contestOutfit = GetContestOutfitForPlayer(player.user.id, contestSaveData) -- Get the player's contest outfit
	if contestOutfit == nil then
		print("Contest outfit not found") -- Print error if outfit is not found
		PlacementResponseEvent:FireClient(player, ErrorCode.ContestOutfitNotFound, nil, 0, nil, playerContainerData) -- Notify client of error
		return
	end

	-- Sort the outfits by score
	table.sort(contestSaveData.ContestOutfits, function(a, b)
		local aScore = GetOutfitScore(a, contestSaveData) -- Get score for the first outfit
		local bScore = GetOutfitScore(b, contestSaveData) -- Get score for the second outfit
		if aScore == bScore then
			return a.TotalVotes < b.TotalVotes -- Sort by total votes if scores are equal
		end
		return aScore > bScore -- Sort by score
	end)

	local placement = 1 -- Initialize placement
	for i, contestOutfitSaveData in ipairs(contestSaveData.ContestOutfits) do
		if contestOutfitSaveData.PlayerId == player.user.id then
			break -- Stop if the player's outfit is found
		end
		placement = placement + 1 -- Increment placement
	end

	local contestTemplate = GetContestTemplate(contestSaveData.TemplateId) -- Get contest template
	local topOutfits = {}
	for i = 1, contestTemplate.TopPlayerCount do
		if i > #contestSaveData.ContestOutfits then
			break -- Stop if there are no more outfits
		end
		table.insert(topOutfits, contestSaveData.ContestOutfits[i]) -- Add top outfits to the list
	end

	-- Add the player's outfit to the top outfits if they are outside the top player count
	if placement > contestTemplate.TopPlayerCount then
		table.insert(topOutfits, contestOutfit) -- Add player's outfit to the top outfits
	end

	-- If the player hasn't received rewards yet, add them
	local rewards: { Types.GameItemAmount } = {}
	if not playerContestData.ReceivedReward then
		playerContestData.ReceivedReward = true -- Mark as received
		local lootContainer = contestTemplate.GetReward(placement) -- Get rewards based on placement
		rewards = GM.LootManager.Roll(lootContainer) -- Roll for rewards
		GM.SaveManager.ServerAddRewardsFromLootContainer(player, rewards, true) -- Add rewards to the player
	end

	SavePlayerContestData(player) -- Save player contest data
	-- Convert rewards to RewardSaveData
	local rewardsList: { SaveManager.RewardSaveData } = SaveManager.ConvertGameAmountToSaveDataRewards(rewards) -- Convert rewards
	PlacementResponseEvent:FireClient(player, ErrorCode.None, topOutfits, placement, rewardsList, playerContainerData) -- Send placement response to the client
end

-- Local function to save global data if it has changed
local function SaveGlobalData()
	if _serverDataDirty then
		SaveContestContainer() -- Save contest container if data is dirty
	end
end

-- Local function to handle player joining the server
local function OnPlayerJoined(player: Player)
	local contestContainer = SaveManager.LoadDataForPlayer(
		player,
		PlayerContestKey,
		function(data: PlayerContestContainerSaveData)
			if data then
				_playerContainerSaveList[player.user.id] = data -- Load player contest data
				print("Loaded player contest container for player: " .. player.user.id) -- Print confirmation
				GM.Utils.PrintTable(data) -- Print loaded data
			else
				local playerData = CreatePlayerContestContainerData() -- Create new player data if none exists
				_playerContainerSaveList[player.user.id] = playerData -- Store the new data
			end
		end
	)
end

-- Local function to handle player leaving the server
local function OnPlayerLeft(player: Player)
	_playerContainerSaveList[player.user.id] = nil -- Remove player data from the list

	-- Count how many players are in the list
	local count = 0
	for _, _ in pairs(_playerContainerSaveList) do
		count = count + 1 -- Increment count for each player
	end
	-- Force save data if all players are leaving to prevent data loss if server shuts down
	if count <= 1 then
		SaveGlobalData() -- Save global data if only one player is left
	end
end

-- Function to initialize the server
function self.ServerAwake()
	LoadContestContainerSaveData() -- Load contest container data

	Timer.Every(_saveInterval, SaveGlobalData) -- Set up a timer to save global data at intervals

	-- Connect events to their respective handlers
	ContestOutfitAddRequestEvent:Connect(OnOutfitAddRequest)
	ContestOutfitVoteRequestEvent:Connect(OnOutfitVoteRequest)
	ContestListRequestEvent:Connect(SendClientsUpdatedContestData)
	ContestVotingBlockRequestEvent:Connect(OnRequestVotingBlock)
	PlacementRequestEvent:Connect(OnPlacementRequest)

	-- Connect cheat commands for testing
	TestAddPlayersEvent:Connect(OnAddTestPlayers_Server)
	ClearAllContestsRequestEvent:Connect(ClearAllContests)
	AddTicketsEventCheatEvent:Connect(OnAddTicketsCheat_Server)
	ClearPlayerDataRequestEvent:Connect(ClearPlayerDataRequest_Server)
	SetVotesCheatRequestEvent:Connect(SetContestVotesCheat_Server)

	-- Connect player join and leave events
	server.PlayerConnected:Connect(OnPlayerJoined)
	server.PlayerDisconnected:Connect(OnPlayerLeft)

	Timer.Every(1, UpdateContests) -- Set up a timer to update contests every second

	-- TestMerge() -- Uncomment for testing merge functionality
end

-------------------------------------------------------------------------------
-- Cheat Commands
-------------------------------------------------------------------------------

-- Local function to add test players for contests
function OnAddTestPlayers_Server(player: Player, outfitDataList: { OutfitSaveData })
	if not _cheatsEnabled then
		return
	end -- Do nothing if cheats are not enabled

	local contestSaveData = _serverContestContainerSaveData.Contests[#_serverContestContainerSaveData.Contests] -- Get the latest contest
	if #contestSaveData.ContestOutfits > 0 then
		return -- Do nothing if outfits already exist
	end

	local count = 1
	for _, outfit in ipairs(outfitDataList) do
		local score = 0 -- Initialize score
		contestOutfitSaveData = {
			PlayerId = "test player " .. count, -- Set test player ID
			OutfitData = outfit, -- Set outfit data
			Score = score, -- Set score
			TotalVotes = 0, -- Initialize total votes
		}
		table.insert(contestSaveData.ContestOutfits, contestOutfitSaveData) -- Add outfit to the contest
		count = count + 1 -- Increment count
		_serverDataDirty = true -- Mark server data as dirty
	end

	PostAddOutfit(contestSaveData) -- Handle post outfit addition logic
	print("Added test players") -- Print confirmation
end

-- Local function to add tickets to a player's account for testing
function OnAddTicketsCheat_Server(player: Player, ticketCount: number)
	if not _cheatsEnabled then
		return
	end -- Do nothing if cheats are not enabled

	local playerSaveData = SaveManager.ServerGetPlayerData(player.user.id) -- Get player save data
	SaveManager.AddCurrency(playerSaveData, "ticket", ticketCount) -- Add tickets to the player
	SaveManager.ServerSavePlayerData(player, playerSaveData, nil, true) -- Save player data
end

-- Local function to clear player data for testing
function ClearPlayerDataRequest_Server(player: Player)
	if not _cheatsEnabled then
		return
	end -- Do nothing if cheats are not enabled
	SaveManager.DeleteDataForPlayer(player, PlayerContestKey) -- Delete player contest data

	local playerData = CreatePlayerContestContainerData() -- Create new player data
	_playerContainerSaveList[player.user.id] = playerData -- Store the new data
end

-- Local function to set contest votes for a player for testing
function SetContestVotesCheat_Server(player: Player, score: number, votes: number)
	-- Find all contests the player is submitted in
	for i, contestSaveData in ipairs(_serverContestContainerSaveData.Contests) do
		if not IsContestInProgress(contestSaveData) then
			continue -- Skip if contest is not in progress
		end
		for j, contestOutfitSaveData in ipairs(contestSaveData.ContestOutfits) do
			if contestOutfitSaveData.PlayerId == player.user.id then
				contestOutfitSaveData.Score = score -- Set score for the player's outfit
				contestOutfitSaveData.TotalVotes = votes -- Set total votes for the player's outfit
				_serverDataDirty = true -- Mark server data as dirty
				print("Set votes for player: " .. player.user.id) -- Print confirmation
				break
			end
		end
	end
end

-- Local function to set up test contest players
function SetupTestContestPlayers()
	local outfitDataList = {}
	for i = 1, #_testCharacterOutfits do
		local outfit = GM.OutfitUtils.SerializeOutfitToOutfitSaveData(_testCharacterOutfits[i]) -- Serialize outfit data
		table.insert(outfitDataList, outfit) -- Add to the list
	end
	TestAddPlayersEvent:FireServer(outfitDataList) -- Fire event to add test players
end

-- Function to add tickets using cheat commands
function AddTicketsCheat(arguments: { string })
	local ticketCount = tonumber(arguments[1]) -- Get ticket count from arguments
	AddTicketsEventCheatEvent:FireServer(ticketCount) -- Fire event to add tickets
end

-- Function to clear all contests using cheat commands
function ClientClearAllContests()
	ClearAllContestsRequestEvent:FireServer() -- Fire event to clear all contests
end

-- Function to clear player data using cheat commands
function ClearPlayerDataRequest()
	ClearPlayerDataRequestEvent:FireServer() -- Fire event to clear player data
end

-- Function to set contest votes using cheat commands
function SetContestVotesCheat(arguments: { string })
	local score: number = tonumber(arguments[1]) or 0 -- Get score from arguments
	local votes: number = tonumber(arguments[2]) or 0 -- Get votes from arguments
	SetVotesCheatRequestEvent:FireServer(score, votes) -- Fire event to set votes
end

-- Local function to test merging contest data
local function TestMerge()
	local firstContainer = CreateNewContestContainer() -- Create first contest container
	firstContainer.ContestNumber = 1 -- Set contest number
	firstContainer.Version = 2 -- Set version
	local contestSaveData: ContestSaveData = {
		TemplateId = "test", -- Set template ID
		Style = "test", -- Set style
		Id = "test", -- Set contest ID
		CanVote = false, -- Set voting status
		EndTime = os.time() + 1000, -- Set end time
		ContestOutfits = {}, -- Initialize empty list for outfits
	}
	-- Add some outfits
	for i = 1, 5 do
		local contestOutfitSaveData: ContestOutfitSaveData = {
			PlayerId = "test player " .. i, -- Set test player ID
			OutfitData = nil, -- Set outfit data
			Score = i, -- Set score
			TotalVotes = i * 5, -- Set total votes
		}
		table.insert(contestSaveData.ContestOutfits, contestOutfitSaveData) -- Add outfit to the contest
	end
	table.insert(firstContainer.Contests, contestSaveData) -- Add contest to the first container

	print("First container data") -- Print first container data
	GM.Utils.PrintTable(firstContainer) -- Print table

	local secondContainer = CreateNewContestContainer() -- Create second contest container
	secondContainer.ContestNumber = 1 -- Set contest number
	secondContainer.Version = 1 -- Set version
	contestSaveData = {
		TemplateId = "test", -- Set template ID
		Style = "test", -- Set style
		Id = "test", -- Set contest ID
		CanVote = false, -- Set voting status
		EndTime = os.time() + 1000, -- Set end time
		ContestOutfits = {}, -- Initialize empty list for outfits
	}
	table.insert(secondContainer.Contests, contestSaveData) -- Add contest to the second container
	for i = 1, 5 do
		local contestOutfitSaveData: ContestOutfitSaveData = {
			PlayerId = "test player " .. i, -- Set test player ID
			OutfitData = nil, -- Set outfit data
			Score = i, -- Set score
			TotalVotes = i * 2, -- Set total votes
		}
		table.insert(contestSaveData.ContestOutfits, contestOutfitSaveData) -- Add outfit to the contest
	end

	_contestOutfitLocalVotes = {} -- Clear local votes
	-- Add local votes
	for i = 1, 5 do
		local localVotes = GetLocalVoteData("test", "test player " .. i) -- Get local vote data
		localVotes.Score = i -- Set score for local votes
		localVotes.TotalVotes = i -- Set total votes for local votes
	end

	GM.Utils.PrintTable(secondContainer) -- Print second container data
	MergeChanges(firstContainer, secondContainer) -- Merge changes from first to second container
	GM.Utils.PrintTable(secondContainer) -- Print merged container data
end

-------------------------------------------------------------------------------
-- Client Functions
-------------------------------------------------------------------------------

-- Local function to update player contest container data on the client
local function ClientUpdatePlayerContainerData(playerContestData: PlayerContestContainerSaveData)
	_clientPlayerContestContainerData = playerContestData -- Update client data
end

-- Function to get player container data on the client
function ClientGetPlayerContainerData()
	return _clientPlayerContestContainerData -- Return client player contest data
end

-- Function to cast a vote for a contest outfit
function CastVote(contestSaveData: ContestSaveData, player1Ids: { string }, player2Ids: { string })
	ContestOutfitVoteRequestEvent:FireServer(contestSaveData.Id, player1Ids, player2Ids) -- Fire event to cast vote
end

-- Function to request a voting block for a contest
function RequestVotingBlock(contestSaveData: ContestSaveData, callback: ({ ContestOutfitSaveData }) -> ())
	ContestVotingBlockRequestEvent:FireServer(contestSaveData.Id) -- Fire event to request voting block
	_voteBlockResponseCallback = callback -- Store callback for response
end

-- Function to submit an outfit for a contest
function SubmitOutfitForContest(
	contestId: string,
	outfitData: OutfitSaveData,
	fakePlayerId: string | nil,
	callback: (number) -> ()
)
	ContestOutfitAddRequestEvent:FireServer(contestId, outfitData, fakePlayerId) -- Fire event to submit outfit
	_addOutfitResponseCallback = callback -- Store callback for response
end

-- Function to get all contests on the client
function ClientGetAllContests(): { ContestSaveData }
	return _clientContestDataList -- Return list of contests
end

-- Function to get active contests on the client
function GetActiveContests(): { ContestSaveData }
	local activeContests = {} -- Initialize list for active contests
	for i, contestSaveData in ipairs(_clientContestDataList) do
		if IsContestInProgress(contestSaveData) then
			table.insert(activeContests, contestSaveData) -- Add active contest to the list
		end
	end
	return activeContests -- Return list of active contests
end

-- Function to request the contest list from the server
function RequestContestList(callback: ({ ContestSaveData }) -> () | nil)
	ContestListRequestEvent:FireServer() -- Fire event to request contest list
	_requestContestListCallback = callback -- Store callback for response
end

-- Function to request placement for a contest
function RequestPlacementForContest(
	contestId: string,
	callback: (number, { ContestOutfitSaveData }, number, { SaveManager.RewardSaveData }) -> ()
)
	PlacementRequestEvent:FireServer(contestId) -- Fire event to request placement
	_placementResponseCallback = callback -- Store callback for response
end

-- Function to initialize the client
function self.ClientAwake()
	-- Connect events to their respective handlers
	ContestListResponseEvent:Connect(function(contestDataList, playerContestData: PlayerContestContainerSaveData)
		print("Received contest list with count " .. #contestDataList) -- Print received contest list count
		ClientUpdatePlayerContainerData(playerContestData) -- Update player contest data
		_clientContestDataList = contestDataList -- Update client contest data list
		if _requestContestListCallback then
			_requestContestListCallback(contestDataList) -- Call the request callback with the contest data
			_requestContestListCallback = nil -- Clear the callback
		end
	end)

	ContestVotingBlockResponseEvent:Connect(
		function(contestOutfitDataList, playerContestData: PlayerContestContainerSaveData)
			ClientUpdatePlayerContainerData(playerContestData) -- Update player contest data
			if _voteBlockResponseCallback then
				_voteBlockResponseCallback(contestOutfitDataList) -- Call the voting block response callback
				_voteBlockResponseCallback = nil -- Clear the callback
			end
		end
	)

	ContestOutfitAddResponseEvent:Connect(function(code: number, playerContestData: PlayerContestContainerSaveData)
		ClientUpdatePlayerContainerData(playerContestData) -- Update player contest data
		if _addOutfitResponseCallback then
			_addOutfitResponseCallback(code) -- Call the outfit add response callback
			_addOutfitResponseCallback = nil -- Clear the callback
		end
	end)

	PlacementResponseEvent:Connect(
		function(
			code: number,
			topOutfits: { ContestOutfitSaveData },
			rank: number,
			rewards: { SaveManager.RewardSaveData },
			playerContestData: PlayerContestContainerSaveData
		)
			ClientUpdatePlayerContainerData(playerContestData) -- Update player contest data
			if _placementResponseCallback then
				_placementResponseCallback(code, topOutfits, rank, rewards) -- Call the placement response callback
				_placementResponseCallback = nil -- Clear the callback
			end
		end
	)

	if GM.GetTestAddDebugPlayersForContest() then
		SetupTestContestPlayers() -- Set up test players if enabled
	end

	Timer.After(1, function()
		RequestContestList(nil) -- Request contest list after a delay
	end)
end
