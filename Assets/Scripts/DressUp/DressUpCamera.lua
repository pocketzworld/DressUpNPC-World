--!Type(Client)

--!Header("Zoom Settings")
--!SerializeField
local zoom: number = 15 -- Current zoom level of the camera
--!SerializeField
local zoomMin: number = 10 -- Minimum zoom level
--!SerializeField
local zoomMax: number = 50 -- Maximum zoom level
--!SerializeField
local fov: number = 30 -- Field of view for the camera
--!Header("Defaults")
--!SerializeField
local allowRotation: boolean = true -- Flag to allow camera rotation
--!SerializeField
local pitch: number = 30 -- Pitch angle of the camera
--!SerializeField
local yaw: number = 45 -- Yaw angle of the camera
--!SerializeField
local centerOnCharacterWhenSpawned: boolean = true -- Flag to center camera on character when spawned
--!Tooltip("0 means no centering, as you approach 1 the centering will get faster, 1 means immediate centering")
--!Range(0, 1)
--!SerializeField
local centerOnCharacterWhenMovingSpeed: number = 0 -- Speed of centering on character when moving
--!SerializeField
local _defaultCameraCutsceneSettings: CameraCutsceneSettings = nil -- Default cutscene settings for the camera

--!SerializeField
local _panToTargetCenterTime: number = 2 -- Time taken to pan to a target

--!SerializeField
local keepPlayerInView: boolean = false -- Flag to keep the player in view
--!SerializeField
local keepPlayerInViewPanDuration: number = 0.5 -- Duration for panning to keep player in view

-- Enum for camera movement states
local CameraMoveStateEnum = {
	None = 0, -- No movement
	ManualControl = 1, -- Manual control of the camera
	Resetting = 2, -- Resetting the camera
	PlayerOffScreenFollow = 3, -- Following player when off-screen
	Centering = 4, -- Centering the camera
	PanningToTarget = 5, -- Panning to a target
}

-- Enum for camera zoom states
local CameraZoomStateEnum = {
	None = 0, -- No zooming
	Zooming = 1, -- Currently zooming
}

-- Initialize camera states
local cameraMoveState = CameraMoveStateEnum.None
local cameraZoomState = CameraZoomStateEnum.None
local _inputEnabled: boolean = true -- Flag to enable or disable input

-- Get the camera component attached to the GameObject
local camera = self.gameObject:GetComponent(Camera)
if camera == nil then
	print("HighriseCameraController requires a Camera component on the GameObject its attached to.")
	return
end
local cameraRig: Transform = camera.transform -- Quick reference to the camera's transform

-- Variables for camera inertia and movement
local inertiaVelocity: Vector3 = Vector3.zero -- Current velocity of the camera from inertia
local inertiaMagnitude: number = 0 -- Magnitude of the current inertia velocity
local inertiaMultiplier: number = 2 -- Multiplier for inertia force
local closeMaxInitialInertia: number = 35 -- Max inertia force at closest zoom
local farMaxInitialIntertia: number = 150 -- Max inertia force at farthest zoom
local inertiaDampeningFactor: number = 0.93 -- Factor to scale inertia force over time

-- Variables for keeping the player in view
local playerViewBoundsPercentage: number = 0.7 -- Percentage of screen for player movement without camera movement
local playerOutOfViewScreenMoveSpeedMin: number = 0.4 -- Min speed of camera to keep player in view
local playerOutOfViewScreenMoveSpeedMax: number = 2.0 -- Max speed of camera to keep player in view

-- Resetting variables
local resetTime: number = 0
local resetLerpDuration: number = 1.2 -- Duration for lerping back to character
local defaultZoom = zoom -- Store the default zoom level

-- Variables for pinch gesture
local initialZoomOfPinch: number = zoom -- Initial zoom level at the start of pinch
local wasPinching: boolean = false -- Flag to check if the last frame was pinching

-- Variables for panning
local wasPanning: boolean = false
local panTargetStart: Vector3 = Vector3.zero -- Starting position for panning

-- Variables for player position and camera rotation
local playerPanStartScreenPos: Vector2 = Vector2.zero
local outOfViewStartTime: number = 0

