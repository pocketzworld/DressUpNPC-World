--!Type(Client)

--!SerializeField
local _duration: number = 1

function self.ClientAwake()
    Timer.After(_duration, function()
        Object.Destroy(self.gameObject)
    end)
end