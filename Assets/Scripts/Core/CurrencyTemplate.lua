--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _displayData: DisplayDataTemplate = nil
--!SerializeField
local _stackable: boolean = true

local function GetId()
    return _id
end
Id = GetId()

local function GetDisplayData()
    return _displayData
end
DisplayData = GetDisplayData()

local function IsStackable()
    return _stackable
end
Stackable = IsStackable()