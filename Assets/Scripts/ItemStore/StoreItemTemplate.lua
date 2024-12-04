--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _clothingCollectionRewardTemplate: ClothingCollectionRewardTemplate = nil
--!SerializeField
local _displayData: DisplayDataTemplate = nil
--!SerializeField
local _cost: number = 0
--!SerializeField
local _currencyCostTemplate: CurrencyTemplate = nil

local function GetId()
    return _id
end
Id = GetId()

local function GetClothingCollectionRewardTemplate()
    return _clothingCollectionRewardTemplate
end
ClothingCollectionRewardTemplate = GetClothingCollectionRewardTemplate()

local function GetDisplayData()
    return _displayData
end
DisplayData = GetDisplayData()

local function GetCost()
    return _cost
end
Cost = GetCost()

local function GetCurrencyCostTemplate()
    return _currencyCostTemplate
end
CurrencyCostTemplate = GetCurrencyCostTemplate()