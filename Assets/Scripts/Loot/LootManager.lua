--!Type(Module)

-- Importing required modules for types and utility functions
local Types = require("Types")
local Utils = require("Utils")

-- Function to get a random amount within a specified range
-- @param _range: A table containing 'x' and 'y' as the range limits
-- @return: A random number between _range.x and _range.y
local function GetRandomAmount(_range): number
	return math.random(_range.x, _range.y)
end

-- Function to retrieve a reward from a list based on its ID
-- @param rewards: A list of game item amounts
-- @param rewardId: The ID of the reward to find
-- @return: The found GameItemAmount or nil if not found
local function GetRewardInList(rewards: { Types.GameItemAmount }, rewardId: string): Types.GameItemAmount
	for i, reward: Types.GameItemAmount in ipairs(rewards) do
		if reward.Template.Id == rewardId then
			return reward
		end
	end
	return nil
end

-- Function to add a reward to a list, either by increasing the amount of an existing reward or adding a new one
-- @param rewards: A list of game item amounts to which the reward will be added
-- @param loot: The LootItemDefinition containing the reward template
-- @param amt: The amount of the reward to add
local function AddRewardToList(rewards: { Types.GameItemAmount }, loot: LootItemDefinition, amt: number)
	-- Check if the reward already exists in the list
	local existingReward = GetRewardInList(rewards, loot.RewardTemplate.Id)
	if existingReward and existingReward.Template.Stackable then
		-- If it exists and is stackable, increase the amount
		existingReward.Amount = existingReward.Amount + amt
	else
		-- Otherwise, create a new GameItemAmount and add it to the list
		local gameItemAmt = {
			Template = loot.RewardTemplate,
			Amount = amt,
		}
		table.insert(rewards, gameItemAmt)
	end
end

-- Main function to roll for loot from a loot container
-- @param lootContainer: The LootContainerTemplate containing the loot definitions
-- @return: A list of game item amounts representing the rewards obtained
function Roll(lootContainer: LootContainerTemplate): { Types.GameItemAmount }
	local rewards: { Types.GameItemAmount } = {}

	-- Add the guaranteed items from the loot container
	for i, loot: LootItemDefinition in ipairs(lootContainer.GuaranteedLootList) do
		if not loot.RewardTemplate then
			continue -- Skip if there is no reward template
		end

		-- Get a random amount for the guaranteed loot
		local amt = GetRandomAmount(lootContainer.GuaranteedLootRanges[i])
		if amt > 0 then
			AddRewardToList(rewards, loot, amt) -- Add the reward to the list
		end
	end

	-- Calculate the total weight of additional rewards
	local totalWeight = 0
	for i, loot: LootItemDefinition in ipairs(lootContainer.AdditionalLootList) do
		totalWeight = totalWeight + lootContainer.AdditionalLootWeights[i]
	end

	-- Determine how many additional items to add based on the specified range
	local additionalLootCount =
		math.random(lootContainer.AdditionalLootCountRange.x, lootContainer.AdditionalLootCountRange.y)
	print("adding " .. additionalLootCount .. " additional items")

	-- Add the additional items based on their weights
	for i = 1, additionalLootCount do
		local roll = math.random(0, totalWeight - 1) -- Roll a random number based on total weight
		for j, loot: LootItemDefinition in ipairs(lootContainer.AdditionalLootList) do
			local weight = lootContainer.AdditionalLootWeights[j]
			if roll < weight then
				if not loot or not loot.RewardTemplate then
					break -- Break if there is no loot or reward template
				end

				-- Get a random amount for the additional loot
				local amt = GetRandomAmount(lootContainer.AdditionalLootRanges[j])
				if amt <= 0 then
					break -- Break if the amount is not positive
				end
				AddRewardToList(rewards, loot, amt) -- Add the reward to the list
				break
			end
			roll = roll - weight -- Decrease the roll by the weight of the current loot
		end
	end

	return rewards -- Return the list of rewards obtained
end
