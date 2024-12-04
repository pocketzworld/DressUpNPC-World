--!Type(UI)

--!Bind
local _root : VisualElement = nil

local _onClosed = nil

function OnCancelClicked()
    _onClosed()
end

function Init(onClosed)
    _onClosed = onClosed
    Timer.After(0.5, function()
        _root:RegisterCallback(PointerDownEvent, OnCancelClicked)
    end)
end
