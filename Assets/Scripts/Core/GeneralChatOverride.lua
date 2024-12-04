--[[
	
	Copyright (c) 2024 Pocket Worlds

	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software
	in a product, an acknowledgment in the product documentation would be
	appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
	
--]] 

--!Type(Module)

--!SerializeField
local noVoiceChannelName: string = "Silent Zone"

--!SerializeField
local voiceChannelName: string = "Open Mic"

--!SerializeField
local enableVoice: boolean = true

--!SerializeField
--!Tooltip("If true, two channels will be created, the default channel where no one can speak and a joinable voice channel where everyone can speak")
local optInVoiceChannel : boolean = true

--!SerializeField
local enableProximityChat: boolean = true

--!SerializeField
--!Tooltip("The distance between players where their voice starts to get softer")
local maxVolumeDistance: number = 15

--!SerializeField
--!Tooltip("The distance between players where you can no longer hear them")
local minVolumeDistance: number = 30

local channels = {}

local function CreateChannel(name : string, allowsVoice : boolean) : ChannelInfo
	local channel = Chat:CreateChannel(name, true, allowsVoice)
	table.insert(channels, channel)
	return channel
end

function self:ServerStart()
	if enableVoice and optInVoiceChannel then
		local silentChannel = CreateChannel(noVoiceChannelName, true)
		silentChannel.speakerFilter = function(player) return false end
	end

	local channelName = if enableVoice then voiceChannelName else noVoiceChannelName
	local general = CreateChannel(channelName, enableVoice)
	if enableVoice and enableProximityChat then
		general:EnableProximityChat(maxVolumeDistance, minVolumeDistance)
	end

	--Always add new players to all of the channels
	server.PlayerConnected:Connect(function(player)
		for index, channel in channels do
			Chat:AddPlayerToChannel(channel, player)
		end
	end)
end