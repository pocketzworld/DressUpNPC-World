--!Type(ScriptableObject)

--!SerializeField
local _pitch : number = 28
--!SerializeField
local _zoom : number = 20
--!SerializeField
local _duration : number = 0.5
--!SerializeField
local _targetOffset : Vector3 = Vector3.new(0, 1, 0)

local function GetPitch() : number
    return _pitch
end
Pitch = GetPitch()

local function GetZoom() : number
    return _zoom
end
Zoom = GetZoom()

local function GetDuration() : number
    return _duration
end
Duration = GetDuration()

local function GetTargetOffset() : Vector3
    return _targetOffset
end
TargetOffset = GetTargetOffset()