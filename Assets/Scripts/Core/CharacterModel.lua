--!Type(Client)

local GM: GameManager = require("GameManager")

--!SerializeField
local _fadeHelper: CharacterFadeHelper = nil
--!SerializeField
local _character: Character = nil

function GetCharacter() : Character
    return _character
end

function GetPlayer() : Player
    return _character.player
end

local function GetFadeHelper() : CharacterFadeHelper
    return _fadeHelper
end
CharacterFade = GetFadeHelper()

function self.OnDestroy()
    GM.RemoveModelFromList(self)
end

function self.ClientAwake()
    GM.AddModelToList(self)
end