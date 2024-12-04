--!Type(Module)

-- Importing the TweenModule which contains the Tween and Easing classes for animations
local TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

--!SerializeField
-- Duration for the open/close animations
local _openCloseDuration: number = 0.5

-- Function to play the opening animation for a UI element
-- @param ui: The UI element to animate
function PlayOpenAnim(ui)
	-- Check if the ui parameter is nil
	if not ui then
		print("UIPopupAnimateHelper:PlayOpenAnim - UI is nil")
		return
	end

	-- Get the root visual element of the UI
	local root: VisualElement = ui.GetRoot()
	-- If the root is nil, exit the function
	if root == nil then
		return
	end

	-- Set the initial scale of the root to zero (invisible)
	root.style.scale = StyleScale.new(Vector2.zero)

	-- Create a new Tween for the opening animation
	local myTween = Tween
		:new(function(value) -- onUpdate callback to update the scale
			root.style.scale = StyleScale.new(Vector2.one * value) -- Scale from 0 to 1
		end)
		:FromTo(0, 1) -- Tween from 0 to 1
		:Duration(_openCloseDuration) -- Set the duration of the tween
		:Easing(Easing.easeInOutSin) -- Set the easing function for smooth animation

	-- Start the tween animation
	myTween:start()
end

-- Function to play a slide-up animation with a specified height
-- @param root: The root visual element to animate
-- @param savedTop: The original top position of the element
-- @param height: The height to slide from
local function PlaySlideUpWithHeight(root: VisualElement, savedTop: number, height: number)
	-- Set the initial top position to the specified height
	root.style.top = StyleLength.new(height)

	-- Create a new Tween for the slide-up animation
	local myTween = Tween
		:new(function(value) -- onUpdate callback to update the top position
			root.style.top = StyleLength.new(value) -- Slide from height to savedTop
		end)
		:FromTo(height, savedTop) -- Tween from height to savedTop
		:Duration(_openCloseDuration) -- Set the duration of the tween
		:Easing(Easing.easeInOutSin) -- Set the easing function for smooth animation

	-- Start the tween animation
	myTween:start()
end

-- Function to play the slide-up animation for a UI element
-- @param ui: The UI element to animate
function PlaySlideUpAnim(ui)
	-- Check if the ui parameter is nil
	if not ui then
		print("UIPopupAnimateHelper:PlaySlideUpAnim - UI is nil")
		return
	end

	-- Get the root visual element of the UI
	local root: VisualElement = ui.GetRoot()
	-- If the root is nil, exit the function
	if root == nil then
		return
	end

	-- Set the initial opacity of the root to 0 (invisible)
	root.style.opacity = StyleFloat.new(0)

	-- Delay the execution of the following code by 0.05 seconds
	Timer.After(0.05, function()
		-- Save the current top position of the root
		local savedTop = root.style.top.value.value
		-- Set the opacity to 1 (fully visible)
		root.style.opacity = StyleFloat.new(1)
		-- Call the slide-up function with the saved top position and the height of the UI
		PlaySlideUpWithHeight(root, savedTop, ui.GetSize().y)
	end)
end
