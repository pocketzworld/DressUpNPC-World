--!Type(Client)

-- Importing the GameManager module to handle game-related functionalities
local GM = require("GameManager")

-- A flag to control whether chat messages are displayed
local _showingMessages = true

-- Function that is called when the client is initialized
function self:ClientAwake()
	-- Connects a handler to the TextMessageReceived event from the Chat module
	Chat.TextMessageReceivedHandler:Connect(function(channelInfo, player, message)
		-- Fires a chat message event to the GameManager
		GM.ChatMessageEvent:Fire(channelInfo, player, message)

		-- If messages are not set to be shown, exit the function
		if not _showingMessages then
			return
		end

		-- Displays the text message in the chat UI
		Chat:DisplayTextMessage(channelInfo, player, message)
	end)
end

-- A recursive function to find and hide/show the UIWorld element
-- @param element: The VisualElement to search within
-- @param searchChildren: A boolean indicating whether to search child elements
-- @param show: A boolean indicating whether to show or hide the element
-- @return: A boolean indicating if the UIWorld element was found
local function FindAndHideUIWorld(element: VisualElement, searchChildren: boolean, show: boolean): boolean
	-- If the element is nil, return false
	if element == nil then
		return false
	end

	-- Check if the current element is the UIWorld element
	if element.name == "_world" then
		-- Set the display state of the UIWorld element
		element:SetDisplay(show)
		return true
	end

	local found = false

	-- If searching children is enabled, iterate through child elements
	if searchChildren then
		local children = element:Children()
		for _, child in ipairs(children) do
			-- Recursively search for the UIWorld element in children
			found = FindAndHideUIWorld(child, false, show)
			if found then
				return true
			end
		end

		-- Recursively search in the parent element
		found = FindAndHideUIWorld(element.parent, true, show)
	end

	return found
end

-- Function to show or hide messages based on the boolean parameter
-- @param show: A boolean indicating whether to show or hide messages
function ShowMessages(show: boolean)
	-- Get the root element of the main UI from the GameManager
	local rootElement = GM.MainUI.GetRoot()
	-- Recursively search for the UIWorld element in the parent and set its display state
	FindAndHideUIWorld(rootElement.parent, true, show)
end

-- Function to enable or disable the showing of messages
-- @param show: A boolean indicating whether to enable or disable message display
function EnableShowingMessages(show: boolean)
	-- Print the current state of message display to the console
	print("Enable Showing Chats: ", tostring(show))
	-- Update the flag controlling message display
	_showingMessages = show

	-- Call ShowMessages to update the UI based on the new state
	ShowMessages(show)
end