local rotation: Vector3 = Vector3.zero -- Rotation of the camera
local lastDirection: Vector2 = Vector2.zero -- Direction of the last pinch gesture
local lastPinchWorldPosition: Vector3 = Vector3.zero -- Last world position during pinch

local target = Vector3.zero -- Point the camera is looking at

-- Variables for cutscene settings and target positions
local _cutsceneSettings: CameraCutsceneSettings = nil
local _targetPosition: Vector3 = nil
local _targetZoom: number = 0
local _centerTimer: number = 0
local _targetSpeed: number = 0
local _targetStartPos: Vector3 = Vector3.zero
local _startZoom: number = 0
local _startPitch: number = 0
local _targetPitch: number = 0
local _startYaw: number = 0
local _targetYaw: number = 0

local localCharacterInstantiatedEvent = nil -- Event for local character instantiation

-- Function to initialize the camera controller
function self:Start()
	-- Center camera on character if the flag is set
	if centerOnCharacterWhenSpawned and client.localPlayer then
		localCharacterInstantiatedEvent = client.localPlayer.CharacterChanged:Connect(function(player, character)
			if character then
				OnLocalCharacter(player, character) -- Call function when local character is instantiated
			end
		end)

		function OnLocalCharacter(player, character)
			localCharacterInstantiatedEvent:Disconnect() -- Disconnect the event after handling
			localCharacterInstantiatedEvent = nil

			local position = character.gameObject.transform.position -- Get character position
			CenterOn(position) -- Center camera on character
		end
	end

	_cutsceneSettings = _defaultCameraCutsceneSettings -- Set default cutscene settings
	self:ResetCamera() -- Reset camera to initial state
end

-- Function to reset the camera to its default state
function ResetCamera()
	cameraMoveState = CameraMoveStateEnum.None -- Set camera move state to none

	target = Vector3.zero -- Reset target position
	if centerOnCharacterWhenSpawned and client.localPlayer and client.localPlayer.character then
		target = client.localPlayer.character.gameObject.transform.position -- Center on character position
	end

	rotation = Vector3.zero -- Reset rotation
	zoom = defaultZoom -- Reset zoom to default

	playerPanStartScreenPos = Vector2.zero -- Reset pan start position
	outOfViewStartTime = 0 -- Reset out of view start time

	ResetPinchDrag() -- Reset pinch drag state
	ResetZoomScale() -- Reset zoom scale
	ResetInertia() -- Reset inertia

	UpdatePosition() -- Update camera position
end

-- Function to enable or disable input
function SetInputEnabled(enabled: boolean)
	_inputEnabled = enabled -- Set input enabled state
end

-- Function to get the centering speed
function GetCenteringSpeed()
	return centerOnCharacterWhenMovingSpeed -- Return the centering speed
end

-- Function to check if the camera is active
function IsActive()
	return camera ~= nil and camera.isActiveAndEnabled and self.isActiveAndEnabled -- Check if camera is active
end

-- Reset event listener for the client
client.Reset:Connect(function(evt)
	if not IsActive() or not _inputEnabled then
		return -- Exit if camera is not active or input is disabled
	end

	if not client.localPlayer or not client.localPlayer.character then
		return -- Exit if local player or character is not available
	end

	ResetInertia() -- Reset inertia
	cameraMoveState = CameraMoveStateEnum.Resetting -- Set camera move state to resetting

	resetTime = Time.time -- Store the current time for resetting
end)

-- Mouse wheel event listener for zooming
Input.MouseWheel:Connect(function(evt)
	if not IsActive() or not _inputEnabled then
		return -- Exit if camera is not active or input is disabled
	end

	if evt.delta.y < 0.0 then
		ZoomIn() -- Zoom in if mouse wheel is scrolled down
		PostZoomMoveTowardsScreenPoint(evt.position) -- Move camera towards the screen point
	else
		ZoomOut() -- Zoom out if mouse wheel is scrolled up
		PostZoomMoveTowardsScreenPoint(evt.position) -- Move camera towards the screen point
	end
end)

