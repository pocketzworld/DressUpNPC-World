--!Type(Module)

-- Importing required modules
local Utils: Utils = require("Utils") -- Utility functions
local Types: Types = require("Types") -- Type definitions
local LootManager: LootManager = require("LootManager") -- Manages loot-related functionalities

-- Define the PlayerData type, which holds information about a player
export type PlayerData = {
	PlayerId: string, -- Unique identifier for the player
	SeenIntro: boolean, -- Indicates if the player has seen the intro
	CompletedTasks: { string }, -- List of completed task IDs
	RewardList: { RewardSaveData }, -- List of rewards earned by the player
	QuestList: { QuestSaveData }, -- List of quests associated with the player
	ItemsPurchased: { string }, -- List of purchased item IDs
	RepeatCount: number, -- Count of how many times the player has finished
}

-- Define the RewardSaveData type, which holds information about rewards
export type RewardSaveData = {
	Id: string, -- Unique identifier for the reward
	Amount: number, -- Amount of the reward
}

-- Define the QuestSaveData type, which holds information about quests
export type QuestSaveData = {
	Id: string, -- Unique identifier for the quest
	Progress: number, -- Progress made in the quest
}

-- Define the CompleteDressUpResponse type, which is the response structure for dress-up completion
export type CompleteDressUpResponse = {
	Code: number, -- Response code indicating success or failure
	PlayerData: PlayerData, -- The updated player data
	Rewards: { RewardSaveData }, -- List of rewards received from the dress-up task
}

--!SerializeField
local _gameSettings: GameSettings = nil -- Game settings variable

local PlayerDataKey = "playerData" -- Key used to store player data

-- Callback function to be called when player data is loaded
local _onLoadCallback: (playerData: PlayerData) -> () = nil

-- Table to hold player data for all players on the server
local _serverPlayerSaveList: { [string]: PlayerData } = {}

-- Client-side player data
local _clientPlayerData: PlayerData = nil
local _completeDressUpCallback: (response: CompleteDressUpResponse) -> () = nil -- Callback for dress-up completion

-- Events for data loading and saving
local LoadDataRequestEvent = Event.new("LoadDataRequestEvent")
local LoadDataResponseEvent = Event.new("LoadDataResponseEvent")
local SaveDataRequestEvent = Event.new("SaveDataRequestEvent")
local SaveDataResponseEvent = Event.new("SaveDataResponseEvent")
SaveDataLoadedEvent = Event.new("SaveDataLoadedEvent")

-- Dress Up Events
local CompleteDressUpRequestEvent = Event.new("CompleteDressUpRequestEvent")
local CompleteDressUpResponseEvent = Event.new("CompleteDressUpResponseEvent")
local CompleteQuestCheatRequestEvent = Event.new("CompleteQuestCheatRequestEvent")
local CompleteQuestCheatResponseEvent = Event.new("CompleteQuestCheatResponseEvent")
local RestartQuestsRequestEvent = Event.new("RestartQuestsRequestEvent")
local RestartQuestsResponseEvent = Event.new("RestartQuestsResponseEvent")
ResetQuestsEvent = Event.new("ResetQuestsEvent")

-------------------------------------------------------------------------------
-- Server Functions
-------------------------------------------------------------------------------

-- Function to create new player save data
function CreateNewPlayerSaveData(player: Player): PlayerData
	return {
		PlayerId = player.user.id, -- Set player ID
		SeenIntro = false, -- Initialize seen intro to false
		CompletedTasks = {}, -- Initialize completed tasks as empty
		RewardList = {}, -- Initialize reward list as empty
		QuestList = {}, -- Initialize quest list as empty
		ItemsPurchased = {}, -- Initialize purchased items as empty
		RepeatCount = 0, -- Initialize repeat count to zero
	}
end

-- Function to validate and initialize player data fields
local function Validate(playerData: PlayerData)
	if playerData.CompletedTasks == nil then
		playerData.CompletedTasks = {} -- Initialize if nil
	end
	if playerData.RewardList == nil then
		playerData.RewardList = {} -- Initialize if nil
	end
	if playerData.QuestList == nil then
		playerData.QuestList = {} -- Initialize if nil
	end
	if playerData.ItemsPurchased == nil then
		playerData.ItemsPurchased = {} -- Initialize if nil
	end
	if playerData.RepeatCount == nil then
		playerData.RepeatCount = 0 -- Initialize if nil
	end
