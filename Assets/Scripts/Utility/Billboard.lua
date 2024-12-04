--[[
    
    Copyright (c) 2024 Pocket Worlds

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely.
    
--]] 


--!Type(Client)

--!SerializeField
local _originalScale : Vector3 = Vector3.one

local _followTarget : Transform = nil

function self.ClientAwake()
    _followTarget = Camera.main.transform
end

function self.LateUpdate()

    if(not _followTarget) then
        return
    end

    self.transform.localScale = Vector3.one
    local lookPos = _followTarget.position - self.transform.position
    local rotation = Quaternion.LookRotation(lookPos)
    self.transform.rotation = rotation
    self.transform.localScale = _originalScale
end