-- Event listener for pinch or drag start
Input.PinchOrDragBegan:Connect(function(evt)
	if not IsActive() or not _inputEnabled then
		return -- Exit if camera is not active or input is disabled
	end

	cameraMoveState = CameraMoveStateEnum.ManualControl -- Set camera move state to manual control

	ResetPinchDrag() -- Reset pinch drag state
	ResetZoomScale() -- Reset zoom scale
	ResetInertia() -- Reset inertia
end)

-- Event listener for pinch or drag changes
Input.PinchOrDragChanged:Connect(function(evt)
	if not IsActive() or not _inputEnabled then
		return -- Exit if camera is not active or input is disabled
	end

	cameraMoveState = CameraMoveStateEnum.ManualControl -- Set camera move state to manual control

	if Input.isMouseInput then
		if Input.isAltPressed then
			MouseRotateCamera(evt) -- Rotate camera with mouse if Alt is pressed
		else
			PanCamera(evt) -- Pan camera with mouse
		end
	else
		if evt.isPinching then
			PinchRotateAndZoomCamera(evt) -- Rotate and zoom camera with pinch gesture
		else
			PanCamera(evt) -- Pan camera with touch
		end
	end

	wasPinching = evt.isPinching -- Update pinch state
	wasPanning = not evt.isPinching -- Update pan state
end)

-- Event listener for pinch or drag end
Input.PinchOrDragEnded:Connect(function(evt)
	if not IsActive() or not _inputEnabled then
		return -- Exit if camera is not active or input is disabled
	end

	cameraMoveState = CameraMoveStateEnum.None -- Reset camera move state

	if not Input.isMouseInput then
		ApplyInertia(CalculateWorldVelocity(evt)) -- Apply inertia based on swipe velocity
	end
end)

-- Cached plane for world up direction to avoid re-generating every call
local worldUpPlane = Plane.new(Vector3.up, Vector3.new(0, 0, 0))

-- Function to convert screen position to world point
function ScreenPositionToWorldPoint(camera, screenPosition)
	local ray = camera:ScreenPointToRay(screenPosition) -- Create a ray from the camera to the screen position

	local success, distance = worldUpPlane:Raycast(ray) -- Check if the ray intersects with the world up plane
	if not success then
		print("HighriseCameraController Failed to cast ray down into the world. Is the camera not looking down?")
		return Vector3.zero -- Return zero vector if raycast fails
	end

	return ray:GetPoint(distance) -- Return the world point at the intersection
end

-- Function to pan the camera
function PanCamera(evt)
	if not wasPanning then
		panTargetStart = ScreenPositionToWorldPoint(camera, evt.position) -- Set the start position for panning
	end

	PanWorldPositionToScreenPosition(panTargetStart, evt.position) -- Pan the camera to the target position
end

-- Function to rotate the camera with mouse input
function MouseRotateCamera(evt)
	local screenDelta = evt.position - (evt.position - evt.deltaPosition) -- Calculate the change in screen position
	local xAngle = screenDelta.x / Screen.width * 360.0 -- Calculate the rotation angle based on screen width
	Rotate(Vector2.new(xAngle, 0)) -- Rotate the camera
end

-- Function to rotate the camera by a given amount
function Rotate(rotate)
	if not allowRotation then
		return -- Exit if rotation is not allowed
	end

	rotation = rotation + Vector3.new(rotate.y, rotate.x, 0) -- Update rotation
	rotation.y = rotation.y + 3600 -- Ensure positive value
	rotation.y = rotation.y % 360 -- Ensure value is between 0 and 360
end

-- Function to handle pinch rotation and zoom
function PinchRotateAndZoomCamera(evt)
	if not wasPinching then
		lastPinchWorldPosition = ScreenPositionToWorldPoint(camera, evt.position) -- Store the last pinch world position
		lastDirection = evt.direction -- Store the last pinch direction
		ResetZoomScale() -- Reset zoom scale
	end

	local deltaAngle = Vector2.SignedAngle(lastDirection, evt.direction) -- Calculate the change in angle

	if Mathf.Abs(deltaAngle) > 0 then
		Rotate(Vector2.new(deltaAngle, 0)) -- Rotate the camera based on pinch direction
		UpdatePosition() -- Update camera position

		PanWorldPositionToScreenPosition(lastPinchWorldPosition, evt.position) -- Pan camera to the pinch position
		UpdatePosition() -- Update camera position

		lastDirection = evt.direction -- Update last direction
		lastPinchWorldPosition = ScreenPositionToWorldPoint(camera, evt.position) -- Update last pinch world position
	end

	if evt.scale > 0 then
		local newZoom = initialZoomOfPinch + (initialZoomOfPinch / evt.scale - initialZoomOfPinch) -- Calculate new zoom level
		zoom = Mathf.Clamp(newZoom, zoomMin, zoomMax) -- Clamp zoom level within min and max

		PostZoomMoveTowardsScreenPoint(evt.position) -- Move camera towards the screen point after zoom
	end
