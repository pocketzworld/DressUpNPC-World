--!Type(Module)

local TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

local _spinAngle: number = 0

function ParentElement(element, parent)
    parent:Add(element)
end

function AddClass(element, class: string)
    if not element or not class or class == "" then
        return
    end
    element:AddToClassList(class)
end

function RemoveClass(element, class: string)
    if not element or not class or class == "" then
        return
    end
    element:RemoveFromClassList(class)
end

function SetPickingMode(element, ignore: boolean)
    element.pickingMode = ignore and PickingMode.Ignore or PickingMode.Position
end

local function BaseSet(element, parent, classes: {string}, ignoreClick: boolean | nil)
    ParentElement(element, parent)
    for i, class in ipairs(classes) do
        AddClass(element, class)
    end
    local ignore = ignoreClick
    if ignoreClick == nil then
        ignore = true
    end
    SetPickingMode(element, ignore)
end

function NewVisualElement(parent, classes: {string}, ignoreClick: boolean | nil): VisualElement
    local element = VisualElement.new()
    BaseSet(element, parent, classes, ignoreClick)
    return element
end

function NewImage(parent, classes: {string}, ignoreClick: boolean | nil): Image
    local element = Image.new()
    BaseSet(element, parent, classes, ignoreClick)
    return element
end

function NewLabel(parent, classes: {string}, text: string, ignoreClick: boolean | nil): Label
    local element = Label.new()
    element.text = text
    BaseSet(element, parent, classes, ignoreClick)
    return element
end

function NewUserThumbnail(parent, classes: {string}, playerId: string, ignoreClick: boolean | nil): Label
    local element = UIUserThumbnail.new()
    element:Load(playerId)
    BaseSet(element, parent, classes, ignoreClick)
    return element
end

function NewButton(parent, classes: {string}, ignoreClick: boolean | nil): Button
    local element = Button.new()
    BaseSet(element, parent, classes, ignoreClick)
    return element
end

function NewLoadingSpinner(parent, classes: {string}): VisualElement
    local element = Image.new()
    BaseSet(element, parent, classes, true)
    PlaySpin(element)
    return element
end

function SetButtonEnabled(element: VisualElement, enabled: boolean)
    element:SetEnabled(enabled)
end

function ShowElementByOpacity(element: VisualElement, show: boolean, ignoreClick: boolean | nil)
    element.style.opacity = StyleFloat.new(show and 1 or 0)
    if not show then
        SetPickingMode(element, true)
    else
        SetPickingMode(element, ignoreClick or true)
    end
end

function ZeroMargin(element: VisualElement)
    element.style.marginBottom = StyleLength.new(0)
    element.style.marginTop = StyleLength.new(0)
    element.style.marginLeft = StyleLength.new(0)
    element.style.marginRight = StyleLength.new(0)
end

function ZeroPadding(element: VisualElement)
    element.style.paddingBottom = StyleLength.new(0)
    element.style.paddingTop = StyleLength.new(0)
    element.style.paddingLeft = StyleLength.new(0)
    element.style.paddingRight = StyleLength.new(0)
end

--------------------
-- Tween Functions --
--------------------

function PlaySpin(element: VisualElement)
    _spinAngle = 0
    local myTween = Tween:new(
        function(value)
            _spinAngle = _spinAngle + value * 5 * Time.deltaTime
            element.style.rotate = StyleRotate.new(Rotate.new(Angle.new(_spinAngle)))
        end
    )
    :FromTo(0, 359)
    :Easing(Easing.linear)
    :Duration(0.1)
    :Loop()

    myTween:start()
end