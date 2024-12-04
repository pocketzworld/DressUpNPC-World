--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _questText: string = ""
--!SerializeField
local _goalDescription: string = ""
--!SerializeField
local _displayData: DisplayDataTemplate = nil
--!SerializeField
local _targetAmount: number = 1
--!SerializeField
local _requirement: DressUpTaskRequirementTemplate = nil
--!SerializeField
local _lootContainerTemplate: LootContainerTemplate = nil

local function GetId() : string
    return _id
end
Id = GetId()

local function GetQuestText() : string
    return _questText
end
QuestText = GetQuestText()

local function GetGoalDescription() : string
    return _goalDescription
end
GoalDescription = GetGoalDescription()

local function GetDisplayData() : DisplayDataTemplate
    return _displayData
end
DisplayData = GetDisplayData()

local function GetTargetAmount() : number
    return _targetAmount
end
Target = GetTargetAmount()

local function GetLootContainerTemplate() : LootContainerTemplate
    return _lootContainerTemplate
end
LootContainer = GetLootContainerTemplate()

function GetRequirement(): DressUpTaskRequirementTemplate
    return _requirement
end
Requirement = GetRequirement()

function MeetsReqs(data: any): (boolean, number)
    if not _requirement or not data then
        return false, 0
    end
    return _requirement.MeetsReqs(data)
end