--!Type(UI)

-- Import necessary modules for game management and tweening animations
local GameManager = require("GameManager")
local TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

-- Bindings for UI elements
--!Bind
local _root: VisualElement = nil -- Root visual element for the UI
--!Bind
local _nodeBase: VisualElement = nil -- Base visual element for the node
--!Bind
local _nodeImage: Image = nil -- Image component of the node

-- Serialized fields for configuration
--!SerializeField
local _nodeAnimDuration: number = 0.5 -- Duration for node animations
--!SerializeField
local _scaelUpSound: AudioShader = nil -- Sound to play when scaling up
--!SerializeField
local _pulseTime: number = 1 -- Duration for pulsing animation
--!SerializeField
local _pulseSize: number = 1.1 -- Size increase for pulsing animation

-- Local variables for managing state
local _parent: NPCDressUpTaskController = nil -- Reference to the parent controller
local _nodeData: DressUpNode = nil -- Data associated with the dress-up node
local _worldAnchor: Transform = nil -- World position anchor for the node
local _scalingUp: boolean = false -- Flag to indicate if the node is scaling up
local _destroyed: boolean = false -- Flag to indicate if the node has been destroyed
local _pulsingTween = nil -- Tween instance for pulsing animation

-- Function to get the root visual element
function GetRoot(): VisualElement
	return _root -- Return the root element
end

-- Function called when the client is destroyed
function self.ClientOnDestroy()
	_destroyed = true -- Mark as destroyed
	if _pulsingTween then
		_pulsingTween:stop() -- Stop any active pulsing tween
	end
end

-- Function to set the chosen state of the node
function SetChosen(chosen: boolean)
	if chosen then
		_nodeBase:RemoveFromClassList("notchosen") -- Remove 'notchosen' class
		_nodeBase:AddToClassList("chosen") -- Add 'chosen' class

		if _pulsingTween then
			_pulsingTween:stop() -- Stop pulsing if chosen
		end
	else
		_nodeBase:RemoveFromClassList("chosen") -- Remove 'chosen' class
		_nodeBase:AddToClassList("notchosen") -- Add 'notchosen' class

		if not _scalingUp then
			PlayPulsingAnim(0, 1) -- Start pulsing animation if not scaling up
		end
	end
end

-- Function to handle node click events
local function OnNodeClicked()
	Audio:PlaySoundGlobal(_scaelUpSound, 1, 1, false) -- Play scale-up sound
	_parent.OnNodeClicked(_nodeData) -- Notify parent of the click event
end

-- Function to update the screen position of the node based on world position
local function UpdateScreenPositionFromWorld()
	local camera: Camera = GameManager.MainCamera -- Get the main camera
	local screenPosition = camera:WorldToViewportPoint(_worldAnchor.position) -- Convert world position to screen position

	-- Calculate UI coordinates based on screen position
	local uiX = screenPosition.x * _root.parent.contentRect.width
	local uiY = (1 - screenPosition.y) * _root.parent.contentRect.height
	_nodeBase.style.left = StyleLength.new(uiX - (_nodeBase.layout.width * 0.5)) -- Center the node horizontally
	_nodeBase.style.top = StyleLength.new(uiY - (_nodeBase.layout.height * 0.5)) -- Center the node vertically
end

-- Function called every frame to update the node's position
function self:ClientUpdate()
	UpdateScreenPositionFromWorld() -- Update the screen position
end

-- Function to initialize the node with parent, data, and world anchor
function Init(parent: NPCDressUpTaskController, nodeData: DressUpNode, worldAnchor: Transform)
	_parent = parent -- Set the parent controller
	_nodeData = nodeData -- Set the node data
	_worldAnchor = worldAnchor -- Set the world anchor
	_scalingUp = true -- Set scaling up flag

	_nodeBase:RegisterPressCallback(OnNodeClicked) -- Register click callback
	_nodeImage.image = _nodeData.DisplayData.ImageSprite.texture -- Set the node image
end

-- Function to hide the node by scaling it down to zero
function HideNodeForScaleUp()
	_nodeBase.style.scale = StyleScale.new(Vector2.zero) -- Set scale to zero
end

-- Function to play the scale-up animation
function PlayScaleUpAnim()
	Audio:PlaySoundGlobal(_scaelUpSound, 1, 1, false) -- Play scale-up sound
	_nodeBase.style.scale = StyleScale.new(Vector2.zero) -- Start from zero scale
	local myTween = Tween
		:new(function(value) -- onUpdate callback
			_nodeBase.style.scale = StyleScale.new(Vector2.one * value) -- Update scale based on tween value
		end)
		:FromTo(0, 1) -- Tween from 0 to 1
		:Easing(Easing.easeOutBack) -- Use ease-out-back easing
		:Duration(_nodeAnimDuration) -- Set duration for the animation

	myTween:start() -- Start the tween
	Timer.After(_nodeAnimDuration, function() -- After the animation duration
		if _destroyed then
			return -- Exit if destroyed
		end
		_scalingUp = false -- Mark scaling up as false
		print("PlayPulsingAnim") -- Debug print
		PlayPulsingAnim(0, 1) -- Start pulsing animation
	end)
end

-- Function to play the pulsing animation
function PlayPulsingAnim(start: number, finish: number)
	if _scalingUp then
		return -- Exit if scaling up
	end
	if _pulsingTween then
		_pulsingTween:stop() -- Stop any existing pulsing tween
	end
	_pulsingTween = Tween
		:new(function(value) -- onUpdate callback
			local size = 1 + (value * _pulseSize) -- Calculate new size based on tween value
			_nodeBase.style.scale = StyleScale.new(Vector2.one * size) -- Update scale
		end)
		:FromTo(start, finish) -- Tween from start to finish
		:Easing(Easing.easeInOutSin) -- Use ease-in-out sine easing
		:Duration(_pulseTime) -- Set duration for the pulsing animation
		:OnComplete(function() -- Callback when tween completes
			local size = 1 + (finish * _pulseSize) -- Calculate final size
			_nodeBase.style.scale = StyleScale.new(Vector2.one * size) -- Set final scale
			PlayPulsingAnim(finish, start) -- Start pulsing animation in reverse
		end)

	_pulsingTween:start() -- Start the pulsing tween
end
