/*

    Copyright (c) 2024 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;
using Highrise.Studio;
using Highrise.Lua;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/GeneralChatOverride")]
    [LuaRegisterType(0xaf4fc9d8f84b428d, typeof(LuaBehaviour))]
    public class GeneralChatOverride : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "3f3042cebd6342142a3f180262235f96";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public System.String m_noVoiceChannelName = "Silent Zone";
        [SerializeField] public System.String m_voiceChannelName = "Open Mic";
        [SerializeField] public System.Boolean m_enableVoice = true;
        [Tooltip("If true, two channels will be created, the default channel where no one can speak and a joinable voice channel where everyone can speak")]
        [SerializeField] public System.Boolean m_optInVoiceChannel = true;
        [SerializeField] public System.Boolean m_enableProximityChat = true;
        [Tooltip("The distance between players where their voice starts to get softer")]
        [SerializeField] public System.Double m_maxVolumeDistance = 15;
        [Tooltip("The distance between players where you can no longer hear them")]
        [SerializeField] public System.Double m_minVolumeDistance = 30;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_noVoiceChannelName),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_voiceChannelName),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_enableVoice),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_optInVoiceChannel),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_enableProximityChat),
                CreateSerializedProperty(_script.GetPropertyAt(5), m_maxVolumeDistance),
                CreateSerializedProperty(_script.GetPropertyAt(6), m_minVolumeDistance),
            };
        }
    }
}

#endif