end

-- Function to load player data from storage
local function ServerLoadPlayerData(player: Player)
	LoadDataForPlayer(player, PlayerDataKey, function(playerData)
		print("Data loaded for player " .. player.user.id) -- Log data loading
		if not playerData then
			print("Creating new player data") -- Log new player data creation
			playerData = CreateNewPlayerSaveData(player) -- Create new data if none exists
		end
		Validate(playerData) -- Validate the loaded data
		_serverPlayerSaveList[player.user.id] = playerData -- Store data in server list
		LoadDataResponseEvent:FireClient(player, playerData) -- Send data back to client
	end)
end

-- Function to handle save data requests from the client
function OnSaveDataRequest(player: Player, data: any)
	ServerSavePlayerData(player, data.playerData, nil, true) -- Save player data
end

-- Function to save player data to storage
function ServerSavePlayerData(
	player: Player,
	playerData: PlayerData,
	callback: (() -> ()) | nil,
	sendClientResponse: boolean
)
	Storage.SetPlayerValue(player, PlayerDataKey, playerData, function(err: StorageError)
		if err ~= StorageError.None then
			error("Failed to save player data: " .. tostring(err)) -- Log error if saving fails
		else
			_serverPlayerSaveList[player.user.id] = playerData -- Update server data list
		end
		if sendClientResponse then
			SaveDataResponseEvent:FireClient(player, playerData) -- Send response back to client
		end
		if callback then
			callback() -- Call the provided callback if it exists
		end
	end)
end

-- Function to load data for a specific player
function LoadDataForPlayer(player: Player, key: string, callback: (data: any) -> ())
	Storage.GetPlayerValue(player, key, function(data)
		callback(data) -- Call the provided callback with the loaded data
	end)
end

-- Function to save data for a specific player
function SaveDataForPlayer(player: Player, key: string, data: any)
	Storage.SetPlayerValue(player, key, data, function(err: StorageError)
		if err ~= StorageError.None then
			error("Failed to save player data: " .. tostring(err)) -- Log error if saving fails
		end
	end)
end

-- Function to delete data for a specific player
function DeleteDataForPlayer(player: Player, key: string)
	Storage.DeletePlayerValue(player, key, function(err: StorageError)
		if err ~= StorageError.None then
			error("Failed to delete player data: " .. tostring(err)) -- Log error if deletion fails
		end
	end)
end

-- Function to load global data
function LoadGlobalData(key: string, callback: (data: any) -> ())
	Storage.GetValue(key, function(data)
		callback(data) -- Call the provided callback with the loaded global data
	end)
end

-- Function to save global data
function SaveGlobalData(key: string, data: any)
	Storage.SetValue(key, data, function(err: StorageError)
		if err ~= StorageError.None then
			error("Failed to save global data: " .. tostring(err)) -- Log error if saving fails
		end
	end)
end

-- Function to update global data with a validator function
function UpdateGlobalData(key: string, validator: (data: any) -> any?, callback: (data: any) -> any)
	Storage.UpdateValue(key, function(data)
		return validator(data) -- Validate and return updated data
	end, callback) -- Call the provided callback with the updated data
end

-- Function to delete global data
function DeleteGlobalData(key: string)
	Storage.DeleteValue(key, function(err: StorageError)
		if err ~= StorageError.None then
			error("Failed to delete global data: " .. tostring(err)) -- Log error if deletion fails
		end
	end)
end

-- Function to get player data from the server list
function ServerGetPlayerData(id: string): PlayerData
	return _serverPlayerSaveList[id] -- Return the player data for the given ID
end

