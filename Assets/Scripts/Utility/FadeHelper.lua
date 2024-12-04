--!Type(Client)

local _renderer : Renderer = nil
local _timer : number = 0
local _val : number = 0
local _endVal : number = 0
local _duration : number = 0
local _enabled : boolean = false
local _savedMaterial : Material = nil

function self.ClientAwake()
    _renderer = self.gameObject:GetComponentInChildren(Renderer, true)
    if not _renderer then
        print("No renderer found for FadeHelper")
        return
    end

    _savedMaterial = _renderer.material
end

function self.ClientUpdate()
    if not _renderer or not _enabled then
        return
    end

    _timer = _timer + Time.deltaTime
    local newVal = Mathf.Lerp(_val, _endVal, _timer / _duration)
    local color : Color = _savedMaterial.color
    color.a = newVal
    _savedMaterial:SetColor("_Color", color)
    if (_timer >= _duration) then
        _enabled = false
    end
end

function StartFade(reverse : boolean, duration : number)
    if (_enabled) then
        return
    end

    _duration = duration
    _enabled = true
    _timer = 0
    if (reverse) then
        _val = 1
        _endVal = 0
    else
        _val = 0
        _endVal = 1
    end
end