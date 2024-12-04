--!Type(Client)

--!SerializeField
local _offset : Vector3 = Vector3.zero
--!SerializeField
local _duration : number = 0.2

function self.Start()
    local currentPosition = self.transform.localPosition
    local targetPosition = currentPosition + _offset
    self.transform:TweenLocalPosition(currentPosition, targetPosition):Duration(_duration):EaseInOutSine():PingPong():Loop():Play()
end