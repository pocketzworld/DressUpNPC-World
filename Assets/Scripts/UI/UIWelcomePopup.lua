--!Type(UI)

local GM: GameManager = require("GameManager")

--!Bind
local _closeOverlay : VisualElement = nil
--!Bind
local _okButton : Button = nil
--!Bind
local _content : VisualElement = nil

function GetRoot() : VisualElement
    return _content
end

local function OnCloseButton()
    GM.UIManager.CloseUI(GM.UIManager.UINames.WelcomePopup)
end

function self.ClientAwake()
    _closeOverlay:RegisterPressCallback(OnCloseButton)
    _okButton:RegisterPressCallback(OnCloseButton)
end