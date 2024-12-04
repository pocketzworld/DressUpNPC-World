--!Type(ScriptableObject)

--!SerializeField
local _dressUpTask: DressUpTask = nil
--!SerializeField
local _enteredContest: boolean = false

function IsDressUpRequirement(): boolean
    return _dressUpTask ~= nil
end

function MeetsReqsForContest(data: any): (boolean, number)
    return _enteredContest == data.EnteredContest, 1
end

function GetDressUpTask(): DressUpTask
    return _dressUpTask
end

--returns if conditions are met and the progress made
function MeetsReqs(data: any): (boolean, number)
    if not data then
        return false, 0
    end

    if not _dressUpTask then
        return MeetsReqsForContest(data)
    end
    
    local id = data.Id
    if not id then
        return false, 0
    end
    return id == _dressUpTask.Id, 1
end