end

-- Function to pan the camera from world position to screen position
function PanWorldPositionToScreenPosition(worldPosition, screenPosition)
	local targetPlane = Plane.new(Vector3.up, worldPosition) -- Create a plane at the world position

	local ray = camera:ScreenPointToRay(screenPosition) -- Create a ray from the camera to the screen position
	local success, distance = targetPlane:Raycast(ray) -- Check if the ray intersects with the target plane
	if success then
		local dragAdjustment = -(ray:GetPoint(distance) - worldPosition) -- Calculate drag adjustment
		dragAdjustment.y = 0 -- Ignore vertical adjustment

		target = target + dragAdjustment -- Update target position
	end
end

-- Function to zoom in the camera
function ZoomIn()
	zoom = Mathf.Clamp(zoom - 1, zoomMin, zoomMax) -- Decrease zoom level
end

-- Function to zoom out the camera
function ZoomOut()
	zoom = Mathf.Clamp(zoom + 1, zoomMin, zoomMax) -- Increase zoom level
end

-- Function to move the camera towards a screen point after zooming
function PostZoomMoveTowardsScreenPoint(screenPosition)
	local ray = camera:ScreenPointToRay(screenPosition) -- Create a ray from the camera to the screen position
	local success, distance = worldUpPlane:Raycast(ray) -- Check if the ray intersects with the world up plane
	if success then
		local desiredPosition = ray:GetPoint(distance - CalculateCameraDistanceToTarget()) -- Calculate desired position
		target = desiredPosition - CalculateRelativePosition() -- Update target position
		UpdatePosition() -- Update camera position
	end
end

-- Function to reset pinch drag state
function ResetPinchDrag()
	lastDirection = Vector2.zero -- Reset last direction
	lastPinchWorldPosition = Vector3.zero -- Reset last pinch world position
	wasPanning = false -- Reset panning state
	wasPinching = false -- Reset pinching state
end

-- Function to reset zoom scale
function ResetZoomScale()
	initialZoomOfPinch = zoom -- Store the initial zoom level
end

-- Function to reset inertia
function ResetInertia()
	inertiaVelocity = Vector3.zero -- Reset inertia velocity
	inertiaMagnitude = 0 -- Reset inertia magnitude
end

-- Maximum swipe velocity for applying inertia
local MaxSwipeVelocity = 400

-- Function to calculate world velocity based on swipe event
function CalculateWorldVelocity(evt)
	local velocity = evt.velocity -- Get swipe velocity
	velocity.x = Mathf.Clamp(velocity.x, -MaxSwipeVelocity, MaxSwipeVelocity) -- Clamp x velocity
	velocity.y = Mathf.Clamp(velocity.y, -MaxSwipeVelocity, MaxSwipeVelocity) -- Clamp y velocity

	local screenStart = evt.position -- Starting screen position
	local screenEnd = evt.position + velocity -- Ending screen position based on velocity

	local worldStart = ScreenPositionToWorldPoint(camera, screenStart) -- Convert start position to world point
	local worldEnd = ScreenPositionToWorldPoint(camera, screenEnd) -- Convert end position to world point

	local result = -(worldEnd - worldStart) -- Calculate the resulting world velocity
	return result -- Return the calculated velocity
end

