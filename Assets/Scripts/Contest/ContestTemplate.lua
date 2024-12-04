--!Type(ScriptableObject)
-- This line indicates that the script is a type of ScriptableObject, which is a Unity-specific type used for storing data.

-- Declare and serialize a string variable to hold the ID of the object.
--!SerializeField
local _id: string = ""

-- Declare and serialize a table of possible styles as strings.
--!SerializeField
local _possibleStyles: { string } = nil

-- Declare and serialize a variable to hold display data, which is of type DisplayDataTemplate.
--!SerializeField
local _displayData: DisplayDataTemplate = nil

-- Declare and serialize a number to represent the duration, defaulting to 300.
--!SerializeField
local _duration: number = 300

-- Declare and serialize a number to represent the ticket cost, defaulting to 5.
--!SerializeField
local _ticketCost: number = 5

-- Declare and serialize a number to represent the top player count, defaulting to 10.
--!SerializeField
local _topPlayerCount: number = 10

-- Declare and serialize a variable to hold the participation reward, which is of type LootContainerTemplate.
--!SerializeField
local _participationReward: LootContainerTemplate = nil

-- Declare and serialize a list of top rewards, which are of type LootContainerTemplate.
--!SerializeField
local _topRewardsList: { LootContainerTemplate } = nil

-- Function to get the ID of the object.
-- @return string - The ID of the object.
local function GetId(): string
	return _id
end
Id = GetId() -- Assign the result of GetId() to a global variable Id.

-- Function to get the possible styles.
-- @return {string} - A table of possible styles.
local function GetPossibleStyles(): { string }
	return _possibleStyles
end
PossibleStyles = GetPossibleStyles() -- Assign the result of GetPossibleStyles() to a global variable PossibleStyles.

-- Function to get a random style based on a seed.
-- @param seed number - The seed for random number generation.
-- @return string - A randomly selected style from the possible styles.
function GetRandomStyle(seed: number): string
	math.randomseed(seed) -- Seed the random number generator.
	return _possibleStyles[math.random(1, #_possibleStyles)] -- Return a random style.
end

-- Function to get the display data.
-- @return DisplayDataTemplate - The display data associated with the object.
function GetDisplayData(): DisplayDataTemplate
	return _displayData
end
DisplayData = GetDisplayData() -- Assign the result of GetDisplayData() to a global variable DisplayData.

-- Function to get the duration.
-- @return number - The duration value.
local function GetDuration(): number
	return _duration
end
Duration = GetDuration() -- Assign the result of GetDuration() to a global variable Duration.

-- Function to get the ticket cost.
-- @return number - The ticket cost value.
local function GetTicketCost(): number
	return _ticketCost
end
TicketCost = GetTicketCost() -- Assign the result of GetTicketCost() to a global variable TicketCost.

-- Function to get the top player count.
-- @return number - The count of top players.
local function GetTopPlayerCount(): number
	return _topPlayerCount
end
TopPlayerCount = GetTopPlayerCount() -- Assign the result of GetTopPlayerCount() to a global variable TopPlayerCount.

-- Function to get the participation reward.
-- @return LootContainerTemplate - The participation reward associated with the object.
local function GetParticipationReward(): LootContainerTemplate
	return _participationReward
end
ParticipationReward = GetParticipationReward() -- Assign the result of GetParticipationReward() to a global variable ParticipationReward.

-- Function to get the reward based on the player's rank.
-- @param rank number - The rank of the player.
-- @return LootContainerTemplate - The reward associated with the player's rank.
function GetReward(rank: number): LootContainerTemplate
	if rank > _topPlayerCount then
		return _participationReward -- Return participation reward if rank exceeds top player count.
	end
	-- Search for a top reward. If no reward exists, find the lowest rank reward.
	if rank > #_topRewardsList then
		rank = #_topRewardsList -- Adjust rank to the maximum available index.
	end
	return _topRewardsList[rank] -- Return the reward corresponding to the player's rank.
end
