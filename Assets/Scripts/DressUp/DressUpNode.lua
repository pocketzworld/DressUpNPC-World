--!Type(ScriptableObject)

--!SerializeField
local _clothingCollection : ClothingCollection = nil
--!SerializeField
local _displayData : DisplayDataTemplate = nil
--!SerializeField
local _removedClothing : {string} = nil
--!SerializeField
local _extraClothing : {string} = nil

local function GetClothing() : ClothingCollection
    return _clothingCollection
end
ClothingChoices = GetClothing()

local function GetRemovedClothing() : {string}
    return _removedClothing
end
RemovedClothing = GetRemovedClothing()

local function GetExtraClothing() : {string}
    return _extraClothing
end
ExtraClothing = GetExtraClothing()

local function GetDisplayData() : DisplayDataTemplate
    return _displayData
end
DisplayData = GetDisplayData()