--!Type(Module)

--!SerializeField
local _testMode: boolean = false
--!SerializeField
local _validPlayers: {string} = nil

local chatCommandRequest = Event.new("ChatCommandRequest")
local chatCommandResponse = Event.new("ChatCommandResponse")

local GM: GameManager = require("GameManager")
local ContestManager: ContestManager = require("ContestManager")

local commands = {}
local info = nil

helpCallback = function()
    Chat:DisplayTextMessage(info, client.localPlayer, "Available commands:")
    local printcommands = ""
    for command, _ in pairs(commands) do
        printcommands = printcommands .. "\n"
        printcommands = printcommands .. "-" .. command
    end
    Timer.After(0.5, function() Chat:DisplayTextMessage(info, client.localPlayer, printcommands) end)
end

local function SplitString(input)
    local result = {}
    for word in input:gmatch("%S+") do
        table.insert(result, word)
    end
    return result
end

local function ParseCommand(input) : (string, {string})
    -- Ensure the command starts with a '/'
    if input:sub(1, 1) ~= "/" and input:sub(1, 1) ~= ":" then
        return "", nil
    end
    
    -- Remove the leading '/'
    input = input:sub(2)

    -- Split the string into parts
    local parts = SplitString(input)
    
    -- The first part is the command
    local command = parts[1]
    
    -- The rest are arguments
    local arguments = {}
    for i = 2, #parts do
        table.insert(arguments, parts[i])
    end
    
    return command, arguments
end

local function CommandExists(command)
    return commands[command] ~= nil
end

local function CanPlayerRunCommand(player)
    if _testMode then
        return true
    end
    if _validPlayers == nil then
        return false
    end
    for i = 1, #_validPlayers do
        if _validPlayers[i] == player.user.id then
            return true
        end
    end
    return false
end

function self:ClientAwake()
    GM.ChatMessageEvent:Connect(function(channelInfo, player, message)
        info = channelInfo
        local isCommand = string.sub(message, 1, 1) == "/"
        local isServerCommand = string.sub(message, 1, 1) == ":"
        local isLocalPlayer = player == client.localPlayer

        if (not isCommand and not isServerCommand) or not isLocalPlayer then
            return
        end

        local command, arguments = ParseCommand(message)
        if not CanPlayerRunCommand(player) then
            print("Player " .. player.name .. " is not allowed to run commands.")
            return
        end

        if not command or command == "" or not CommandExists(command) then
            return
        end
        local chatMsg = "Running command " .. command
        Chat:DisplayTextMessage(channelInfo, player, chatMsg)

        if isCommand then
            commands[command](arguments)
        elseif isServerCommand then
            chatCommandRequest:FireServer(command, arguments)
        end
    end)

    chatCommandResponse:Connect(function(command, arguments)
        if CommandExists(command) then
            commands[command](arguments)
        else
            Chat:DisplayTextMessage(info, client.localPlayer, "Command not found. Type /help to see available commands.")
        end
    end)
end

function self:ClientStart()
    commands = {
        help = helpCallback,
        cleardata = GM.ClearData,
        addreward = GM.AddRewardCheat,
        debugquests = GM.DebugQuestsCheat,
        deletecontests = ContestManager.ClientClearAllContests,
        addcontestplayers = ContestManager.SetupTestContestPlayers,
        addtickets = ContestManager.AddTicketsCheat,
        setcontestvotes = ContestManager.SetContestVotesCheat,
        unlockcontest = GM.UnlockContestCheat,
        completequests = GM.CompleteQuestsCheat
    }
end

function self:ServerAwake()
    chatCommandRequest:Connect(function(player, command, arguments)
        if not CanPlayerRunCommand(player) then
            return
        end
        chatCommandResponse:FireAllClients(command, arguments)
    end)
end