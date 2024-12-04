--!Type(ScriptableObject)

--!SerializeField
local _id: string = ""
--!SerializeField
local _quests: {QuestTemplate} = nil

local function GetId(): string
    return _id
end
Id = GetId()

function GetQuestTemplateById(id: string) : QuestTemplate
    for i, quest in ipairs(_quests) do
        if quest.Id == id then
            return quest
        end
    end
    return nil
end

function GetQuestTemplate(index: number) : QuestTemplate
    return _quests[index]
end

function GetQuests() : {QuestTemplate}
    return _quests
end