-- Function to apply inertia based on world velocity
function ApplyInertia(worldVelocity)
	local t = Easing.Quadratic((zoom - zoomMin) / (zoomMax - zoomMin)) -- Calculate inertia factor based on zoom
	local currentMaxVelocity = Mathf.Lerp(closeMaxInitialInertia, farMaxInitialIntertia, t) -- Lerp max velocity based on zoom

	inertiaVelocity = Vector3.ClampMagnitude(worldVelocity * inertiaMultiplier, currentMaxVelocity) -- Clamp inertia velocity
	inertiaMagnitude = inertiaVelocity.magnitude -- Update inertia magnitude
end

-- Function to center the camera on a new target position
function CenterOn(newTarget, newZoom)
	zoom = newZoom or zoom -- Update zoom if provided

	target = newTarget -- Update target position
	zoom = Mathf.Clamp(zoom, zoomMin, zoomMax) -- Clamp zoom level
end

-- Function to calculate the distance from the camera to the target
function CalculateCameraDistanceToTarget()
	local frustumHeight = zoom -- Get the height of the frustum
	local distance = (frustumHeight * 0.5) / math.tan(fov * 0.5 * Mathf.Deg2Rad) -- Calculate distance
	return distance -- Return calculated distance
end

-- Function to calculate the relative position of the camera based on rotation
function CalculateRelativePosition()
	local rotation = Quaternion.Euler(
		pitch + rotation.x, -- Calculate pitch
		yaw + rotation.y, -- Calculate yaw
		0
	)

	local cameraPos = Vector3.back * CalculateCameraDistanceToTarget() -- Get camera position based on distance
	cameraPos = rotation * cameraPos -- Apply rotation to camera position

	return cameraPos -- Return calculated camera position
end

-- Function to pan the camera if the player is out of the view bounds
function PanIfPlayerOutOfView()
	-- Check if the local player and their character exist
	if client.localPlayer and client.localPlayer.character then
		-- Calculate the screen bounds for the player's view based on a percentage
		local screenMinX = camera.pixelWidth / 2 - (camera.pixelWidth / 2) * playerViewBoundsPercentage
		local screenMaxX = camera.pixelWidth / 2 + (camera.pixelWidth / 2) * playerViewBoundsPercentage

		local screenMinY = camera.pixelHeight / 2 - (camera.pixelHeight / 2) * playerViewBoundsPercentage
		local screenMaxY = camera.pixelHeight / 2 + (camera.pixelHeight / 2) * playerViewBoundsPercentage

		-- Get the player's screen position
		local playerScreenPosVector3 =
			camera:WorldToScreenPoint(client.localPlayer.character.gameObject.transform.position)
		local playerScreenPos = Vector2.new(playerScreenPosVector3.x, playerScreenPosVector3.y)

		-- Check if the player is out of the defined screen bounds
		if
			playerScreenPos.x < screenMinX
			or playerScreenPos.x > screenMaxX
			or playerScreenPos.y < screenMinY
			or playerScreenPos.y > screenMaxY
		then
			-- If the camera is not already in the follow state, initialize the pan
			if cameraMoveState ~= CameraMoveStateEnum.PlayerOffScreenFollow then
				outOfViewStartTime = Time.time
				playerPanStartScreenPos = playerScreenPos
				cameraMoveState = CameraMoveStateEnum.PlayerOffScreenFollow
			end

			-- Reset any inertia effects
			ResetInertia()

			-- Calculate the target screen position to pan towards
			local targetScreenPosition = Vector2.new(
				Mathf.Clamp(playerScreenPos.x, screenMinX, screenMaxX),
				Mathf.Clamp(playerScreenPos.y, screenMinY, screenMaxY)
			)

			-- Smoothly interpolate the camera's position towards the target position
			local lerpAmount = Mathf.SmoothStep(0, 1, (Time.time - outOfViewStartTime) / keepPlayerInViewPanDuration)
			PanWorldPositionToScreenPosition(
				client.localPlayer.character.gameObject.transform.position,
				Vector2.Lerp(playerPanStartScreenPos, targetScreenPosition, lerpAmount)
			)
		else
			-- Reset the camera move state if the player is back in view
			cameraMoveState = CameraMoveStateEnum.None
		end
	end
end

-- Constants for inertia handling
local InertiaMinVelocity = 0.5 -- Minimum velocity to prevent infinite slow drag
local InertiaStepDuration = 1 / 60 -- Duration for each inertia step normalized to 60fps

