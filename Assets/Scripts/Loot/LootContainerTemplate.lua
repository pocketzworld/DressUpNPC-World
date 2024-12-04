--!Type(ScriptableObject)

--!SerializeField
local _guaranteedLootList: {LootItemDefinition} = nil
--!SerializeField
local _guaranteedLootRanges: {Vector3} = nil
--!Header("Additional Loot Settings")
--!SerializeField
local _additionalLootCountRange: Vector3 = nil
--!SerializeField
local _additionalLootList: {LootItemDefinition} = nil
--!SerializeField
local _additionalLootRanges: {Vector3} = nil
--!SerializeField
local _additionalLootWeights: {number} = nil

local function GetGuaranteedLootList() : {LootItemDefinition}
    return _guaranteedLootList
end
GuaranteedLootList = GetGuaranteedLootList()

local function GetGuaranteedLootRanges() : {Vector3}
    return _guaranteedLootRanges
end
GuaranteedLootRanges = GetGuaranteedLootRanges()

local function GetAdditionalLootCountRange() : Vector3
    return _additionalLootCountRange
end
AdditionalLootCountRange = GetAdditionalLootCountRange()

local function GetAdditionalLootList() : {LootItemDefinition}
    return _additionalLootList
end
AdditionalLootList = GetAdditionalLootList()

local function GetAdditionalLootRanges() : {Vector3}
    return _additionalLootRanges
end
AdditionalLootRanges = GetAdditionalLootRanges()

local function GetAdditionalLootWeights() : {number}
    return _additionalLootWeights
end
AdditionalLootWeights = GetAdditionalLootWeights()
