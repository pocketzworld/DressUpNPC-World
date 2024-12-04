--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _itemId: string = ""
--!SerializeField
local _palette: number = 0
--!SerializeField
local _displayData: DisplayDataTemplate = nil

local function GetId() : string
    return _id
end
Id = GetId()

local function GetItemId() : string
    return _itemId
end
ItemId = GetItemId()

local function GetPalette() : number
    return _palette
end
Palette = GetPalette()

local function GetDisplayData() : DisplayDataTemplate
    return _displayData
end
DisplayData = GetDisplayData()

local function GetStackable() : boolean
    return false
end
Stackable = GetStackable()

function GetClothingData(): ClothingData
    return {
        id = _itemId,
        color = _palette
    }
end