-- Function to handle complete dress-up requests from the client
function OnCompleteDressUpRequest(player: Player, id: string)
	local playerData = _serverPlayerSaveList[player.user.id] -- Get player data
	if not playerData then
		print("Player data not found for player " .. player.user.id) -- Log if data not found
		CompleteDressUpResponseEvent:FireClient(player, { Code = 1, nil, Rewards = {} }) -- Send error response
		return
	end
	if Utils.IsInTable(playerData.CompletedTasks, id) then
		print("Task already completed: " .. id) -- Log if task is already completed
		CompleteDressUpResponseEvent:FireClient(player, { Code = 1, playerData, Rewards = {} }) -- Send error response
		return
	end

	local dressUpTask: DressUpTask? = _gameSettings.GetDressUpTask(id) -- Get the dress-up task
	if not dressUpTask then
		print("DressUpTask not found: " .. id) -- Log if task not found
		CompleteDressUpResponseEvent:FireClient(player, { Code = 1, playerData, Rewards = {} }) -- Send error response
		return
	end

	print("Completed task: " .. id .. ", Saving data") -- Log task completion
	table.insert(playerData.CompletedTasks, id) -- Add task to completed tasks
	local rewards = {}
	if dressUpTask and dressUpTask.LootContainer then
		rewards = LootManager.Roll(dressUpTask.LootContainer) -- Roll for rewards
	end
	ServerAddRewardsFromLootContainer(player, rewards, true) -- Add rewards to player
	local rewardsList: { RewardSaveData } = ConvertGameAmountToSaveDataRewards(rewards) -- Convert rewards to save data format
	local response: CompleteDressUpResponse = { Code = 0, PlayerData = playerData, Rewards = rewardsList } -- Create response
	CompleteDressUpResponseEvent:FireClient(player, response) -- Send response back to client
end

-- Function to handle requests to restart quests for a player
local function OnRequestRestartData(player: Player)
	local playerData = ServerGetPlayerData(player.user.id) -- Get player data
	if not playerData then
		print("Player data not found for player " .. player.user.id) -- Log if data not found
		return
	end

	playerData.CompletedTasks = {} -- Reset completed tasks
	playerData.QuestList = {} -- Reset quest list
	-- Add the contest quest back in
	local contestQuest = _gameSettings.GetQuestTemplateByIndex(1, 5) -- Get contest quest
	if contestQuest then
		table.insert(playerData.QuestList, { Id = contestQuest.Id, Progress = 1 }) -- Add contest quest to the list
	end

	playerData.RepeatCount = playerData.RepeatCount + 1 -- Increment repeat count

	print("reset quests for player " .. player.user.id) -- Log quest reset
	Utils.PrintTable(playerData) -- Print player data for debugging

	ServerSavePlayerData(player, playerData, nil, false) -- Save updated player data
	RestartQuestsResponseEvent:FireClient(player, playerData) -- Send response back to client
end

-- Function to initialize server-side events
function self.ServerAwake()
	LoadDataRequestEvent:Connect(ServerLoadPlayerData) -- Connect load data request event
	SaveDataRequestEvent:Connect(OnSaveDataRequest) -- Connect save data request event

	CompleteDressUpRequestEvent:Connect(OnCompleteDressUpRequest) -- Connect complete dress-up request event

	CompleteQuestCheatRequestEvent:Connect(ServerOnCompleteQuestCheatRequest) -- Connect complete quest cheat request event

	RestartQuestsRequestEvent:Connect(OnRequestRestartData) -- Connect restart quests request event
end

-------------------------------------------------------------------------------
-- Client Functions
-------------------------------------------------------------------------------

-- Function to get the current client player data
function GetClientPlayerData(): PlayerData
	return _clientPlayerData -- Return client player data
end

-- Function to check if player data is loaded
function IsPlayerDataLoaded(): boolean
	return _clientPlayerData ~= nil -- Return true if player data is loaded
end

-- Function to set the client player data
function ClientSetPlayerData(playerData: PlayerData)
	_clientPlayerData = playerData -- Set client player data
end

-- Function to load player data from the server
function LoadPlayerData(OnLoaded: (playerData: PlayerData) -> ())
	_onLoadCallback = OnLoaded -- Set the callback for when data is loaded
	LoadDataRequestEvent:FireServer() -- Request data from the server
end

-- Function to save player data to the server
function SavePlayerData()
	print("Saving data") -- Log saving data
	local data = {
		playerData = _clientPlayerData, -- Prepare data to send
	}

	SaveDataRequestEvent:FireServer(data) -- Send data to the server
end

-- Function to handle data loaded from the server
local function OnDataLoaded(playerData: PlayerData)
	_clientPlayerData = playerData -- Set the loaded player data
	if _onLoadCallback then
		_onLoadCallback(playerData) -- Call the load callback if it exists
	end
	SaveDataLoadedEvent:Fire() -- Fire the data loaded event
