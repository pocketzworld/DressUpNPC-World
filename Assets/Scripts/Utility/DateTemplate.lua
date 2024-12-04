--!Type(ScriptableObject)

--!SerializeField
local _startYear: number = 2020
--!SerializeField
local _startMonth: number = 1
--!SerializeField
local _startDay: number = 1
--!SerializeField
local _startHour: number = 0
--!SerializeField
local _startMinute: number = 0
--!SerializeField
local _startSecond: number = 0

function GetTimeForDate() : number
    return os.time({year = _startYear, month = _startMonth, day = _startDay, hour = _startHour, min = _startMinute, sec = _startSecond})
end

function FindPreviousTimeToStart(eventDuration: number)
    local currentTime = os.time()
    local timeForDate = GetTimeForDate()
    local timeSinceStart = currentTime - timeForDate
    local timeToStart = math.floor(timeSinceStart / eventDuration) * eventDuration + timeForDate
    return timeToStart
end