-- Function to update the inertia of the camera movement
function UpdateInertia()
	-- Check if there is no mouse input and inertia magnitude is above the minimum
	if not Input.isMouseInput and inertiaMagnitude > InertiaMinVelocity then
		-- Calculate the reduction in velocity based on the dampening factor
		local stepReduction = (1.0 - inertiaDampeningFactor) / (InertiaStepDuration / Time.deltaTime)
		local velocityDampener = 1.0 - math.min(math.max(stepReduction, 0), 1)
		inertiaVelocity = inertiaVelocity * velocityDampener
		inertiaMagnitude = inertiaMagnitude * velocityDampener
		target = target + (inertiaVelocity * Time.deltaTime) -- Update the target position based on inertia
	end
end

-- Function to update the camera's position and field of view
function UpdatePosition()
	camera.fieldOfView = fov -- Set the camera's field of view

	-- Update the camera rig's position and orientation
	cameraRig.position = CalculateRelativePosition() + target
	cameraRig:LookAt(target) -- Make the camera look at the target position
end

-- Function to check if the character is currently moving
function IsCharacterMoving()
	-- Return false if the character does not exist
	if not client.localPlayer.character then
		return false
	end

	-- Get the current state of the character
	local state = client.localPlayer.character.state

	-- Return true if the character is walking, running, or jumping
	return state == CharacterState.Walking or state == CharacterState.Running or state == CharacterState.Jumping
end

-- Function to pan the camera towards a specified character
function PanToCharacter(character)
	-- Return if the character is nil
	if not character then
		return
	end

	-- Set the target position to the character's position and update the camera state
	_targetPosition = character.gameObject.transform.position
	cameraMoveState = CameraMoveStateEnum.PanningToTarget
	_centerTimer = 0
	_targetStartPos = target
	local distance = Vector3.Distance(target, _targetPosition) -- Calculate distance to target
	_targetSpeed = distance / _panToTargetCenterTime -- Set the target speed based on distance
end

-- Function to zoom out to a specified character with given settings
function ZoomOutToCharacter(settings: CameraCutsceneSettings)
	_cutsceneSettings = settings
	_startZoom = zoom
	_targetZoom = _cutsceneSettings.Zoom
	_startPitch = pitch
	_targetPitch = _cutsceneSettings.Pitch
	_startYaw = yaw
	_targetYaw = yaw
	_centerTimer = 0
	cameraZoomState = CameraZoomStateEnum.Zooming -- Set the camera zoom state to zooming
end

-- Function to start centering the camera on a specified position with settings
function StartCenteringOnPosition(settings: CameraCutsceneSettings, position: Vector3, forward: Vector3)
	-- Return if the position is nil
	if not position then
		return
	end

	_cutsceneSettings = settings
	_targetPosition = position
	cameraMoveState = CameraMoveStateEnum.Centering
	cameraZoomState = CameraZoomStateEnum.Zooming
	_targetZoom = _cutsceneSettings.Zoom
	_startZoom = zoom
	_startPitch = pitch
	_targetPitch = _cutsceneSettings.Pitch
	_centerTimer = 0
	_targetStartPos = target
	local distance = Vector3.Distance(target, _targetPosition) -- Calculate distance to target position
	_targetSpeed = distance / _cutsceneSettings.Duration -- Set target speed based on duration
	-- Calculate yaw from the forward vector
	_startYaw = yaw
	_targetYaw = Mathf.Atan2(forward.x, forward.z) * Mathf.Rad2Deg
	rotation = Vector3.zero -- Reset rotation
end

-- Function to center the camera on a character with a springiness effect
function CenterOnCharacterWithSpringiness(character, speed)
	speed = Mathf.Clamp(speed, 0, 1) -- Clamp speed between 0 and 1
	local updatedTarget = character.gameObject.transform.position * speed + target * (1 - speed) -- Calculate updated target position
	CenterOn(updatedTarget) -- Center the camera on the updated target

	-- Return to manual control when the character is centered
	if Vector3.Distance(updatedTarget, character.gameObject.transform.position) < 0.05 then
		cameraMoveState = CameraMoveStateEnum.ManualControl
	end
