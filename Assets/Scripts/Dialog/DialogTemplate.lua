--!Type(ScriptableObject)

export type DialogStep = {
    DisplayData: DisplayDataTemplate,
    Dialog: string,
    PlayerSpeaking: boolean,
    Emote: string
}

local GM = nil
if not server then
    GM = require("GameManager")
end

--!SerializeField
local _dialogStrings: {string} = nil
--!SerializeField
local _emotes: {string} = nil
--!SerializeField
local _playerSpeakingList: {boolean} = nil
--!SerializeField
local _speechAudio: AudioShader = nil
--!SerializeField
local _displayData: DisplayDataTemplate = nil
--!SerializeField
local _randomizeStrings: boolean = false

if not server then
    function GetDialogStep(index: number) : DialogStep
        local playerDD = GM.Settings.GetPlayerDisplayData()
        local playerSpeaking = _playerSpeakingList[index]
        local displayData = playerSpeaking and playerDD or _displayData
        local dialog = _dialogStrings[index]
        if _randomizeStrings then
            dialog = _dialogStrings[math.random(1, #_dialogStrings)]
        end
        return {
            DisplayData = displayData,
            Dialog = dialog,
            PlayerSpeaking = playerSpeaking,
            Emote = _emotes[index]
        }
    end

    function GetStepCount() : number
        if _randomizeStrings then
            return 1
        end
        return #_dialogStrings
    end

    function GetSpeechAudio() : AudioShader
        return _speechAudio
    end

    function GetDisplayData() : DisplayDataTemplate
        return _displayData
    end

end