end

-- Function to clear player data and create new data
function ClearData()
	_clientPlayerData = CreateNewPlayerSaveData(client.localPlayer) -- Create new player data
	SavePlayerData() -- Save the new data
end

-- Function to initialize client-side events
function self.ClientAwake()
	LoadDataResponseEvent:Connect(OnDataLoaded) -- Connect load data response event

	SaveDataResponseEvent:Connect(function(playerData: PlayerData)
		_clientPlayerData = playerData -- Update client player data on save response
		print("Data saved") -- Log data saved
	end)

	CompleteDressUpResponseEvent:Connect(OnCompleteDressUpResponse) -- Connect complete dress-up response event

	CompleteQuestCheatResponseEvent:Connect(function(playerData: PlayerData)
		_clientPlayerData = playerData -- Update client player data on quest cheat response
	end)

	RestartQuestsResponseEvent:Connect(function(playerData: PlayerData)
		_clientPlayerData = playerData -- Update client player data on restart quests response
		ResetQuestsEvent:Fire() -- Fire reset quests event
	end)
end

-------------------------------------------------------------------------------
-- Currency Save Data Functions
-------------------------------------------------------------------------------

-- Function to add rewards from a loot container to a player's data on the server
function ServerAddRewardsFromLootContainer(player: Player, rewards: { Types.GameItemAmount }, save: boolean)
	local serverPlayerData = _serverPlayerSaveList[player.user.id] -- Get server player data
	if not serverPlayerData then
		print("Player data not found for player " .. player.user.id) -- Log if data not found
		return
	end
	for _, reward in ipairs(rewards) do
		AddCurrency(serverPlayerData, reward.Template.Id, reward.Amount) -- Add each reward to player data
	end

	if save then
		ServerSavePlayerData(player, serverPlayerData, nil, true) -- Save updated player data if required
	end
end

-- Function to add rewards from a loot container to a player's data on the client
function ClientAddRewardsFromLootContainer(rewards: { Types.GameItemAmount }, save: boolean)
	for _, reward in ipairs(rewards) do
		AddCurrency(_clientPlayerData, reward.Template.Id, reward.Amount) -- Add each reward to client player data
	end
	if save then
		SavePlayerData() -- Save updated player data if required
	end
end

-- Function to add currency to a player's data
function AddCurrency(playerData: PlayerData, id: string, amount: number)
	if not id or id == "" or amount == 0 then
		return -- Exit if ID is invalid or amount is zero
	end

	if playerData.RewardList == nil then
		playerData.RewardList = {} -- Initialize reward list if nil
	end
	local currencyData = Utils.FindInTable(playerData.RewardList, function(data)
		return data.Id == id -- Find existing currency data
	end)

	if currencyData then
		currencyData.Amount = currencyData.Amount + amount -- Update amount if currency already exists
	else
		table.insert(playerData.RewardList, { Id = id, Amount = amount }) -- Add new currency data
	end
end

-- Function to spend currency from a player's data
function SpendCurrency(playerData: PlayerData, id: string, amount: number)
	AddCurrency(playerData, id, -amount) -- Subtract amount from currency
end

-- Function to check if a player has enough currency
function HasEnoughCurrency(playerData: PlayerData, id: string, amount: number): boolean
	return GetCurrencyAmount(playerData, id) >= amount -- Return true if enough currency is available
end

-- Function to get the amount of currency a player has
function GetCurrencyAmount(playerData: PlayerData, id: string): number
	if playerData.RewardList == nil then
		return 0 -- Return zero if reward list is nil
	end
	local currencyData = Utils.FindInTable(playerData.RewardList, function(data)
		return data.Id == id -- Find currency data by ID
	end)

	if currencyData then
		return currencyData.Amount -- Return the amount if found
	end
	return 0 -- Return zero if not found
end

-- Function to convert game amounts to save data rewards format
function ConvertGameAmountToSaveDataRewards(rewards: { Types.GameItemAmount }): { RewardSaveData }
	local rewardSaveData = {}
	for _, reward in ipairs(rewards) do
		table.insert(rewardSaveData, { Id = reward.Template.Id, Amount = reward.Amount }) -- Convert each reward
	end
	return rewardSaveData -- Return the converted rewards
end

-------------------------------------------------------------------------------
-- Quest Save Data Functions
-------------------------------------------------------------------------------

