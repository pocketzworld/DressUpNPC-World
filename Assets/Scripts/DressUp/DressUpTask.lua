--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _closetTask: boolean = false
--!Header("Closet Settings")
--!SerializeField
local _closetClothingCollection: ClothingCollection = nil
--!SerializeField
local _typeTargets: {string} = nil
--!Header("Choice Settings")
--!SerializeField
local _characterOutfits : {DressUpNode} = nil
--!SerializeField
local _bestChoices : {number} = nil
--!Header("Shared Settings")
--!SerializeField
local _startDialogTemplate: DialogTemplate = nil
--!SerializeField
local _endSuccessDialogTemplate: DialogTemplate = nil
--!SerializeField
local _endFailDialogTemplate: DialogTemplate = nil
--!SerializeField
local _lootContainerTemplate: LootContainerTemplate = nil

local function GetId() : string
    return _id
end
Id = GetId()

local function IsClosetTaskInternal() : boolean
    return _closetTask
end
IsClosetTask = IsClosetTaskInternal()

function GetClosetClothingCollection() : ClothingCollection
    return _closetClothingCollection
end
ClosetClothingCollection = GetClosetClothingCollection()

function GetTypeTargets() : {string}
    return _typeTargets
end
TypeTargets = GetTypeTargets()

local function GetOutfitCount() : number 
    return #_characterOutfits 
end 
OutfitCount = GetOutfitCount()

function GetDressUpData(index: number) : DressUpNode
    return _characterOutfits[index]
end

function GetStartDialogTemplate() : DialogTemplate
    return _startDialogTemplate
end
StartDialog = GetStartDialogTemplate()

function GetEndSuccessDialogTemplate() : DialogTemplate
    return _endSuccessDialogTemplate
end
EndSuccessDialog = GetEndSuccessDialogTemplate()

function GetEndFailDialogTemplate() : DialogTemplate
    return _endFailDialogTemplate
end
EndFailDialog = GetEndFailDialogTemplate()

function GetLootContainerTemplate() : LootContainerTemplate
    return _lootContainerTemplate
end
LootContainer = GetLootContainerTemplate()

function HasBestChoices() : boolean
    return _bestChoices ~= nil and #_bestChoices > 0
end

function GetBestChoice(index: number) : number
    return _bestChoices[index]
end

function GetPercentOfBestChoicesCorrect(choicesMade: {number}) : number
    local nonChoiceCount = 0
    for i = 1, #choicesMade do
        if choicesMade[i] == -1 then
            nonChoiceCount = nonChoiceCount + 1
        end
    end
    print("non choice count: " .. nonChoiceCount)
    if nonChoiceCount >= 2 then
        return 0
    end

    if not HasBestChoices() then
        return 1
    end

    local correct = 0
    if #_bestChoices == 3 then
        for i = 1, #_bestChoices do
            if choicesMade[i] == _bestChoices[i] then
                correct = correct + 1
            end
        end
    elseif #_bestChoices == 9 then
        --check for a 0 or 1 in the best choices
        for i=1, #choicesMade do
            local choice = choicesMade[i]
            if _bestChoices[choice + (i - 1) * 3] == 1 then
                correct = correct + 1
            end
        end
    end
    return correct / 3
end

function GetIndexOfData(data: DressUpNode) : number
    for i = 1, #_characterOutfits do
        if _characterOutfits[i] == data then
            return i
        end
    end
    return -1
end
