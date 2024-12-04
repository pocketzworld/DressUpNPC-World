--!Type(ScriptableObject)

--!SerializeField
local _name : string = ""
--!SerializeField
local _description : string = ""
--!SerializeField
local _imageSprite: Sprite = nil

local function GetName() : string
    return _name
end
Name = GetName()

local function GetDescription() : string
    return _description
end
Description = GetDescription()

local function GetImage() : Sprite
    return _imageSprite
end
ImageSprite = GetImage()