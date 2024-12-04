--!Type(ScriptableObject)

-- Serialized fields for various templates and data used in the game
-- Player display data template
--!SerializeField
local _playerDisplayData: DisplayDataTemplate = nil

-- Dialog template for when a quest is already complete
--!SerializeField
local _questAlreadyCompleteDialog: DialogTemplate = nil

-- Dialog template for resetting quests
--!SerializeField
local _resetQuestsDialog: DialogTemplate = nil

-- List of currency templates
--!SerializeField
local _currencyList: { CurrencyTemplate } = nil

-- List of clothing templates
--!SerializeField
local _clothingList: { ClothingTemplate } = nil

-- List of clothing collection reward templates
--!SerializeField
local _clothingCollectionRewardList: { ClothingCollectionRewardTemplate } = nil

-- List of store item templates
--!SerializeField
local _itemStoreList: { StoreItemTemplate } = nil

-- List of quest line templates
--!SerializeField
local _questLines: { QuestLineTemplate } = nil

-- List of dress-up tasks
--!SerializeField
local _dressUpTasks: { DressUpTask } = nil

-- Dialog template for when a quest is not unlocked
--!SerializeField
local _questNotUnlockedDialog: DialogTemplate = nil

-- Percentage of correct choices required to succeed
--!SerializeField
local _percentChoicesCorrectToSucceed: number = 0.9

-- Sound to play when dress-up is completed
--!SerializeField
local _dressUpCompleteSound: AudioShader = nil

-- Function to get the reset quests dialog template
function GetResetDialog(): DialogTemplate
	return _resetQuestsDialog
end

-- Function to check if an ID is valid (not nil or empty)
local function IsIdValid(id: string): boolean
	return id ~= nil and id ~= ""
end

-- Function to validate a list of templates for unique and valid IDs
local function ValidateTemplateList(list, listName: string)
	local count = 0
	local errorString: string = ""
	-- Check if 2 templates have the same ID and check if the ID is valid
	for i = 1, #list do
		if not IsIdValid(list[i].Id) then
			errorString = errorString .. listName .. " at index " .. i .. " has an invalid id." .. "\n"
			count = count + 1
			continue
		end
		for j = i + 1, #list do
			if not IsIdValid(list[j].Id) then
				errorString = errorString .. listName .. " at index " .. j .. " has an invalid id." .. "\n"
				count = count + 1
				continue
			end
			if list[i].Id == list[j].Id then
				errorString = errorString
					.. listName
					.. " at index "
					.. i
					.. " and "
					.. j
					.. " have the same id."
					.. "\n"
				count = count + 1
			end
		end
	end
	if errorString ~= "" then
		-- Color the text red for error display
		errorString = "<color=red>Error Count: " .. count .. ": " .. errorString .. "</color>"
		print(errorString)
	end
end

-- Function to validate all template lists
function Validate()
	ValidateTemplateList(_currencyList, "CurrencyTemplate")
	ValidateTemplateList(_clothingList, "ClothingTemplate")
	ValidateTemplateList(_questLines, "QuestLineTemplate")
	ValidateTemplateList(_dressUpTasks, "DressUpTask")
	ValidateTemplateList(_clothingCollectionRewardList, "Clothing Collection Reward Template")
	ValidateTemplateList(_itemStoreList, "Store Item Template")
end

-- Function to get the player display data template
function GetPlayerDisplayData(): DisplayDataTemplate
	return _playerDisplayData
end

-- Function to get the quest complete dialog template
local function GetQuestCompleteDialog(): DialogTemplate
	return _questAlreadyCompleteDialog
end
QuestCompleteDialog = GetQuestCompleteDialog()

-- Function to get a currency template by ID
function GetCurrencyTemplate(id: string): CurrencyTemplate | nil
	for i = 1, #_currencyList do
		if _currencyList[i].Id == id then
			return _currencyList[i]
		end
	end
	return nil
end

-- Function to get a clothing template by ID
function GetClothingTemplate(id: string): ClothingTemplate | nil
	for i = 1, #_clothingList do
		if _clothingList[i].Id == id then
			return _clothingList[i]
		end
	end
	return nil
end

-- Function to get a clothing collection reward template by ID
function GetClothingCollectionRewardTemplate(id: string): ClothingCollectionRewardTemplate | nil
	for i = 1, #_clothingCollectionRewardList do
		if _clothingCollectionRewardList[i].Id == id then
			return _clothingCollectionRewardList[i]
		end
	end
	return nil
end

-- Function to get a list of clothing items from collections based on their IDs
function GetClothingListFromCollections(ids: { string }): { CharacterClothing }
	local clothingList = {}
	for i = 1, #ids do
		local collection = GetClothingCollectionRewardTemplate(ids[i])
		if collection then
			local clothingCollection: ClothingCollection = collection.Collection
			for _, clothing in pairs(clothingCollection.clothing) do
				table.insert(clothingList, clothing)
			end
		end
	end
	return clothingList
end

-- Function to get an item store template by ID
function GetItemStoreTemplate(id: string): StoreItemTemplate | nil
	for i = 1, #_itemStoreList do
		if _itemStoreList[i].Id == id then
			return _itemStoreList[i]
		end
	end
	return nil
end

-- Function to get all item store templates
function GetStoreItems(): { StoreItemTemplate }
	return _itemStoreList
end

-- Function to get a dress-up task by ID
function GetDressUpTask(id: string): DressUpTask | nil
	for i = 1, #_dressUpTasks do
		if _dressUpTasks[i].Id == id then
			return _dressUpTasks[i]
		end
	end
	return nil
end

-- Function to get a template for a given ID from various categories
function GetTemplateForId(id: string): any
	local template = GetCurrencyTemplate(id)
	if template then
		return template
	end
	template = GetClothingTemplate(id)
	if template then
		return template
	end
	template = GetClothingCollectionRewardTemplate(id)
	if template then
		return template
	end
	template = GetDressUpTask(id)
	if template then
		return template
	end
	template = GetItemStoreTemplate(id)
	if template then
		return template
	end
	print("Template with id " .. id .. " not found.")
	return nil
end

-- Function to get all quest lines
function GetAllQuestLines(): { QuestLineTemplate }
	return _questLines
end

-- Function to get a quest template by ID
function GetQuestTemplate(id: string)
	for i = 1, #_questLines do
		local quests = _questLines[i].GetQuests()
		for j = 1, #quests do
			if quests[j].Id == id then
				return quests[j]
			end
		end
	end
	print("QuestTemplate with id " .. id .. " not found.")
	return nil
end

-- Function to get a quest template by index in a specific quest line
function GetQuestTemplateByIndex(mainQuestLineIndex: number, index: number): QuestTemplate
	local questLine = _questLines[mainQuestLineIndex]
	if questLine then
		local quests = questLine.GetQuests()
		if quests[index] then
			return quests[index]
		end
	end
	return nil
end

-- Function to get a dress-up task by index
function GetDressUpTaskByIndex(index: number): DressUpTask
	return _dressUpTasks[index]
end

-- Function to get the percentage of correct choices required to succeed
function GetPercentChoicesCorrectToSucceed(): number
	return _percentChoicesCorrectToSucceed
end

-- Function to get the sound to play when dress-up is successful
function GetDressUpSuccessSound(): AudioShader
	return _dressUpCompleteSound
end

-- Function to get the dialog template for when a quest is not unlocked
function GetQuestNotUnlockedDialog(): DialogTemplate
	return _questNotUnlockedDialog
end
