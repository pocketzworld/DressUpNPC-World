--!Type(Client)

local GM: GameManager = require("GameManager")

--!SerializeField
local _npcCharacter: Character = nil

function self.ClientAwake()
    local tapHandler = self.gameObject:GetComponent(TapHandler)
    tapHandler.Tapped:Connect(function()
        GM.UIManager.OpenItemStoreUI()
    end)

end