-- Function to progress on a quest
function ProgressOnQuest(id: string, totalProgress: number)
	local quest = GetQuestData(id) -- Get quest data
	if quest == nil then
		table.insert(_clientPlayerData.QuestList, { Id = id, Progress = totalProgress }) -- Add new quest if not found
	else
		quest.Progress = totalProgress -- Update progress if found
	end
end

-- Function to get quest data by ID
function GetQuestData(id: string): QuestSaveData
	if _clientPlayerData.QuestList == nil then
		_clientPlayerData.QuestList = {} -- Initialize quest list if nil
	end
	return Utils.FindInTable(_clientPlayerData.QuestList, function(data)
		return data.Id == id -- Find quest data by ID
	end)
end

-- Function to complete a quest cheat request
function CompleteQuestCheat(index: number)
	CompleteQuestCheatRequestEvent:FireServer(index) -- Fire request to server
end

-- Function to handle server-side complete quest cheat requests
function ServerOnCompleteQuestCheatRequest(player: Player, index: number)
	local playerData: PlayerData = _serverPlayerSaveList[player.user.id] -- Get player data
	for i = 1, index do
		local quest: QuestTemplate = _gameSettings.GetQuestTemplateByIndex(1, i) -- Get quest template
		if quest then
			-- Check if quest is already in the quest list
			local found = false
			for j = 1, #playerData.QuestList do
				if playerData.QuestList[j].Id == quest.Id then
					found = true -- Mark as found
					break
				end
			end
			if found then
				continue -- Skip if found
			end

			table.insert(playerData.QuestList, { Id = quest.Id, Progress = 1 }) -- Add new quest to the list
		end
	end

	-- Account for contest quest
	if index >= 5 then
		index = index - 1 -- Adjust index for contest quest
	end
	for i = 1, index do
		local dressupTask = _gameSettings.GetDressUpTaskByIndex(i) -- Get dress-up task
		if dressupTask then
			table.insert(playerData.CompletedTasks, dressupTask.Id) -- Add task to completed tasks
		end
	end
	ServerSavePlayerData(player, playerData, nil, true) -- Save updated player data
	CompleteQuestCheatResponseEvent:FireClient(player, playerData) -- Send response back to client
end

-- Function to request a restart of quests
function RequestRestartQuests()
	RestartQuestsRequestEvent:FireServer() -- Fire request to server
end

-- Function to mark no reset for the player
function MarkNoReset()
	print("marking no reset") -- Log marking no reset
	_clientPlayerData.RepeatCount = 1 -- Set repeat count to 1
	SavePlayerData() -- Save updated player data
end

-------------------------------------------------------------------------------
-- Client Dress Up Functions
-------------------------------------------------------------------------------

-- Function to handle complete dress-up response from the server
function OnCompleteDressUpResponse(response: CompleteDressUpResponse)
	if _completeDressUpCallback then
		_clientPlayerData = response.PlayerData -- Update client player data
		Utils.PrintTable(response.PlayerData) -- Print player data for debugging
		Utils.PrintTable(_clientPlayerData) -- Print current player data for debugging
		_completeDressUpCallback(response) -- Call the complete dress-up callback
	end
end

-- Function to request completion of a dress-up task
function CompleteDressUpRequest(id: string, callback: (response: CompleteDressUpResponse) -> ())
	-- Check if the task is already completed
	if Utils.IsInTable(_clientPlayerData.CompletedTasks, id) then
		callback({ Code = 1, PlayerData = _clientPlayerData, Rewards = {} }) -- Return error if already completed
		return
	end

	_completeDressUpCallback = callback -- Set the callback for completion
	print("Completed task: " .. id .. ", Saving data") -- Log task completion
	CompleteDressUpRequestEvent:FireServer(id) -- Fire request to server
end

-- Function to check if a dress-up task has been completed
function HasCompletedDressUp(id: string): boolean
	return Utils.IsInTable(_clientPlayerData.CompletedTasks, id) -- Return true if completed
end

-- Function to mark that the player has seen the intro
function ClientSeenIntro()
	_clientPlayerData.SeenIntro = true -- Set seen intro to true
	_clientPlayerData.RepeatCount = 1 -- Set repeat count to 1
	SavePlayerData() -- Save updated player data
end
