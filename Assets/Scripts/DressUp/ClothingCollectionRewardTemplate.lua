--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _collection: ClothingCollection = nil
--!SerializeField
local _displayData: DisplayDataTemplate = nil

local function GetId(): string
	return _id
end
Id = GetId()

local function GetCollection(): ClothingCollection
	return _collection
end
Collection = GetCollection()

local function GetDisplayData(): DisplayDataTemplate
	return _displayData
end
DisplayData = GetDisplayData()

local function GetStackable(): boolean
	return true
end
Stackable = GetStackable()
