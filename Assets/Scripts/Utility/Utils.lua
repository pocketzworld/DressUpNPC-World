--!Type(Module)

function IsInTable(t, value) : boolean
    for _, v in t do
        if v == value then
            return true
        end
    end
    return false
end

function GetIndexInTable(t, value) : number
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return -1
end

function RemoveInTable(t, value)
    for i, v in ipairs(t) do
        if v == value then
            table.remove(t, i)
            return
        end
    end
end

function IsStringNullOrEmpty(s : string) : boolean
    return s == nil or s == ""
end

function IsTableEqual(t1,t2,ignore_mt) : boolean
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  for k1,v1 in pairs(t1) do
      local v2 = t2[k1]
      if v2 == nil or not IsTableEqual(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
      local v1 = t1[k2]
      if v1 == nil or not IsTableEqual(v1,v2) then return false end
  end
  return true
end

function GetPositionSuffix(position: number): string
  if position == 1 then
    return "1st"
  elseif position == 2 then
    return "2nd"
  elseif position == 3 then
    return "3rd"
  else
    return tostring(position) .. "th"
  end
end

    -- Function to deep copy a table (testing)
    function DeepCopy(original)
      local copy = {}
      for k, v in pairs(original) do
        if type(v) == "table" then
          copy[k] = DeepCopy(v)
        else
          copy[k] = v
        end
      end
      return copy
    end

    -- Activate the object if it is not active
    function SetGameObjectActive(object : GameObject, active : boolean)
        if object.activeSelf ~= active then
            object:SetActive(active)
        end
    end
  
    -- Function to print a table
  function PrintTable(t, indent)
    indent = indent or ''
    for k, v in pairs(t) do
      if type(v) == 'table' then
        print(indent .. k .. ' :')
        PrintTable(v, indent .. '  ')
      else
        print(indent .. k .. ' : ' .. tostring(v))
      end
    end
  end

function FindInTable(t, predicate)
    for _, v in t do
        if predicate(v) then
            return v
        end
    end
    return nil
end
  
  -- Function to get the count of a table
  function GetCountFromTable(t) : number
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
  end

  function GetRandomValueFromVector2(vector : Vector2) : number
    return math.random() * (vector.y - vector.x) + vector.x
  end

  function ShowElement(element : VisualElement, show : boolean)
    if show then
      element.style.display = DisplayStyle.Flex
    else
      element.style.display = DisplayStyle.None
    end
  end

function LerpNoClamp(a : number, b : number, t : number) : number
    return a + (b - a) * t
end

function GetDateString(seconds: number) : string
    local date = os.date("*t", seconds)
    return (date.year .. "/" .. date.month .. "/" .. date.day .. " " .. date.hour .. ":" .. date.min .. ":" .. date.sec)
end

function GetTimerText(seconds: number) : string
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    if hours <= 0 then
        return string.format("%02d:%02d", minutes, secs)
    else 
      return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
end

function GetTimeEndedAgo(endedSeconds: number) : string
    local currentTime = os.time()
    local timeSinceEnd = currentTime - endedSeconds
    if timeSinceEnd < 60 then
        return "Just now"
    elseif timeSinceEnd < 3600 then
        return math.floor(timeSinceEnd / 60) .. "m ago"
    elseif timeSinceEnd < 86400 then
        return math.floor(timeSinceEnd / 3600) .. "h ago"
    else
        return math.floor(timeSinceEnd / 86400) .. "d ago"
    end
end