end

-- Function to zoom in on a target based on step progress
function ZoomOnTarget(stepProgress)
	local t = EaseInOutSine(stepProgress) -- Calculate easing value
	zoom = Mathf.Lerp(_startZoom, _targetZoom, t) -- Interpolate zoom value
end

-- Function to move the camera towards a target position based on step progress
function MoveTowardsTarget(stepProgress)
	-- Calculate speed for movement
	local t = EaseInOutSine(stepProgress)
	local newTarget = Vector3.Lerp(_targetStartPos, _targetPosition + _cutsceneSettings.TargetOffset, t) -- Interpolate target position
	CenterOn(newTarget) -- Center the camera on the new target
end

-- Function to adjust the camera's pitch towards a target pitch based on step progress
function MoveToTargetPitch(stepProgress)
	local t = EaseInOutSine(stepProgress) -- Calculate easing value
	pitch = Mathf.Lerp(_startPitch, _targetPitch, t) -- Interpolate pitch value

	yaw = Mathf.LerpAngle(_startYaw, _targetYaw, t) -- Interpolate yaw value
end

-- Easing function for smooth transitions
function EaseInOutSine(t: number)
	return -(Mathf.Cos(Mathf.PI * t) - 1) * 0.5 -- Calculate eased value
end

-- Update function to be called every frame
function self:Update()
	-- Check if the camera is active
	if not self:IsActive() then
		return
	end

	-- Handle camera movement states
	if cameraMoveState == CameraMoveStateEnum.None or cameraMoveState == CameraMoveStateEnum.PlayerOffScreenFollow then
		if keepPlayerInView then
			PanIfPlayerOutOfView() -- Pan the camera if the player is out of view
		end
	elseif cameraMoveState == CameraMoveStateEnum.Resetting then
		-- Smoothly reset the camera position and rotation
		local lerp = (Time.time - resetTime) / resetLerpDuration

		local position = client.localPlayer.character.gameObject.transform.position
		target = Vector3.Lerp(target, position, lerp) -- Interpolate target position
		rotation.x = Mathf.LerpAngle(rotation.x, 0, lerp) -- Interpolate rotation x
		rotation.y = Mathf.LerpAngle(rotation.y, 0, lerp) -- Interpolate rotation y
		zoom = Mathf.Lerp(zoom, defaultZoom, lerp) -- Interpolate zoom

		-- Check if the reset is complete
		if lerp >= 1 then
			cameraMoveState = CameraMoveStateEnum.None -- Reset camera move state
		end
	end

	-- Update inertia if the camera is in a suitable state
	if cameraMoveState == CameraMoveStateEnum.None or cameraMoveState == CameraMoveStateEnum.ManualControl then
		UpdateInertia()
	end

	-- Center the camera on the character if they are moving
	if centerOnCharacterWhenMovingSpeed > 0 and IsCharacterMoving() then
		CenterOnCharacterWithSpringiness(client.localPlayer.character, centerOnCharacterWhenMovingSpeed)
	end

	_centerTimer += Time.deltaTime -- Increment the center timer
	-- Handle centering and panning states
	if cameraMoveState == CameraMoveStateEnum.Centering or cameraMoveState == CameraMoveStateEnum.PanningToTarget then
		if _centerTimer > _cutsceneSettings.Duration then
			cameraMoveState = CameraMoveStateEnum.None -- Reset camera move state when done
		else
			local step = _centerTimer / _cutsceneSettings.Duration -- Calculate step progress
			MoveTowardsTarget(step) -- Move towards the target
		end
	end

	-- Handle zooming state
	if cameraZoomState == CameraZoomStateEnum.Zooming then
		if _centerTimer > _cutsceneSettings.Duration then
			cameraZoomState = CameraZoomStateEnum.None -- Reset zoom state when done
		else
			local step = _centerTimer / _cutsceneSettings.Duration -- Calculate step progress
			ZoomOnTarget(step) -- Zoom towards the target
			MoveToTargetPitch(step) -- Adjust pitch towards target
		end
	end

	UpdatePosition() -- Update the camera's position and orientation
end
