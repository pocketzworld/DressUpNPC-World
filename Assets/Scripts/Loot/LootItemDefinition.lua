--!Type(ScriptableObject)  -- This line indicates that the script is a type of ScriptableObject, which is a Unity-specific class used to store data.

--!SerializeField  -- This attribute allows the following variable to be serialized and visible in the Unity Inspector.
local _currencyRewardTemplate: CurrencyTemplate = nil -- Declares a variable to hold a template for currency rewards, initialized to nil.

--!SerializeField  -- This attribute allows the following variable to be serialized and visible in the Unity Inspector.
local _clothingRewardTemplate: ClothingTemplate = nil -- Declares a variable to hold a template for clothing rewards, initialized to nil.

--!SerializeField  -- This attribute allows the following variable to be serialized and visible in the Unity Inspector.
local _clothingCollectionRewardTemplate: ClothingCollectionRewardTemplate = nil -- Declares a variable to hold a template for clothing collection rewards, initialized to nil.

-- Function to retrieve the appropriate reward template based on the available templates.
local function GetRewardTemplate(): any
	-- Check if the clothing reward template is set; if so, return it.
	if _clothingRewardTemplate then
		return _clothingRewardTemplate
	-- If the clothing reward template is not set, check for the currency reward template.
	elseif _currencyRewardTemplate then
		return _currencyRewardTemplate
	-- If neither of the above is set, check for the clothing collection reward template.
	elseif _clothingCollectionRewardTemplate then
		return _clothingCollectionRewardTemplate
	end
	-- If none of the templates are set, return nil.
	return nil
end
RewardTemplate = GetRewardTemplate() -- Call the GetRewardTemplate function and store the result in the RewardTemplate variable.
