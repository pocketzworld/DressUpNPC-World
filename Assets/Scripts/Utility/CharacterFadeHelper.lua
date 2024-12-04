--!Type(Client)

-- Declare a material for fading effect
--!SerializeField
local _fadeMaterial: Material = nil

-- String used to access the fade property in the material
--!SerializeField
local _fadeString: string = "_FadeAlpha"

-- Table to hold renderers for the object
local _renderers: { Renderer } = nil

-- Timer to track the duration of the fade effect
local _timer: number = 0

-- Current value of the fade effect
local _val: number = 0

-- Target value for the fade effect
local _endVal: number = 0

-- Duration of the fade effect
local _duration: number = 0

-- Flag to check if the fade effect is enabled
local _enabled: boolean = false

-- Material property block to set properties on the material
local _matPropBlock: MaterialPropertyBlock = nil

-- Reference to the character being faded
local _character: Character = nil

-- Function called when the client is initialized
function self.ClientAwake()
	-- Get all Renderer components in the children of the game object
	local comps = self.gameObject:GetComponentsInChildren(Renderer, true)
	for _, comp in ipairs(comps) do
		-- Initialize the renderers table if it is nil
		if not _renderers then
			_renderers = {}
		end
		-- Add each renderer to the renderers table
		table.insert(_renderers, comp)
	end
	-- Create a new MaterialPropertyBlock instance
	_matPropBlock = MaterialPropertyBlock.new()
end

-- Function called every frame to update the fade effect
function self.ClientUpdate()
	-- If there are no renderers or the fade effect is not enabled, exit the function
	if #_renderers == 0 or not _enabled then
		return
	end

	-- Increment the timer by the time passed since the last frame
	_timer = _timer + Time.deltaTime

	-- Calculate the new fade value using linear interpolation
	local newVal = Mathf.Lerp(_val, _endVal, _timer / _duration)

	-- Set the new fade value in the material property block
	_matPropBlock:SetFloat(_fadeString, newVal)

	-- Apply the material property block to each renderer
	for _, renderer in ipairs(_renderers) do
		renderer:SetPropertyBlock(_matPropBlock)
	end

	-- Check if the fade duration has been reached
	if _timer >= _duration then
		_enabled = false -- Disable the fade effect
		-- If the end value is less than or equal to 0, deactivate the character's game object
		if _endVal <= 0 then
			_character.gameObject:SetActive(false)
		end
	end
end

-- Function to show or hide the shadow of the character
-- @param character: The character whose shadow is being modified
-- @param show: Boolean indicating whether to show or hide the shadow
local function ShowShadow(character: Character, show: boolean)
	-- Find the "Rig" child of the character's game object
	local rig = character.gameObject.transform:Find("Rig")
	if rig then
		-- Find the "Shadow" child of the rig
		local shadow = rig:Find("Shadow")
		if shadow then
			-- Set the active state of the shadow based on the show parameter
			shadow.gameObject:SetActive(show)
		end
	end
end

-- Function to start the fade effect on a character
-- @param character: The character to fade
-- @param fade: Boolean indicating whether to fade in or out
-- @param duration: Duration of the fade effect
function StartFade(character: Character, fade: boolean, duration: number)
	-- If a fade is already in progress, exit the function
	if _enabled then
		return
	end

	-- Set the character reference
	_character = character
	-- Assign the fade material to the character's render material
	_character.renderMaterial = Material.new(_fadeMaterial)
	-- Show or hide the shadow based on the fade parameter
	ShowShadow(character, not fade)
	-- Activate the character's game object
	_character.gameObject:SetActive(true)

	-- Set the duration and enable the fade effect
	_duration = duration
	_enabled = true
	_timer = 0

	-- Set the initial and target values based on the fade direction
	if fade then
		_val = 1 -- Start from fully opaque
		_endVal = 0 -- End at fully transparent
	else
		_val = 0 -- Start from fully transparent
		_endVal = 1 -- End at fully opaque
	end
end
