--!Type(Module)

-- Define a type for representing the amount of a game item.
export type GameItemAmount = {
	Template: any, -- The template or definition of the game item.
	Amount: number, -- The quantity of the game item.
}

-------------------------------------------------------------------------------
-- Quest Instance
-------------------------------------------------------------------------------

-- Define a type for representing an instance of a quest.
export type QuestInstance = {
	QuestTemplate: QuestTemplate, -- The template that defines the quest.
	QuestLineTemplate: QuestLineTemplate, -- The template that defines the quest line the quest belongs to.
	Progress: number, -- The current progress of the quest.
}

-- Create a table to represent the QuestInstance class.
local QuestInstance = {}
QuestInstance.__index = QuestInstance

-- Constructor function to create a new QuestInstance.
-- @param template: QuestTemplate - The template for the quest.
-- @param questLine: QuestLineTemplate - The template for the quest line.
-- @param progress: number - The initial progress of the quest.
-- @return QuestInstance - A new instance of QuestInstance.
function QuestInstance.New(template: QuestTemplate, questLine: QuestLineTemplate, progress: number)
	local self = setmetatable({}, QuestInstance) -- Set the metatable for the new instance.
	self.QuestTemplate = template -- Assign the quest template to the instance.
	self.QuestLineTemplate = questLine -- Assign the quest line template to the instance.
	self.Progress = progress -- Set the initial progress of the quest.
	return self -- Return the new instance.
end

-- Helper function to create a new QuestInstance.
-- @param template: QuestTemplate - The template for the quest.
-- @param questLine: QuestLineTemplate - The template for the quest line.
-- @param progress: number - The initial progress of the quest.
-- @return QuestInstance - A new instance of QuestInstance.
function NewQuestInstance(template: QuestTemplate, questLine: QuestLineTemplate, progress: number): QuestInstance
	return QuestInstance.New(template, questLine, progress) -- Call the constructor to create a new instance.
end

-- Method to check if the quest is completed.
-- @return boolean - True if the quest is completed, false otherwise.
function QuestInstance:IsCompleted()
	return self.Progress >= self.QuestTemplate.Target -- Compare current progress with the target to determine completion.
end
