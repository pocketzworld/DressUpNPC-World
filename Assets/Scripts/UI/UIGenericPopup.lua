--!Type(UI)

local UIManager = require("UIManager")

--!Bind
local _content: VisualElement = nil
--!Bind
local _message: Label = nil
--!Bind
local _okButton: UIButton = nil
--!Bind
local _okButtonText: Label = nil
--!Bind
local _cancelButton: UIButton = nil
--!Bind
local _closeOverlay: VisualElement = nil

local _okCallback: () -> ()
local _cancelCallback: () -> ()

function GetRoot(): VisualElement
	return _content
end

local function CloseUI()
	UIManager.CloseUI(UIManager.UINames.GenericPopup)
end

local function OnOkButton()
	if _okCallback then
		_okCallback()
	end
	CloseUI()
end

local function OnCancel()
	if _cancelCallback then
		_cancelCallback()
	end
	CloseUI()
end

function Init(message: string, okCallback: () -> ())
	_message.text = message
	_okCallback = okCallback

	_okButton:RegisterPressCallback(OnOkButton)
	_cancelButton:SetDisplay(false)
	_closeOverlay:RegisterCallback(PointerDownEvent, CloseUI)
end

function InitPurchase(message: string, confirmButtonText: string, okCallback: () -> (), cancelCallback: () -> ())
	_message.text = message
	_okCallback = okCallback
	_cancelCallback = cancelCallback

	_okButtonText.text = confirmButtonText

	_okButton:RegisterPressCallback(OnOkButton)
	_cancelButton:RegisterPressCallback(OnCancel)
	_closeOverlay:RegisterCallback(PointerDownEvent, CloseUI)
end
